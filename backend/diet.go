package main

import (
    "time"
    "gorm.io/gorm"
    "github.com/gin-gonic/gin"
    "net/http"
)

type DietLog struct {
    gorm.Model
    UserID          uint      `json:"user_id"`
    Timestamp       time.Time `json:"timestamp"`
    FoodDescription string    `json:"food_description" binding:"required"`
    Calories        uint      `json:"calories"`
    Nutrients       string    `json:"nutrients"`
}


func AddDietLog(c *gin.Context) {
    var input DietLog

    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID, exists := c.Get("user_id")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }

    input.UserID = userID.(uint)
    input.Timestamp = time.Now()

    if err := DB.Create(&input).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save diet log"})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "message": "Diet log saved",
        "data":    input,
    })
}

func GetDietLogs(c *gin.Context) {
    userID, exists := c.Get("user_id")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
        return
    }

    var logs []DietLog
    if err := DB.Where("user_id = ?", userID.(uint)).Order("timestamp desc").Find(&logs).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve diet logs"})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "user_id":  userID,
        "readings": logs,
    })
}
