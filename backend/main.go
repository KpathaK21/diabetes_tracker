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
	r.POST("/refresh", RefreshTokenHandler) // Token refresh endpoint
	r.POST("/submit-data", handleDataSubmission)
	r.POST("/signup", Signup)
	r.POST("/verify", VerifyEmail) // Email verification endpoint with code

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

		// New image classification endpoints
		auth.POST("/classify_food_image", ClassifyFoodImage)
		auth.POST("/submit_image_and_recommend", SubmitImageAndRecommend)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8443" // Using standard HTTPS port
	}

	// Check if we're in development mode
	devMode := os.Getenv("DEV_MODE") == "true"

	if devMode {
		// For development, run without TLS
		log.Printf("Starting server in development mode on port %s...", port)
		r.Run(":" + port)
	} else {
		// For production, use HTTPS
		certFile := os.Getenv("CERT_FILE")
		keyFile := os.Getenv("KEY_FILE")

		if certFile == "" || keyFile == "" {
			log.Fatal("CERT_FILE and KEY_FILE environment variables must be set for HTTPS")
		}

		log.Printf("Starting secure server on port %s...", port)
		log.Fatal(http.ListenAndServeTLS(":"+port, certFile, keyFile, r))
	}
}

func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get allowed origins from environment variable or use a default for development
		allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
		if allowedOrigins == "" {
			// In production, this should be explicitly set to your frontend domain(s)
			if os.Getenv("DEV_MODE") == "true" {
				allowedOrigins = "*" // Only allow all origins in development mode
			} else {
				allowedOrigins = "https://yourdomain.com" // Default to your production domain
			}
		}

		c.Writer.Header().Set("Access-Control-Allow-Origin", allowedOrigins)
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		// Add security headers
		c.Writer.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		c.Writer.Header().Set("X-Content-Type-Options", "nosniff")
		c.Writer.Header().Set("X-Frame-Options", "DENY")
		c.Writer.Header().Set("X-XSS-Protection", "1; mode=block")

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
