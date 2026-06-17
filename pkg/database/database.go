	package database

	import (
		"context"
		"fmt"
		"log"

		"github.com/onebharat/backend/config"
		"github.com/onebharat/backend/pkg/models"
		"github.com/redis/go-redis/v9"
		"go.mongodb.org/mongo-driver/mongo"
		"go.mongodb.org/mongo-driver/mongo/options"
		"gorm.io/driver/postgres"
		"gorm.io/gorm"
		"gorm.io/gorm/logger"
	)

	func InitPostgres(cfg *config.Config) *gorm.DB {
		dsn := fmt.Sprintf(
			"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable TimeZone=Asia/Kolkata",
			cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName,
		)

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

	func InitRedis(cfg *config.Config) *redis.Client {
		rdb := redis.NewClient(&redis.Options{
			Addr:     cfg.RedisAddr,
			Password: cfg.RedisPassword,
			DB:       0,
		})

		if _, err := rdb.Ping(context.Background()).Result(); err != nil {
			log.Fatal("Failed to connect to Redis:", err)
		}

		log.Println("✅ Redis connected")
		return rdb
	}

	func InitMongo(cfg *config.Config) *mongo.Database {
		clientOptions := options.Client().ApplyURI(cfg.MongoURI)
		client, err := mongo.Connect(context.Background(), clientOptions)
		if err != nil {
			log.Fatal("Failed to connect to MongoDB:", err)
		}

		if err := client.Ping(context.Background(), nil); err != nil {
			log.Fatal("MongoDB ping failed:", err)
		}

		log.Println("✅ MongoDB connected")
		return client.Database(cfg.MongoDB)
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
