package main

import (
	"log"

	"github.com/onebharat/backend/config"
	"github.com/onebharat/backend/internal/auth"
	"github.com/onebharat/backend/internal/temple"
	"github.com/onebharat/backend/internal/pooja"
	"github.com/onebharat/backend/internal/user"
	"github.com/onebharat/backend/internal/astrology"
	"github.com/onebharat/backend/internal/wallet"
	"github.com/onebharat/backend/internal/store"
	"github.com/onebharat/backend/internal/notification"
	"github.com/onebharat/backend/internal/sadhana"
	"github.com/onebharat/backend/pkg/database"
	"github.com/onebharat/backend/pkg/middleware"
	"github.com/gin-gonic/gin"
)

func main() {
	// Load config
	cfg := config.Load()

	// Init DB connections
	db := database.InitPostgres(cfg)
	rdb := database.InitRedis(cfg)
	mdb := database.InitMongo(cfg)

	// Auto migrate models
	database.AutoMigrate(db)

	// Setup Gin router
	r := gin.Default()

	// Global middleware
	r.Use(middleware.CORS())
	r.Use(middleware.RateLimiter(rdb))
	r.Use(middleware.RequestLogger())

	// API v1 group
	api := r.Group("/api/v1")

	// Register all module routes
	auth.RegisterRoutes(api, db, rdb, cfg)
	user.RegisterRoutes(api, db, rdb, cfg)
	temple.RegisterRoutes(api, db, mdb, cfg)
	pooja.RegisterRoutes(api, db, cfg)
	astrology.RegisterRoutes(api, db, cfg)
	wallet.RegisterRoutes(api, db, rdb, cfg)
	store.RegisterRoutes(api, db, cfg)
	notification.RegisterRoutes(api, db, cfg)
	sadhana.RegisterRoutes(api, db, cfg)

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "One Bharat Backend"})
	})

	log.Printf("🕉️  One Bharat Server starting on port %s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
