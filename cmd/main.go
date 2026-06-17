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
	cfg := config.Load()

	db := database.InitPostgres(cfg)
	database.AutoMigrate(db)

	r := gin.Default()

	r.Use(middleware.CORS())
	r.Use(middleware.RequestLogger())

	api := r.Group("/api/v1")

	auth.RegisterRoutes(api, db, nil, cfg)
	user.RegisterRoutes(api, db, nil, cfg)
	temple.RegisterRoutes(api, db, nil, cfg)
	pooja.RegisterRoutes(api, db, cfg)
	astrology.RegisterRoutes(api, db, cfg)
	wallet.RegisterRoutes(api, db, nil, cfg)
	store.RegisterRoutes(api, db, cfg)
	notification.RegisterRoutes(api, db, cfg)
	sadhana.RegisterRoutes(api, db, cfg)

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "One Bharat Backend"})
	})

	log.Printf("🕉️  One Bharat Server starting on port %s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}