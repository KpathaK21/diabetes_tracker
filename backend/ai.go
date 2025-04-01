package main

import (
	"bytes"
	"io"
    "context"
    "fmt"
    "net/http"  // Ensure net/http is imported for HTTP status codes
    "os"
    "strings"
    "time"      // Ensure time is imported for time.Now()
    "github.com/gin-gonic/gin"
    openai "github.com/sashabaranov/go-openai"
)

type CombinedInput struct {
    Glucose GlucoseReading `json:"glucose"`
    Diet    DietLog        `json:"diet"`
}


func SubmitDataAndRecommend(c *gin.Context) {
    userID, exists := c.Get("user_id")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }

    var input CombinedInput
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input format", "details": err.Error()})
        return
    }

    // Save Glucose
    input.Glucose.UserID = userID.(uint)
    input.Glucose.RecordedAt = time.Now()
    if err := DB.Create(&input.Glucose).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save glucose data"})
        return
    }

    // Save Diet
    input.Diet.UserID = userID.(uint)
    input.Diet.Timestamp = time.Now()
    if err := DB.Create(&input.Diet).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save diet data"})
        return
    }

    recommend(c, []DietLog{input.Diet}, []GlucoseReading{input.Glucose})
}

// Extracted AI recommendation logic for reuse
func recommend(c *gin.Context, diets []DietLog, glucose []GlucoseReading) {
    prompt := buildPrompt(diets, glucose)
    fmt.Println("Prompt being sent to OpenAI:\n", prompt)

    client := openai.NewClient(os.Getenv("OPENAI_API_KEY"))
    resp, err := client.CreateChatCompletion(context.Background(), openai.ChatCompletionRequest{
        Model: "gpt-3.5-turbo",
        Temperature: 0.7,
        Messages: []openai.ChatCompletionMessage{
            {
                Role:    openai.ChatMessageRoleSystem,
                Content: "You are a helpful nutritionist for people with diabetes, using the most advanced medical model available.",
            },
            {
                Role:    openai.ChatMessageRoleUser,
                Content: prompt,
            },
        },
    })

    if err != nil {
        fmt.Println("OpenAI error:", err)
        c.JSON(500, gin.H{"error": "Failed to get recommendation from AI"})
        return
    }

    c.JSON(200, gin.H{"recommendation": resp.Choices[0].Message.Content})
}

// Build the prompt for AI using the latest data
func buildPrompt(diets []DietLog, glucose []GlucoseReading) string {
    var sb strings.Builder

    sb.WriteString("Here is the recent glucose and diet log for a user with diabetes:\n\n")

    if len(glucose) > 0 {
        sb.WriteString("Recent Glucose Readings:\n")
        for _, g := range glucose {
            sb.WriteString(fmt.Sprintf("- %s: %.1f mg/dL (%s)\n", g.RecordedAt.Format("Jan 2 15:04"), g.Level, g.MealTag))
        }
        sb.WriteString("\n")
    }

    if len(diets) > 0 {
        sb.WriteString("Recent Meals:\n")
        for _, d := range diets {
            if d.FoodDescription == "" {
                continue // skip empty descriptions
            }
            sb.WriteString(fmt.Sprintf("- %s: %s (%d cal) - %s\n", d.Timestamp.Format("Jan 2 15:04"), d.FoodDescription, d.Calories, d.Nutrients))
        }
        sb.WriteString("\n")
    }

    sb.WriteString("Please suggest what the user should eat today to maintain stable blood sugar.")

    return sb.String()
}
