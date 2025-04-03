package main

import (
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

type User struct {
	ID                uint      `gorm:"primaryKey" json:"id"`
	Email             string    `gorm:"not null;unique" json:"email"`
	Password          string    `gorm:"not null" json:"password"`
	FullName          string    `gorm:"not null"`
	DOB               time.Time `gorm:"not null"`
	Gender            string    `gorm:"not null"`
	Verified          bool      `gorm:"default:false" json:"verified"`
	VerificationToken string    `gorm:"size:100" json:"-"`
	TokenExpiry       time.Time `json:"-"`

	MedicalProfile  MedicalProfile
	GlucoseReadings []GlucoseReading
	Medications     []Medication
	Appointments    []Appointment
}

func RegisterUser(c *gin.Context) {
	// Struct to bind JSON input for registration (email, password, etc.)
	var input struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required"`
		FullName string `json:"full_name" binding:"required"`
		DOB      string `json:"dob" binding:"required"` // Expecting ISO string
		Gender   string `json:"gender" binding:"required"`
	}

	// Bind JSON input to the input struct and handle errors
	if err := c.ShouldBindJSON(&input); err != nil {
		// Check if it's a validation error related to email
		if strings.Contains(err.Error(), "Email") && strings.Contains(err.Error(), "email") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Please enter a valid email address format"})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parsing the date of birth (DOB) from the input
	parsedDOB, err := time.Parse("2006-01-02", input.DOB)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid DOB format (expected YYYY-MM-DD)"})
		return
	}

	// Check if the email is already registered to prevent duplicate registrations
	var existing User
	if err := DB.Where("email = ?", input.Email).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
		return
	}

	// Hash the password using bcrypt before storing it to ensure it's never stored in plain text
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Create and store the new user with the hashed password
	user := User{
		Email:    input.Email,
		Password: string(hashedPassword),
		FullName: input.FullName,
		DOB:      parsedDOB,
		Gender:   input.Gender,
	}

	// Generate verification token
	token := generateVerificationToken()
	user.VerificationToken = token
	user.TokenExpiry = time.Now().Add(24 * time.Hour) // Token valid for 24 hours

	// Save the user to the database and handle potential errors
	if err := DB.Create(&user).Error; err != nil {
		fmt.Println("DB error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Send verification email
	go sendVerificationEmail(user.Email, token)

	// Respond with success if the user is registered without any issues
	c.JSON(http.StatusOK, gin.H{
		"message":  "User registered successfully. Please check your email to verify your account.",
		"verified": false,
	})
}

// Generate a 6-digit verification code
func generateVerificationToken() string {
	// Initialize the random number generator
	rand.Seed(time.Now().UnixNano())
	// Generate a random 6-digit number
	code := 100000 + rand.Intn(900000)
	return fmt.Sprintf("%d", code)
}

// Send verification email to the user using SendGrid
func sendVerificationEmail(email, token string) {
	// Get the app domain from environment variable
	appDomain := os.Getenv("APP_DOMAIN")
	if appDomain == "" {
		log.Println("WARNING: APP_DOMAIN environment variable not set. Using default value.")
		appDomain = "http://localhost:3000" // Default for local development
	}

	// We're now using a verification code instead of a link
	verificationCode := token

	// Log the verification code for debugging purposes
	log.Printf("Sending verification email to %s with code: %s\n", email, verificationCode)

	// Get sender email from environment variable
	senderEmail := os.Getenv("SENDER_EMAIL")
	if senderEmail == "" {
		log.Println("ERROR: SENDER_EMAIL environment variable not set. Using default value, but this will likely fail.")
		senderEmail = "noreply@diabetesapp.com" // Default, but this will fail if not verified
	}

	// Create email using SendGrid
	from := mail.NewEmail("Diabetes App", senderEmail)
	subject := "Please verify your email address"
	to := mail.NewEmail("", email)

	// Create plain text content
	plainTextContent := fmt.Sprintf(`
Hello,

Thank you for signing up for the Diabetes App. Please verify your email address by entering the verification code below:

%s

If you did not sign up for this service, please ignore this email.

Best regards,
The Diabetes App Team
	`, verificationCode)

	// Create HTML content with a professional template
	htmlContent := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
	   <style>
	       body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
	       .container { max-width: 600px; margin: 0 auto; padding: 20px; }
	       .header { background-color: #4285f4; color: white; padding: 10px; text-align: center; }
	       .content { padding: 20px; }
	       .verification-code { font-size: 32px; font-weight: bold; text-align: center; letter-spacing: 5px; margin: 20px 0; color: #4285f4; }
	       .footer { font-size: 12px; color: #777; margin-top: 30px; }
	   </style>
</head>
<body>
	   <div class="container">
	       <div class="header">
	           <h1>Diabetes App</h1>
	       </div>
	       <div class="content">
	           <p>Hello,</p>
	           <p>Thank you for signing up for the Diabetes App. Please verify your email address by entering the verification code below:</p>
	           <div class="verification-code">%s</div>
	           <p>Enter this code in the verification screen of the app to complete your registration.</p>
	           <p>If you did not sign up for this service, please ignore this email.</p>
	           <p>Best regards,<br>The Diabetes App Team</p>
	       </div>
	       <div class="footer">
	           <p>This is an automated message, please do not reply to this email.</p>
	       </div>
	   </div>
</body>
</html>
	`, verificationCode)

	// Create the email message
	message := mail.NewSingleEmail(from, subject, to, plainTextContent, htmlContent)

	// Get the SendGrid API key from environment variables
	apiKey := os.Getenv("SENDGRID_API_KEY")
	if apiKey == "" {
		log.Println("ERROR: SENDGRID_API_KEY environment variable not set. Email not sent.")
		return
	}

	// Create the SendGrid client
	client := sendgrid.NewSendClient(apiKey)

	// Send the email
	response, err := client.Send(message)
	if err != nil {
		log.Printf("ERROR: Failed to send verification email to %s: %v", email, err)
		return
	}

	// Check response status code
	if response.StatusCode >= 200 && response.StatusCode < 300 {
		log.Printf("SUCCESS: Verification email sent to %s, status code: %d", email, response.StatusCode)
	} else {
		log.Printf("ERROR: SendGrid API returned status code %d when sending to %s: %s",
			response.StatusCode, email, response.Body)

		// Add more helpful error message for sender identity issues
		if response.StatusCode == 403 && strings.Contains(response.Body, "sender identity") {
			log.Printf("SENDER IDENTITY ERROR: The email address '%s' is not verified in SendGrid. "+
				"Please verify this email in your SendGrid account or set the SENDER_EMAIL environment variable "+
				"to a verified email address. Visit https://sendgrid.com/docs/for-developers/sending-email/sender-identity/ "+
				"for more information.", senderEmail)
		}
	}
}

// ValidateEmailFormat performs a more thorough validation of email format
func ValidateEmailFormat(email string) bool {
	// Basic pattern matching for email format
	// This is a simple regex that checks for basic email format
	// For production, consider using a more comprehensive regex or a library
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}

// VerifyEmail handles email verification
func VerifyEmail(c *gin.Context) {
	// Get verification code from request body instead of URL query
	var input struct {
		Code string `json:"code" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Verification code is required"})
		return
	}

	var user User
	if err := DB.Where("verification_token = ? AND token_expiry > ?", input.Code, time.Now()).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired verification code"})
		return
	}

	// Mark user as verified
	user.Verified = true
	user.VerificationToken = "" // Clear the token
	if err := DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to verify email"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Email verified successfully"})
}
