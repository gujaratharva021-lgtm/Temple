package database

import (
	"fmt"
	"log"
	"os"

	"github.com/onebharat/backend/config"
	"github.com/onebharat/backend/pkg/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func InitPostgres(cfg *config.Config) *gorm.DB {
	var dsn string

	// Render pe DATABASE_URL environment variable use karo
	if dbURL := os.Getenv("DATABASE_URL"); dbURL != "" {
		dsn = dbURL + "?sslmode=require"
	} else {
		dsn = fmt.Sprintf(
			"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable TimeZone=Asia/Kolkata",
			cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName,
		)
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatal("Failed to connect to PostgreSQL:", err)
	}

	sqlDB, _ := db.DB()
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)

	log.Println("✅ PostgreSQL connected")
	return db
}

func AutoMigrate(db *gorm.DB) {
	err := db.AutoMigrate(
		&models.User{},
		&models.UserProfile{},
		&models.Temple{},
		&models.TempleStaff{},
		&models.PoojaService{},
		&models.PoojaBooking{},
		&models.Product{},
		&models.Order{},
		&models.OrderItem{},
		&models.AstrologyConsultation{},
		&models.Wallet{},
		&models.WalletTransaction{},
		&models.Donation{},
		&models.LiveDarshan{},
		&models.FamilyMember{},
		&models.Notification{},
		&models.Mantra{},
		&models.SadhanaPractice{},
		&models.SadhanaLog{},
		&models.Festival{},
		&models.Shloka{},
	)
	if err != nil {
		log.Fatal("AutoMigrate failed:", err)
	}
	log.Println("✅ Database migrated")
}