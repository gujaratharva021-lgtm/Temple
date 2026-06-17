package auth

import (
	"context"
	"fmt"
	"math/rand"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/onebharat/backend/config"
	"github.com/onebharat/backend/pkg/middleware"
	"github.com/onebharat/backend/pkg/models"
	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Handler struct {
	db  *gorm.DB
	rdb *redis.Client
	cfg *config.Config
}

func RegisterRoutes(r *gin.RouterGroup, db *gorm.DB, rdb *redis.Client, cfg *config.Config) {
	h := &Handler{db: db, rdb: rdb, cfg: cfg}
	auth := r.Group("/auth")
	{
		auth.POST("/send-otp", h.SendOTP)
		auth.POST("/verify-otp", h.VerifyOTP)
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
		auth.POST("/refresh", h.RefreshToken)
		auth.POST("/logout", middleware.AuthRequired(cfg.JWTSecret), h.Logout)
	}
}

// ─── SEND OTP ────────────────────────────────────────────────────────────────

type SendOTPRequest struct {
	Phone string `json:"phone" binding:"required,len=10"`
}

func (h *Handler) SendOTP(c *gin.Context) {
	var req SendOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	otp := fmt.Sprintf("%06d", rand.Intn(999999))
	key := fmt.Sprintf("otp:%s", req.Phone)
	ctx := context.Background()

	// Store OTP in Redis with expiry
	h.rdb.Set(ctx, key, otp, time.Duration(h.cfg.OTPExpireMinutes)*time.Minute)

	// TODO: Send via Twilio/MSG91
	// In dev mode, return OTP directly
	resp := gin.H{"message": "OTP sent successfully"}
	if h.cfg.Environment == "development" {
		resp["otp"] = otp // Remove in production!
	}

	c.JSON(http.StatusOK, resp)
}

// ─── VERIFY OTP ──────────────────────────────────────────────────────────────

type VerifyOTPRequest struct {
	Phone string `json:"phone" binding:"required"`
	OTP   string `json:"otp" binding:"required,len=6"`
}

func (h *Handler) VerifyOTP(c *gin.Context) {
	var req VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := context.Background()
	key := fmt.Sprintf("otp:%s", req.Phone)
	storedOTP, err := h.rdb.Get(ctx, key).Result()
	if err != nil || storedOTP != req.OTP {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired OTP"})
		return
	}

	h.rdb.Del(ctx, key)

	// Check if user exists
	var user models.User
	result := h.db.Where("phone = ?", req.Phone).First(&user)

	if result.Error != nil {
		// New user - return temp token for registration
		tempToken := uuid.New().String()
		h.rdb.Set(ctx, "temp:"+tempToken, req.Phone, 10*time.Minute)
		c.JSON(http.StatusOK, gin.H{
			"status":     "new_user",
			"temp_token": tempToken,
			"message":    "Please complete registration",
		})
		return
	}

	// Existing user - return JWT
	token, err := middleware.GenerateToken(user.ID.String(), string(user.Role), h.cfg.JWTSecret, h.cfg.JWTExpiryHours)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token generation failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "existing_user",
		"token":  token,
		"user":   user,
	})
}

// ─── REGISTER ────────────────────────────────────────────────────────────────

type RegisterRequest struct {
	TempToken string `json:"temp_token" binding:"required"`
	FullName  string `json:"full_name" binding:"required"`
	Email     string `json:"email"`
	Role      string `json:"role" binding:"required"`
}

func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := context.Background()
	phone, err := h.rdb.Get(ctx, "temp:"+req.TempToken).Result()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired session"})
		return
	}

	role := models.RoleDevotee
	if req.Role == "priest" {
		role = models.RolePriest
	} else if req.Role == "astrologer" {
		role = models.RoleAstrologer
	}

	user := models.User{
		Phone:      phone,
		Email:      req.Email,
		Role:       role,
		IsVerified: true,
		IsActive:   true,
	}

	if err := h.db.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Create profile
	profile := models.UserProfile{
		UserID:   user.ID,
		FullName: req.FullName,
		Language: "hi",
	}
	h.db.Create(&profile)

	// Create wallet
	wallet := models.Wallet{UserID: user.ID}
	h.db.Create(&wallet)

	h.rdb.Del(ctx, "temp:"+req.TempToken)

	token, _ := middleware.GenerateToken(user.ID.String(), string(role), h.cfg.JWTSecret, h.cfg.JWTExpiryHours)

	c.JSON(http.StatusCreated, gin.H{
		"message": "Registration successful",
		"token":   token,
		"user":    user,
	})
}

// ─── EMAIL/PASSWORD LOGIN ────────────────────────────────────────────────────

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := h.db.Where("email = ?", req.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	token, _ := middleware.GenerateToken(user.ID.String(), string(user.Role), h.cfg.JWTSecret, h.cfg.JWTExpiryHours)
	c.JSON(http.StatusOK, gin.H{"token": token, "user": user})
}

func (h *Handler) RefreshToken(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Refresh token endpoint"})
}

func (h *Handler) Logout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Logged out successfully"})
}
