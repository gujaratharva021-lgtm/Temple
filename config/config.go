package config

import (
	"log"
	"github.com/spf13/viper"
)

type Config struct {
	Port        string
	Environment string

	// PostgreSQL
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string

	// Redis
	RedisAddr     string
	RedisPassword string

	// MongoDB
	MongoURI string
	MongoDB  string

	// JWT
	JWTSecret          string
	JWTExpiryHours     int
	RefreshTokenExpiry int

	// OTP
	OTPExpireMinutes int

	// Razorpay
	RazorpayKey    string
	RazorpaySecret string

	// Twilio
	TwilioSID   string
	TwilioToken string
	TwilioFrom  string

	// AWS S3
	AWSRegion    string
	AWSBucket    string
	AWSAccessKey string
	AWSSecretKey string

	// RabbitMQ
	RabbitMQURL string

	// Astrology API (Panchang Festivals)
	AstrologyAPIKey  string
	AstrologyUserID  string
}

func Load() *Config {
	viper.SetConfigFile(".env")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	return &Config{
		Port:        getEnv("PORT", "8080"),
		Environment: getEnv("ENV", "development"),

		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBUser:     getEnv("DB_USER", "postgres"),
		DBPassword: getEnv("DB_PASSWORD", "password"),
		DBName:     getEnv("DB_NAME", "onebharat"),

		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),

		MongoURI: getEnv("MONGO_URI", "mongodb://localhost:27017"),
		MongoDB:  getEnv("MONGO_DB", "onebharat_docs"),

		JWTSecret:          getEnv("JWT_SECRET", "your-super-secret-jwt-key-change-in-prod"),
		JWTExpiryHours:     24,
		RefreshTokenExpiry: 7 * 24,

		OTPExpireMinutes: 10,

		RazorpayKey:    getEnv("RAZORPAY_KEY", ""),
		RazorpaySecret: getEnv("RAZORPAY_SECRET", ""),

		TwilioSID:   getEnv("TWILIO_SID", ""),
		TwilioToken: getEnv("TWILIO_TOKEN", ""),
		TwilioFrom:  getEnv("TWILIO_FROM", ""),

		AWSRegion:    getEnv("AWS_REGION", "ap-south-1"),
		AWSBucket:    getEnv("AWS_BUCKET", "onebharat-media"),
		AWSAccessKey: getEnv("AWS_ACCESS_KEY", ""),
		AWSSecretKey: getEnv("AWS_SECRET_KEY", ""),

		RabbitMQURL: getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),

		AstrologyAPIKey: getEnv("ASTROLOGY_API_KEY", ""),
		AstrologyUserID: getEnv("ASTROLOGY_USER_ID", ""),
	}
}

func getEnv(key, defaultVal string) string {
	if val := viper.GetString(key); val != "" {
		return val
	}
	return defaultVal
}
