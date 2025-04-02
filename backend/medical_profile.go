package main

import "time"

type MedicalProfile struct {
    ID                    uint      `gorm:"primaryKey"`
    UserID                uint      `gorm:"not null;uniqueIndex"`
    DiabetesType          string    `gorm:"not null"`
    DiagnosisDate         time.Time
    PhysicianContact      string
    PreferredUnit         string    `gorm:"default:'mg/dL'"`
    FastingBloodGlucose   float64   `json:"fasting_blood_glucose"` // fasting glucose level
    PostprandialGlucose   float64   `json:"postprandial_glucose"`  // post-meal glucose level
}
