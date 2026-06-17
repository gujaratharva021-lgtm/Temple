package notification

import (
	"net/http"
	"strconv"

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

	notif := r.Group("/notifications")
	notif.Use(middleware.AuthRequired(cfg.JWTSecret))
	{
		notif.GET("", h.GetNotifications)
		notif.PUT("/:id/read", h.MarkRead)
		notif.PUT("/read-all", h.MarkAllRead)
		notif.DELETE("/:id", h.DeleteNotification)
		notif.GET("/unread-count", h.UnreadCount)
	}
}

// GET /notifications?page=1&limit=20
func (h *Handler) GetNotifications(c *gin.Context) {
	userID, _ := c.Get("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	query := h.db.Where("user_id = ?", userID)

	if notifType := c.Query("type"); notifType != "" {
		query = query.Where("type = ?", notifType)
	}
	if isRead := c.Query("is_read"); isRead != "" {
		query = query.Where("is_read = ?", isRead == "true")
	}

	var notifications []models.Notification
	var total int64

	query.Model(&models.Notification{}).Count(&total)
	query.Order("created_at desc").Limit(limit).Offset(offset).Find(&notifications)

	c.JSON(http.StatusOK, gin.H{
		"data":  notifications,
		"total": total,
		"page":  page,
	})
}

// PUT /notifications/:id/read
func (h *Handler) MarkRead(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid notification ID"})
		return
	}

	result := h.db.Model(&models.Notification{}).
		Where("id = ? AND user_id = ?", id, userID).
		Update("is_read", true)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Marked as read"})
}

// PUT /notifications/read-all
func (h *Handler) MarkAllRead(c *gin.Context) {
	userID, _ := c.Get("user_id")

	h.db.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Update("is_read", true)

	c.JSON(http.StatusOK, gin.H{"message": "All notifications marked as read"})
}

// DELETE /notifications/:id
func (h *Handler) DeleteNotification(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid notification ID"})
		return
	}

	result := h.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Notification{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Notification deleted"})
}

// GET /notifications/unread-count
func (h *Handler) UnreadCount(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var count int64
	h.db.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Count(&count)

	c.JSON(http.StatusOK, gin.H{"unread_count": count})
}

// SendNotification - internal helper, dusre services use karte hain
func SendNotification(db *gorm.DB, userID uuid.UUID, title, body, notifType, data string) error {
	notification := models.Notification{
		UserID: userID,
		Title:  title,
		Body:   body,
		Type:   notifType,
		IsRead: false,
		Data:   data,
	}
	return db.Create(&notification).Error
}