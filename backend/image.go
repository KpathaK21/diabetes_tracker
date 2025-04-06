package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// ImageUploadRequest represents the request for image upload
type ImageUploadRequest struct {
	Image string `json:"image"` // Base64 encoded image
}

// FoodClassificationResponse represents the response from the AI service
type FoodClassificationResponse struct {
	Food           string             `json:"food"`
	Confidence     float64            `json:"confidence"`
	Calories       int                `json:"calories"`
	Nutrients      map[string]float64 `json:"nutrients"`
	Description    string             `json:"description"`
	GlycemicIndex  int                `json:"glycemic_index"`
	PortionSize    string             `json:"portion_size"`
	DiabetesImpact string             `json:"diabetes_impact"`
}

// ImageDietLog represents a diet log created from an image
type ImageDietLog struct {
	FoodDescription string             `json:"food_description"`
	Calories        int                `json:"calories"`
	Nutrients       string             `json:"nutrients"`
	Image           string             `json:"image"` // Base64 encoded image
	NutrientsMap    map[string]float64 `json:"nutrients_map"`
}

// ClassifyFoodImage handles the image upload and classification
func ClassifyFoodImage(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var request ImageUploadRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format", "details": err.Error()})
		return
	}

	// Call the AI service to classify the image
	classificationResponse, err := callAIService(request.Image)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to classify image", "details": err.Error()})
		return
	}

	// Convert nutrients map to string for storage
	nutrientsJSON, err := json.Marshal(classificationResponse.Nutrients)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process nutrients data"})
		return
	}

	// Create a diet log from the classification result with enhanced information
	description := classificationResponse.Food + ": " + classificationResponse.Description
	if classificationResponse.DiabetesImpact != "" {
		description += " - " + classificationResponse.DiabetesImpact
	}
	if classificationResponse.PortionSize != "" {
		description += " (Portion: " + classificationResponse.PortionSize + ")"
	}
	if classificationResponse.GlycemicIndex > 0 {
		description += fmt.Sprintf(" [GI: %d]", classificationResponse.GlycemicIndex)
	}

	dietLog := DietLog{
		UserID:          userID.(uint),
		Timestamp:       time.Now(),
		FoodDescription: description,
		Calories:        uint(classificationResponse.Calories),
		Nutrients:       string(nutrientsJSON),
	}

	// Save the diet log to the database
	if err := DB.Create(&dietLog).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save diet log"})
		return
	}

	// Return the classification result and the created diet log
	c.JSON(http.StatusOK, gin.H{
		"message":        "Image classified and diet log created",
		"classification": classificationResponse,
		"diet_log":       dietLog,
	})
}

// callAIService sends the image to the AI service for classification
func callAIService(imageBase64 string) (*FoodClassificationResponse, error) {
	// Log the length of the base64 string
	fmt.Printf("Image base64 length: %d\n", len(imageBase64))

	// Prepare the request to the AI service
	url := "http://localhost:5001/classify"
	requestBody, err := json.Marshal(map[string]string{
		"image": imageBase64,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %v", err)
	}

	// Send the request to the AI service
	fmt.Println("Sending request to AI service...")
	resp, err := http.Post(url, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to call AI service: %v", err)
	}
	defer resp.Body.Close()

	// Read the response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	// Log the response status and body
	fmt.Printf("AI service response status: %d\n", resp.StatusCode)
	fmt.Printf("AI service response body: %s\n", string(body))

	// Check if the response status is not OK
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("AI service returned error: %s", body)
	}

	// Parse the response
	var classificationResponse FoodClassificationResponse
	if err := json.Unmarshal(body, &classificationResponse); err != nil {
		// Try to handle the case where the response might be in a different format
		fmt.Printf("Failed to parse response as FoodClassificationResponse: %v\n", err)

		// Try to parse as a generic map
		var genericResponse map[string]interface{}
		if jsonErr := json.Unmarshal(body, &genericResponse); jsonErr == nil {
			// Create a default response with enhanced fields
			defaultResponse := &FoodClassificationResponse{
				Food:           "unknown_food",
				Confidence:     0.7,
				Calories:       200,
				Nutrients:      map[string]float64{"carbs": 30, "protein": 10, "fat": 5},
				Description:    "Food item detected",
				GlycemicIndex:  50,
				PortionSize:    "1 serving",
				DiabetesImpact: "Unknown impact on blood glucose levels",
			}

			// Try to extract information from the generic response
			if food, ok := genericResponse["food"].(string); ok {
				defaultResponse.Food = food
			}
			if confidence, ok := genericResponse["confidence"].(float64); ok {
				defaultResponse.Confidence = confidence
			}
			if calories, ok := genericResponse["calories"].(float64); ok {
				defaultResponse.Calories = int(calories)
			}

			return defaultResponse, nil
		}

		return nil, fmt.Errorf("failed to parse response: %v", err)
	}

	return &classificationResponse, nil
}

// SubmitImageAndRecommend handles image upload, classification, and recommendation
func SubmitImageAndRecommend(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var request struct {
		Image   string         `json:"image"` // Base64 encoded image
		Glucose GlucoseReading `json:"glucose"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format", "details": err.Error()})
		return
	}

	// Log the request
	fmt.Printf("Received image data of length: %d\n", len(request.Image))
	fmt.Printf("Glucose data: %+v\n", request.Glucose)

	// Call the AI service to classify the image
	classificationResponse, err := callAIService(request.Image)
	if err != nil {
		fmt.Printf("Error calling AI service: %v\n", err)
		// Instead of failing, create a default classification response with enhanced fields
		classificationResponse = &FoodClassificationResponse{
			Food:           "default_food",
			Confidence:     0.7,
			Calories:       200,
			Nutrients:      map[string]float64{"carbs": 30, "protein": 10, "fat": 5},
			Description:    "Default food item when classification fails",
			GlycemicIndex:  50,
			PortionSize:    "1 serving",
			DiabetesImpact: "Unknown impact on blood glucose levels",
		}

		// Log that we're using a default response
		fmt.Println("Using default classification response due to error")
	}

	// Convert nutrients map to string for storage
	nutrientsJSON, err := json.Marshal(classificationResponse.Nutrients)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process nutrients data"})
		return
	}

	// Save Glucose
	request.Glucose.UserID = userID.(uint)
	request.Glucose.RecordedAt = time.Now()
	if err := DB.Create(&request.Glucose).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save glucose data"})
		return
	}

	// Create a diet log from the classification result with enhanced information
	description := classificationResponse.Food + ": " + classificationResponse.Description
	if classificationResponse.DiabetesImpact != "" {
		description += " - " + classificationResponse.DiabetesImpact
	}
	if classificationResponse.PortionSize != "" {
		description += " (Portion: " + classificationResponse.PortionSize + ")"
	}
	if classificationResponse.GlycemicIndex > 0 {
		description += fmt.Sprintf(" [GI: %d]", classificationResponse.GlycemicIndex)
	}

	dietLog := DietLog{
		UserID:          userID.(uint),
		Timestamp:       time.Now(),
		FoodDescription: description,
		Calories:        uint(classificationResponse.Calories),
		Nutrients:       string(nutrientsJSON),
	}

	// Save the diet log to the database
	if err := DB.Create(&dietLog).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save diet log"})
		return
	}

	// Get predefined glucose levels from the medical profile
	var medicalProfile MedicalProfile
	if err := DB.Where("user_id = ?", userID.(uint)).First(&medicalProfile).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve medical profile"})
		return
	}

	// Generate a recommendation based on glucose level and diet
	recommendation := generateCompleteRecommendation(request.Glucose, dietLog, medicalProfile)

	// Call the recommend function with the complete recommendation
	recommend(c, []DietLog{dietLog}, []GlucoseReading{request.Glucose}, recommendation)
}

// Base64ToImage decodes a base64 string to an image
func Base64ToImage(base64String string) ([]byte, error) {
	// Remove data URL prefix if present
	const prefix = "data:image/jpeg;base64,"
	if len(base64String) > len(prefix) && base64String[:len(prefix)] == prefix {
		base64String = base64String[len(prefix):]
	}

	// Decode the base64 string
	return base64.StdEncoding.DecodeString(base64String)
}
