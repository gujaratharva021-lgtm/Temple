package astrology

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/onebharat/backend/config"
	"github.com/onebharat/backend/pkg/middleware"
	"github.com/onebharat/backend/pkg/models"
	"gorm.io/gorm"
)

type Handler struct {
	db  *gorm.DB
	cfg *config.Config
}

func RegisterRoutes(r *gin.RouterGroup, db *gorm.DB, cfg *config.Config) {
	h := &Handler{db: db, cfg: cfg}

	astrology := r.Group("/astrology")
	{
		astrology.GET("/astrologers", h.ListAstrologers)
		astrology.GET("/astrologers/:id", h.GetAstrologer)

		auth := astrology.Group("")
		auth.Use(middleware.AuthRequired(cfg.JWTSecret))
		{
			auth.POST("/consultations", h.BookConsultation)
			auth.GET("/consultations", h.MyConsultations)
			auth.GET("/consultations/:id", h.GetConsultation)
			auth.PUT("/consultations/:id/cancel", h.CancelConsultation)
			auth.GET("/my-appointments", h.AstrologerAppointments)
			auth.PUT("/consultations/:id/status", h.UpdateConsultationStatus)
			auth.PUT("/consultations/:id/report", h.UploadReport)
		}
	}
}

// GET /astrology/astrologers
func (h *Handler) ListAstrologers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	var astrologers []models.User
	var total int64

	query := h.db.Where("role = ? AND is_active = ?", models.RoleAstrologer, true)
	query.Count(&total)
	query.Preload("Profile").Limit(limit).Offset(offset).Find(&astrologers)

	c.JSON(http.StatusOK, gin.H{"data": astrologers, "total": total, "page": page})
}

// GET /astrology/astrologers/:id
func (h *Handler) GetAstrologer(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid astrologer ID"})
		return
	}

	var astrologer models.User
	if err := h.db.Preload("Profile").
		Where("id = ? AND role = ? AND is_active = ?", id, models.RoleAstrologer, true).
		First(&astrologer).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Astrologer not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": astrologer})
}

// POST /astrology/consultations
func (h *Handler) BookConsultation(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	type ConsultationRequest struct {
		AstrologerID string `json:"astrologer_id" binding:"required"`
		Type         string `json:"type" binding:"required"`
		Mode         string `json:"mode" binding:"required"`
		ScheduledAt  string `json:"scheduled_at" binding:"required"`
		Duration     int    `json:"duration_minutes"`
		Notes        string `json:"notes"`
	}

	var req ConsultationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	astrologerID, err := uuid.Parse(req.AstrologerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid astrologer ID"})
		return
	}

	var astrologer models.User
	if err := h.db.Where("id = ? AND role = ? AND is_active = ?", astrologerID, models.RoleAstrologer, true).
		First(&astrologer).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Astrologer not found"})
		return
	}

	validTypes := map[string]bool{"kundli": true, "horoscope": true, "matchmaking": true, "muhurat": true, "vastu": true}
	if !validTypes[req.Type] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid type. Use: kundli, horoscope, matchmaking, muhurat, vastu"})
		return
	}

	validModes := map[string]bool{"chat": true, "call": true, "video": true}
	if !validModes[req.Mode] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mode. Use: chat, call, video"})
		return
	}

	duration := req.Duration
	if duration == 0 {
		duration = 30
	}

	pricePerMin := map[string]float64{"chat": 5, "call": 10, "video": 15}
	amount := pricePerMin[req.Mode] * float64(duration)

	scheduledAt, err := time.Parse(time.RFC3339, req.ScheduledAt)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date. Use RFC3339 format: 2006-01-02T15:04:05Z"})
		return
	}

	consultation := models.AstrologyConsultation{
		UserID:       uid,
		AstrologerID: astrologerID,
		Type:         req.Type,
		Mode:         req.Mode,
		ScheduledAt:  scheduledAt,
		Duration:     duration,
		Amount:       amount,
		Status:       "pending",
		Notes:        req.Notes,
	}

	if err := h.db.Create(&consultation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to book consultation"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"data":    consultation,
		"message": "Consultation booked. Complete payment to confirm.",
	})
}

// GET /astrology/consultations
func (h *Handler) MyConsultations(c *gin.Context) {
	userID, _ := c.Get("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	query := h.db.Where("user_id = ?", userID)
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	var consultations []models.AstrologyConsultation
	var total int64

	query.Model(&models.AstrologyConsultation{}).Count(&total)
	query.Order("scheduled_at desc").Limit(limit).Offset(offset).Find(&consultations)

	c.JSON(http.StatusOK, gin.H{"data": consultations, "total": total, "page": page})
}

// GET /astrology/consultations/:id
func (h *Handler) GetConsultation(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid consultation ID"})
		return
	}

	var consultation models.AstrologyConsultation
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&consultation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Consultation not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": consultation})
}

// PUT /astrology/consultations/:id/cancel
func (h *Handler) CancelConsultation(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid consultation ID"})
		return
	}

	var consultation models.AstrologyConsultation
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&consultation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Consultation not found"})
		return
	}

	if consultation.Status == "completed" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot cancel a completed consultation"})
		return
	}
	if consultation.Status == "cancelled" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Consultation already cancelled"})
		return
	}

	h.db.Model(&consultation).Update("status", "cancelled")
	c.JSON(http.StatusOK, gin.H{"message": "Consultation cancelled successfully"})
}

// GET /astrology/my-appointments (astrologer)
func (h *Handler) AstrologerAppointments(c *gin.Context) {
	userID, _ := c.Get("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	query := h.db.Where("astrologer_id = ?", userID)
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	var consultations []models.AstrologyConsultation
	var total int64

	query.Model(&models.AstrologyConsultation{}).Count(&total)
	query.Order("scheduled_at asc").Limit(limit).Offset(offset).Find(&consultations)

	c.JSON(http.StatusOK, gin.H{"data": consultations, "total": total, "page": page})
}

// PUT /astrology/consultations/:id/status (astrologer)
func (h *Handler) UpdateConsultationStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid consultation ID"})
		return
	}

	type StatusRequest struct {
		Status string `json:"status" binding:"required"`
	}

	var req StatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	validStatuses := map[string]bool{"confirmed": true, "completed": true, "cancelled": true}
	if !validStatuses[req.Status] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status"})
		return
	}

	var consultation models.AstrologyConsultation
	if err := h.db.Where("id = ?", id).First(&consultation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Consultation not found"})
		return
	}

	h.db.Model(&consultation).Update("status", req.Status)
	c.JSON(http.StatusOK, gin.H{"message": "Status updated", "data": consultation})
}

// PUT /astrology/consultations/:id/report (astrologer uploads report URL)
func (h *Handler) UploadReport(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid consultation ID"})
		return
	}

	type ReportRequest struct {
		ReportURL string `json:"report_url" binding:"required"`
	}

	var req ReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var consultation models.AstrologyConsultation
	if err := h.db.Where("id = ?", id).First(&consultation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Consultation not found"})
		return
	}

	h.db.Model(&consultation).Updates(map[string]interface{}{
		"report_url": req.ReportURL,
		"status":     "completed",
	})

	c.JSON(http.StatusOK, gin.H{"message": "Report uploaded successfully"})
}