package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type SignupInput struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func Signup(c *gin.Context) {
	var input SignupInput
	if err := c.ShouldBindJSON(&input); err != nil {
		// Check if it's a validation error related to email
		if strings.Contains(err.Error(), "Email") && strings.Contains(err.Error(), "email") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Please enter a valid email address format"})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	// Check if user already exists
	var existing User
	if err := DB.Where("email = ?", input.Email).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
		return
	}

	// Hash the password
	hashed, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Save new user
	// Generate verification token
	verificationToken := generateVerificationToken()

	newUser := User{
		Email:             input.Email,
		Password:          string(hashed),
		VerificationToken: verificationToken,
		TokenExpiry:       time.Now().Add(24 * time.Hour), // Token valid for 24 hours
	}

	if err := DB.Create(&newUser).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Send verification email
	go sendVerificationEmail(newUser.Email, verificationToken)

	// Return success message instead of token
	c.JSON(http.StatusOK, gin.H{
		"message":  "User registered successfully. Please check your email to verify your account.",
		"verified": false,
	})
}

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Missing or invalid token"})
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")

		log.Println("Attempting to parse token:", tokenStr[:10]+"...")
		token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method")
			}
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			fmt.Println("Decoded Claims:", claims) // Debugging line
			if userID, ok := claims["user_id"].(float64); ok {
				c.Set("user_id", uint(userID)) // Set the user_id in the context
			} else {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
				return
			}
		} else {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid claims"})
			return
		}

		c.Next()
	}
}

func generateJWT(userID uint, email string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"email":   email,
		"exp":     jwt.NewNumericDate(time.Now().Add(24 * time.Hour)), // 24-hour expiration
	})

	return token.SignedString(jwtKey)
}

func SaveGlucoseData(c *gin.Context) {
	var input struct {
		FastingBloodGlucose float64 `json:"fasting_glucose"`
		PostprandialGlucose float64 `json:"postprandial_glucose"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	// Get the user ID from the context (already set by the authentication middleware)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	// Save the glucose values in the database
	medicalProfile := MedicalProfile{
		UserID:              userID.(uint),
		FastingBloodGlucose: input.FastingBloodGlucose,
		PostprandialGlucose: input.PostprandialGlucose,
	}

	if err := DB.Create(&medicalProfile).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save glucose data"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Glucose values saved"})
}

func LoginUser(c *gin.Context) {
	var input struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Lookup user in DB
	var user User
	if err := DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Check if the user's email is verified
	if !user.Verified {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Please verify your email address before logging in"})
		return
	}

	// Compare password hash
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Generate JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"email":   input.Email,
		"user_id": user.ID, // ✅ include real UserID
		"exp":     time.Now().Add(2 * time.Hour).Unix(),
	})

	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   tokenString,
	})
}
