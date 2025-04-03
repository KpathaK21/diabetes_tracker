package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

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

	// Get predefined glucose levels from the medical profile
	var medicalProfile MedicalProfile
	if err := DB.Where("user_id = ?", userID.(uint)).First(&medicalProfile).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve medical profile"})
		return
	}

	// Generate a single recommendation based on glucose level and compare with predefined levels
	recommendation := generateCompleteRecommendation(input.Glucose, input.Diet, medicalProfile)

	// Call the recommend function with the complete recommendation
	recommend(c, []DietLog{input.Diet}, []GlucoseReading{input.Glucose}, recommendation)
}

func generateCompleteRecommendation(glucose GlucoseReading, diet DietLog, medicalProfile MedicalProfile) string {
	// Generate the basic recommendation based on glucose level
	var recommendation string

	// Compare with predefined levels from medical profile
	if glucose.Level < medicalProfile.FastingBloodGlucose {
		recommendation = "Your glucose is below your predefined fasting level. This might indicate hypoglycemia. Consider consuming some carbohydrates."
	} else if glucose.Level > medicalProfile.PostprandialGlucose {
		recommendation = "Your glucose level is above your predefined postprandial level. You should monitor your diet more carefully and consider reducing carbohydrate intake."
	} else if glucose.Level > 180 {
		recommendation = "Your blood glucose level is high. You should consider reducing carbohydrate intake."
	} else if glucose.Level < 70 {
		recommendation = "Your blood glucose level is low. You should eat something rich in carbohydrates."
	} else {
		recommendation = "Your blood glucose level is within the normal range. Keep maintaining a balanced diet."
	}

	// Add dietary advice based on the diet
	if diet.FoodDescription != "" {
		recommendation += " Based on your recent meal: " + diet.FoodDescription + " (" + fmt.Sprintf("%d cal)", diet.Calories) + "."
	}

	// Return the complete recommendation
	return recommendation
}

func recommend(c *gin.Context, diets []DietLog, glucose []GlucoseReading, recommendation string) {
	prompt := buildPrompt(diets, glucose, recommendation) // Pass recommendation to the prompt
	fmt.Println("Prompt being sent to OpenAI:\n", prompt)

	client := openai.NewClient(os.Getenv("OPENAI_API_KEY"))
	resp, err := client.CreateChatCompletion(context.Background(), openai.ChatCompletionRequest{
		Model:       "gpt-3.5-turbo",
		Temperature: 0.7,
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: "You are a helpful nutritionist for people with diabetes, using the most advanced medical knowledge available. Your job is to recommend appropriate meals for the rest of the day based on the user's glucose levels and previous food intake. Also suggest suitable workouts to help maintain optimal glucose control. Present your recommendations in a clear, well-formatted manner.",
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

func buildPrompt(diets []DietLog, glucose []GlucoseReading, recommendation string) string {
	var sb strings.Builder

	sb.WriteString("Here is the recent glucose and diet log for a user with diabetes:\n\n")

	// Include glucose readings and diet logs
	if len(glucose) > 0 {
		sb.WriteString("Recent Glucose Readings:\n")
		for _, g := range glucose {
			sb.WriteString(fmt.Sprintf("- %s: %.1f mg/dL (%s)\n", g.RecordedAt.Format("Jan 2 15:04"), g.Level, g.MealTag))
		}
	}

	if len(diets) > 0 {
		sb.WriteString("Recent Meals:\n")
		for _, d := range diets {
			sb.WriteString(fmt.Sprintf("- %s: %s (%d cal) - %s\n", d.Timestamp.Format("Jan 2 15:04"), d.FoodDescription, d.Calories, d.Nutrients))
		}
	}

	sb.WriteString("\n\nHere is your recommendation:\n")
	sb.WriteString(recommendation)

	return sb.String()
}
