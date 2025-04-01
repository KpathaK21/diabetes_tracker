package main

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "time"
)

type GlucoseReading struct {
    ID         uint      `gorm:"primaryKey"`
    UserID     uint      `gorm:"not null;index"`
    Level      float64   `gorm:"not null"`
    RecordedAt time.Time `gorm:"not null"`
    MealTag    string
    MealType   string    `gorm:"not null"`  // Added field for meal type
    Notes      string
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

func AddGlucoseReading(c *gin.Context) {
    var input GlucoseReading

    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID, exists := c.Get("user_id")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
        return
    }

    input.UserID = userID.(uint)
    input.RecordedAt = time.Now()

    if err := DB.Create(&input).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save glucose reading"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Glucose reading saved", "data": input})
}
