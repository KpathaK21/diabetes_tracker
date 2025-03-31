package main

import (
    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
    "os"
    "log"
)

func main() {
    err := godotenv.Load(".env")
    if err != nil {
        panic("Error loading .env file")
    }
    InitDB()

    r := gin.Default()
    r.Use(CORSMiddleware()) // Apply CORS middleware to handle pre-flight requests for all routes

    // Public routes
    r.POST("/users", RegisterUser)
    r.POST("/login", LoginUser)

    // Protected routes
    auth := r.Group("/", AuthMiddleware())
    {
        auth.GET("/", func(c *gin.Context) {
            c.JSON(200, gin.H{"message": "Authorized!"})
        })

        auth.GET("/glucose", GetGlucoseData)
        auth.POST("/glucose", AddGlucoseReading)

        auth.POST("/diet", AddDietLog)
        auth.GET("/diet", GetDietLogs)

        auth.POST("/diet/recommend", RecommendDiet)
    }

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Starting server on port %s...", port)
    r.Run(":" + port)
}

func CORSMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
        c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
        c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
        c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    }
}
