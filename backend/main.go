package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

// validateEnvVars checks if all required environment variables are set
func validateEnvVars() {
	required := []string{"SENDGRID_API_KEY", "APP_DOMAIN"}
	missing := []string{}

	for _, v := range required {
		if os.Getenv(v) == "" {
			missing = append(missing, v)
		}
	}

	if len(missing) > 0 {
		log.Fatalf("Missing required environment variables: %v", missing)
	}
}

func main() {
	// Load .env file if it exists
	err := godotenv.Load(".env")
	if err != nil {
		log.Println("Warning: .env file not found, using system environment variables")
	}

	// Validate required environment variables
	validateEnvVars()
	InitDB()

	r := gin.Default()
	r.Use(CORSMiddleware()) // Apply CORS middleware to handle pre-flight requests for all routes
	// Public routes
	r.POST("/users", RegisterUser)
	r.POST("/login", LoginUser)
	r.POST("/submit-data", handleDataSubmission)
	r.POST("/signup", Signup)
	r.GET("/verify", VerifyEmail) // Email verification endpoint

	// Protected routes
	auth := r.Group("/", AuthMiddleware())
	{
		auth.GET("/", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "Authorized!"})
		})
		auth.GET("/glucose", GetGlucoseData)
		auth.POST("/glucose", AddGlucoseReading)
		auth.POST("/set_glucose_levels", SetGlucoseLevels)

		auth.POST("/diet", AddDietLog)
		auth.GET("/diet", GetDietLogs)

		auth.POST("/submit_and_recommend", SubmitDataAndRecommend)
		auth.GET("/history", GetUserHistory)

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

func handleDataSubmission(c *gin.Context) {
	var data struct {
		FoodDescription string  `json:"foodDescription"`
		Calories        int     `json:"calories"`
		Nutrients       string  `json:"nutrients"`
		GlucoseLevel    float64 `json:"glucoseLevel"`
	}

	if err := c.ShouldBindJSON(&data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Process data here, e.g., save to database
	// Respond
	c.JSON(http.StatusOK, gin.H{"message": "Data received successfully"})
}
