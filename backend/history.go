package main

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

type HistoryEntry struct {
	Timestamp       string  `json:"timestamp"`
	FoodDescription string  `json:"food_description"`
	Calories        uint    `json:"calories"`
	Nutrients       string  `json:"nutrients"`
	Level           float64 `json:"glucose_level"`
	MealTag         string  `json:"meal_tag"`
	MealType        string  `json:"meal_type"`
	Notes           string  `json:"notes"`
}

// GET /history
func GetUserHistory(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var diets []DietLog
	var glucose []GlucoseReading

	DB.Where("user_id = ?", userID.(uint)).Order("timestamp desc").Find(&diets)
	DB.Where("user_id = ?", userID.(uint)).Order("recorded_at desc").Find(&glucose)

	// Combine entries
	var history []HistoryEntry
	for i := 0; i < len(diets) && i < len(glucose); i++ {
		entry := HistoryEntry{
			Timestamp:       diets[i].Timestamp.Format("Jan 2 15:04"),
			FoodDescription: diets[i].FoodDescription,
			Calories:        diets[i].Calories,
			Nutrients:       diets[i].Nutrients,
			Level:           glucose[i].Level,
			MealTag:         glucose[i].MealTag,
			MealType:        glucose[i].MealType,
			Notes:           glucose[i].Notes,
		}
		history = append(history, entry)
	}

	c.JSON(http.StatusOK, gin.H{
		"history": history,
	})
}
