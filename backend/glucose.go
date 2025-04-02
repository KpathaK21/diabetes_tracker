package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type GlucoseReading struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	UserID     uint      `gorm:"not null;index" json:"user_id"`
	Level      float64   `gorm:"not null" json:"level"`
	RecordedAt time.Time `gorm:"not null" json:"recorded_at"`
	MealTag    string    `json:"meal_tag"`
	MealType   string    `json:"meal_type"`
	Notes      string    `json:"notes"`
}

func AddGlucoseReading(c *gin.Context) {
	var input GlucoseReading

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user ID from context (after JWT validation)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
		return
	}

	// Check if the user exists in the database
	var user User
	if err := DB.Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Get predefined glucose levels from the medical profile
	var medicalProfile MedicalProfile
	if err := DB.Where("user_id = ?", userID).First(&medicalProfile).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve medical profile"})
		return
	}

	// Compare entered glucose level with predefined values
	var recommendation string
	if input.Level < medicalProfile.FastingBloodGlucose {
		recommendation = "Your glucose is below the recommended fasting level. Please consult your doctor."
	} else if input.Level > medicalProfile.PostprandialGlucose {
		recommendation = "Your glucose level is high. You should monitor your diet and consult your doctor."
	} else {
		recommendation = "Your glucose level is within the recommended range."
	}

	// Save the glucose reading
	input.UserID = userID.(uint)
	input.RecordedAt = time.Now()

	if err := DB.Create(&input).Error; err != nil {
		fmt.Println("Error saving glucose reading:", err) // Additional logging
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save glucose reading"})
		return
	}

	// Return the success message with recommendation
	c.JSON(http.StatusOK, gin.H{
		"message":        "Glucose reading saved",
		"data":           input,
		"recommendation": recommendation,
	})
}

func SetGlucoseLevels(c *gin.Context) {
	// Log the headers to see if Authorization is present
	fmt.Println("Headers:", c.Request.Header)

	userID, exists := c.Get("user_id")
	fmt.Println("User ID exists:", exists)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
		return
	}

	var input struct {
		FastingGlucose      float64 `json:"fasting_glucose"`
		PostprandialGlucose float64 `json:"postprandial_glucose"`
	}

	// Parse the JSON request
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	// Try to find existing medical profile or create a new one
	var medicalProfile MedicalProfile
	result := DB.Where("user_id = ?", userID.(uint)).First(&medicalProfile)

	if result.Error != nil {
		// If no profile exists, create a new one
		fmt.Println("No existing medical profile found, creating new one for user ID:", userID)
		medicalProfile = MedicalProfile{
			UserID:              userID.(uint),
			DiabetesType:        "Type 2", // Default value, can be updated later
			DiagnosisDate:       time.Now(),
			FastingBloodGlucose: input.FastingGlucose,
			PostprandialGlucose: input.PostprandialGlucose,
		}

		if err := DB.Create(&medicalProfile).Error; err != nil {
			fmt.Println("Error creating medical profile:", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create medical profile"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Glucose levels saved successfully"})
		return
	}

	medicalProfile.FastingBloodGlucose = input.FastingGlucose
	medicalProfile.PostprandialGlucose = input.PostprandialGlucose

	// Update the medical profile in the database
	if err := DB.Save(&medicalProfile).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save glucose levels"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Glucose levels saved successfully"})
}

func GetGlucoseData(c *gin.Context) {
	var readings []GlucoseReading

	// ✅ Get real user ID from JWT middleware
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
		return
	}

	DB.Where("user_id = ?", userID.(uint)).Find(&readings)

	c.JSON(http.StatusOK, gin.H{
		"user_id":  userID,
		"readings": readings,
	})
}
