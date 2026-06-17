package pooja

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/onebharat/backend/config"
	
	"github.com/onebharat/backend/pkg/models"
	"gorm.io/gorm"
)

type Handler struct {
	db  *gorm.DB
	cfg *config.Config
}

func RegisterRoutes(r *gin.RouterGroup, db *gorm.DB, cfg *config.Config) {
	h := &Handler{db: db, cfg: cfg}

	pooja := r.Group("/pooja")
	{
		pooja.POST("/book", h.CreateBooking)
		pooja.GET("/my-bookings", h.MyBookings)
		pooja.GET("/booking/:id", h.GetBooking)
		pooja.PUT("/booking/:id/cancel", h.CancelBooking)

		// Priest routes
		pooja.GET("/priest/bookings", h.PriestBookings)
		pooja.PUT("/booking/:id/status", h.UpdateBookingStatus)
	}
}

// POST /pooja/book
func (h *Handler) CreateBooking(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		userIDRaw = "00000000-0000-0000-0000-000000000001"
	}
	userID := userIDRaw

	type BookingRequest struct {
		TempleID       string `json:"temple_id" binding:"required"`
		PoojaServiceID string `json:"pooja_service_id" binding:"required"`
		BookingDate    string `json:"booking_date" binding:"required"` // YYYY-MM-DD
		BookingTime    string `json:"booking_time" binding:"required"` // HH:MM
		Persons        int    `json:"persons"`
		Sankalp        string `json:"sankalp"`
		Notes          string `json:"notes"`
		PaymentID      string `json:"payment_id"`
		Amount         float64 `json:"amount"`
	}

	var req BookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	templeID, _ := uuid.Parse(req.TempleID)
	serviceID, _ := uuid.Parse(req.PoojaServiceID)

	// Get service details for price
	var service models.PoojaService
	h.db.Where("id = ? AND is_active = ?", serviceID, true).First(&service)
	if service.Price == 0 && req.Amount > 0 && req.Persons > 0 {
		service.Price = req.Amount / float64(req.Persons)
	} else if service.Price == 0 {
		service.Price = 151
	}

	bookingDate, err := time.Parse("2006-01-02", req.BookingDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format. Use YYYY-MM-DD"})
		return
	}

	if bookingDate.Before(time.Now().Truncate(24 * time.Hour)) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Booking date cannot be in the past"})
		return
	}

	uid, _ := uuid.Parse(fmt.Sprintf("%v", userID))

	persons := req.Persons
	if persons == 0 {
		persons = 1
	}

	booking := models.PoojaBooking{
		UserID:         uid,
		TempleID:       templeID,
		PoojaServiceID: serviceID,
		BookingDate:    bookingDate,
		BookingTime:    req.BookingTime,
		Persons:        persons,
		Sankalp:        req.Sankalp,
		Amount:         service.Price * float64(persons),
		Status:         models.BookingPending,
		PaymentID:      req.PaymentID,
		Notes:          req.Notes,
	}
	if req.PaymentID != "" {
		booking.Status = models.BookingConfirmed
	}

	if err := h.db.Create(&booking).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create booking"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"data":    booking,
		"message": "Booking created successfully. Complete payment to confirm.",
	})
}

// GET /pooja/my-bookings?status=pending&page=1
func (h *Handler) MyBookings(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		userIDRaw = "00000000-0000-0000-0000-000000000001"
	}
	userID := userIDRaw

	query := h.db.Where("user_id = ?", userID)

	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	var bookings []models.PoojaBooking
	var total int64

	query.Model(&models.PoojaBooking{}).Count(&total)
	query.Order("booking_date desc").Limit(limit).Offset(offset).Find(&bookings)

	c.JSON(http.StatusOK, gin.H{
		"data":  bookings,
		"total": total,
		"page":  page,
	})
}

// GET /pooja/booking/:id
func (h *Handler) GetBooking(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		userIDRaw = "00000000-0000-0000-0000-000000000001"
	}
	userID := userIDRaw

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid booking ID"})
		return
	}

	var booking models.PoojaBooking
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&booking).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Booking not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": booking})
}

// PUT /pooja/booking/:id/cancel
func (h *Handler) CancelBooking(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		userIDRaw = "00000000-0000-0000-0000-000000000001"
	}
	userID := userIDRaw

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid booking ID"})
		return
	}

	var booking models.PoojaBooking
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&booking).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Booking not found"})
		return
	}

	if booking.Status == models.BookingCompleted {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot cancel a completed booking"})
		return
	}

	if booking.Status == models.BookingCancelled {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Booking already cancelled"})
		return
	}

	h.db.Model(&booking).Update("status", models.BookingCancelled)

	c.JSON(http.StatusOK, gin.H{"message": "Booking cancelled successfully"})
}

// GET /pooja/priest/bookings (priest sees their assigned bookings)
func (h *Handler) PriestBookings(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		userIDRaw = "00000000-0000-0000-0000-000000000001"
	}
	userID := userIDRaw

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	var bookings []models.PoojaBooking
	var total int64

	query := h.db.Where("priest_id = ?", userID)

	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	query.Model(&models.PoojaBooking{}).Count(&total)
	query.Order("booking_date asc").Limit(limit).Offset(offset).Find(&bookings)

	c.JSON(http.StatusOK, gin.H{
		"data":  bookings,
		"total": total,
		"page":  page,
	})
}

// PUT /pooja/booking/:id/status (priest updates status)
func (h *Handler) UpdateBookingStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid booking ID"})
		return
	}

	type StatusRequest struct {
		Status string `json:"status" binding:"required"` // confirmed, completed, cancelled
	}

	var req StatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	validStatuses := map[string]bool{
		"confirmed": true,
		"completed": true,
		"cancelled": true,
	}

	if !validStatuses[req.Status] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status"})
		return
	}

	var booking models.PoojaBooking
	if err := h.db.Where("id = ?", id).First(&booking).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Booking not found"})
		return
	}

	h.db.Model(&booking).Update("status", req.Status)

	c.JSON(http.StatusOK, gin.H{"message": "Booking status updated", "data": booking})
}