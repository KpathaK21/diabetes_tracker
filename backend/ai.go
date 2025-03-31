package main

import (
    "context"
    "fmt"
    "os"
    "strings"
    "github.com/gin-gonic/gin"
    openai "github.com/sashabaranov/go-openai"
)

func RecommendDiet(c *gin.Context) {
    fmt.Println("AI recommender hit")

    userID, exists := c.Get("user_id")
    if !exists {
        c.JSON(401, gin.H{"error": "Unauthorized"})
        return
    }

    var diets []DietLog
    DB.Where("user_id = ?", userID.(uint)).Order("timestamp desc").Limit(5).Find(&diets)

    var glucose []GlucoseReading
    DB.Where("user_id = ?", userID.(uint)).Order("recorded_at desc").Limit(5).Find(&glucose)

    if len(diets) == 0 && len(glucose) == 0 {
        c.JSON(400, gin.H{"error": "Not enough data to generate a recommendation"})
        return
    }

    prompt := buildPrompt(diets, glucose)
    fmt.Println("Prompt being sent to OpenAI:\n", prompt) 

    client := openai.NewClient(os.Getenv("OPENAI_API_KEY"))
    resp, err := client.CreateChatCompletion(context.Background(), openai.ChatCompletionRequest{
        Model: "gpt-3.5-turbo", 
        Temperature: 0.7,
        Messages: []openai.ChatCompletionMessage{
            {
                Role:    openai.ChatMessageRoleSystem,
                Content: "You are a helpful nutritionist for people with diabetes,  using the most advanced medical model available.",
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

    c.JSON(200, gin.H{
        "recommendation": resp.Choices[0].Message.Content,
    })
}


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
                continue // 👈 skip empty descriptions
            }
            sb.WriteString(fmt.Sprintf("- %s: %s (%d cal) - %s\n", d.Timestamp.Format("Jan 2 15:04"), d.FoodDescription, d.Calories, d.Nutrients))
        }
        sb.WriteString("\n")
    }

    sb.WriteString("Please suggest what the user should eat today to maintain stable blood sugar.")

    return sb.String()
}
