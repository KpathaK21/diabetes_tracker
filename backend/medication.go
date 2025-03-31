package main

import "time"

type Medication struct {
    ID        uint       `gorm:"primaryKey"`
    UserID    uint       `gorm:"not null;index"`
    Name      string     `gorm:"not null"`
    Dosage    string
    StartDate time.Time
    EndDate   *time.Time
    Notes     string
}
