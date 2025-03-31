package main

import "time"

type Appointment struct {
    ID            uint      `gorm:"primaryKey"`
    UserID        uint      `gorm:"not null;index"`
    ScheduledAt   time.Time `gorm:"not null"`
    PhysicianName string
    Purpose       string
    Notes         string
}
