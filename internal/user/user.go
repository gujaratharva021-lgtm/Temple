package user

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/onebharat/backend/config"
	"github.com/onebharat/backend/pkg/middleware"
	"github.com/onebharat/backend/pkg/models"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type Handler struct {
	db  *gorm.DB
	rdb *redis.Client
	cfg *config.Config
}

func RegisterRoutes(r *gin.RouterGroup, db *gorm.DB, rdb *redis.Client, cfg *config.Config) {
	h := &Handler{db: db, rdb: rdb, cfg: cfg}

	users := r.Group("/user")
	users.Use(middleware.AuthRequired(cfg.JWTSecret))
	{
		users.GET("/me", h.GetMe)
		users.PUT("/me", h.UpdateMe)
		users.PUT("/me/fcm-token", h.UpdateFCMToken)
		users.DELETE("/me", h.DeleteAccount)

		// Profile
		users.GET("/profile", h.GetProfile)
		users.PUT("/profile", h.UpdateProfile)

		// Family members
		users.GET("/family", h.GetFamily)
		users.POST("/family", h.AddFamilyMember)
		users.PUT("/family/:id", h.UpdateFamilyMember)
		users.DELETE("/family/:id", h.DeleteFamilyMember)
	}
}

// GET /user/me
func (h *Handler) GetMe(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	if err := h.db.Preload("Profile").Preload("Wallet").
		Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": user})
}

// PUT /user/me
func (h *Handler) UpdateMe(c *gin.Context) {
	userID, _ := c.Get("user_id")

	type UpdateRequest struct {
		Email string `json:"email"`
	}

	var req UpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	h.db.Model(&models.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
		"email": req.Email,
	})

	c.JSON(http.StatusOK, gin.H{"message": "Updated successfully"})
}

// PUT /user/me/fcm-token
func (h *Handler) UpdateFCMToken(c *gin.Context) {
	userID, _ := c.Get("user_id")

	type FCMRequest struct {
		FCMToken string `json:"fcm_token" binding:"required"`
	}

	var req FCMRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	h.db.Model(&models.User{}).Where("id = ?", userID).Update("fcm_token", req.FCMToken)
	c.JSON(http.StatusOK, gin.H{"message": "FCM token updated"})
}

// DELETE /user/me
func (h *Handler) DeleteAccount(c *gin.Context) {
	userID, _ := c.Get("user_id")

	h.db.Model(&models.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
		"is_active": false,
		"phone":     gorm.Expr("phone || ?", "_deleted"),
		"email":     gorm.Expr("email || ?", "_deleted"),
	})

	c.JSON(http.StatusOK, gin.H{"message": "Account deleted successfully"})
}

// GET /user/profile
func (h *Handler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var profile models.UserProfile
	if err := h.db.Where("user_id = ?", userID).First(&profile).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": profile})
}

// PUT /user/profile
func (h *Handler) UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var profile models.UserProfile
	if err := h.db.Where("user_id = ?", userID).First(&profile).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	type UpdateProfileRequest struct {
		FullName  string `json:"full_name"`
		Gender    string `json:"gender"`
		City      string `json:"city"`
		State     string `json:"state"`
		Language  string `json:"language"`
		Gotra     string `json:"gotra"`
		Nakshatra string `json:"nakshatra"`
		AvatarURL string `json:"avatar_url"`
	}

	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	h.db.Model(&profile).Updates(map[string]interface{}{
		"full_name":  req.FullName,
		"gender":     req.Gender,
		"city":       req.City,
		"state":      req.State,
		"language":   req.Language,
		"gotra":      req.Gotra,
		"nakshatra":  req.Nakshatra,
		"avatar_url": req.AvatarURL,
	})

	c.JSON(http.StatusOK, gin.H{"data": profile, "message": "Profile updated successfully"})
}

// GET /user/family
func (h *Handler) GetFamily(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var members []models.FamilyMember
	h.db.Where("user_id = ?", userID).Find(&members)

	c.JSON(http.StatusOK, gin.H{"data": members})
}

// POST /user/family
func (h *Handler) AddFamilyMember(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	var member models.FamilyMember
	if err := c.ShouldBindJSON(&member); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	member.UserID = uid

	if err := h.db.Create(&member).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add family member"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"data": member, "message": "Family member added"})
}

// PUT /user/family/:id
func (h *Handler) UpdateFamilyMember(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var member models.FamilyMember
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&member).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Family member not found"})
		return
	}

	if err := c.ShouldBindJSON(&member); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	h.db.Save(&member)
	c.JSON(http.StatusOK, gin.H{"data": member, "message": "Updated successfully"})
}

// DELETE /user/family/:id
func (h *Handler) DeleteFamilyMember(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	if err := h.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.FamilyMember{}).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Family member not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Family member removed"})
}