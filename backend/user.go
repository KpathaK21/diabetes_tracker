package main

import (
    "golang.org/x/crypto/bcrypt"
    "net/http"
    "github.com/gin-gonic/gin"
    "fmt"
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type User struct {
    ID        uint      `gorm:"primaryKey"`
    Email     string    `gorm:"unique;not null"`
    Password  string    `gorm:"not null"` // hashed
    FullName  string    `gorm:"not null"`
    DOB       time.Time `gorm:"not null"`
    Gender    string    `gorm:"not null"`

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

    // Save the user to the database and handle potential errors
    if err := DB.Create(&user).Error; err != nil {
        fmt.Println("DB error:", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
        return
    }

    // Respond with success if the user is registered without any issues
    c.JSON(http.StatusOK, gin.H{"message": "User registered successfully"})
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

    // Compare password hash
    if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)); err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
        return
    }

    // Generate JWT
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "email": input.Email,
        "user_id": user.ID, // ✅ include real UserID
        "exp":   time.Now().Add(2 * time.Hour).Unix(),
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

