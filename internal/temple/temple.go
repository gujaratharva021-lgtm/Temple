package temple

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/onebharat/backend/config"
	"github.com/onebharat/backend/pkg/middleware"
	"github.com/onebharat/backend/pkg/models"
	"go.mongodb.org/mongo-driver/mongo"
	"gorm.io/gorm"
)

type Handler struct {
	db  *gorm.DB
	mdb *mongo.Database
	cfg *config.Config
}

func RegisterRoutes(r *gin.RouterGroup, db *gorm.DB, mdb *mongo.Database, cfg *config.Config) {
	h := &Handler{db: db, mdb: mdb, cfg: cfg}

	temples := r.Group("/temples")
	{
		temples.GET("", h.ListTemples)
		temples.GET("/nearby", h.NearbyTemples)
		temples.GET("/:id", h.GetTemple)
		temples.GET("/:id/services", h.GetTempleServices)
		temples.GET("/:id/live-darshan", h.GetLiveDarshan)

		admin := temples.Group("")
		admin.Use(middleware.AuthRequired(cfg.JWTSecret))
		{
			admin.POST("", h.CreateTemple)
			admin.PUT("/:id", h.UpdateTemple)
			admin.DELETE("/:id", h.DeleteTemple)
			admin.POST("/:id/services", h.AddPoojaService)
			admin.PUT("/:id/services/:sid", h.UpdatePoojaService)
			admin.POST("/:id/live-darshan", h.CreateLiveDarshan)
		}
	}
}

// GET /temples?city=Mumbai&state=Maharashtra&deity=Shiva&page=1&limit=20
func (h *Handler) ListTemples(c *gin.Context) {
	var temples []models.Temple

	query := h.db.Where("is_active = ?", true)

	if city := c.Query("city"); city != "" {
		query = query.Where("city ILIKE ?", "%"+city+"%")
	}
	if state := c.Query("state"); state != "" {
		query = query.Where("state ILIKE ?", "%"+state+"%")
	}
	if deity := c.Query("deity"); deity != "" {
		query = query.Where("deity ILIKE ?", "%"+deity+"%")
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("name ILIKE ? OR description ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	var total int64
	query.Model(&models.Temple{}).Count(&total)

	query.Limit(limit).Offset(offset).Find(&temples)

	c.JSON(http.StatusOK, gin.H{
		"data":  temples,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// GET /temples/nearby?lat=19.0760&lng=72.8777&radius=10
func (h *Handler) NearbyTemples(c *gin.Context) {
	lat, err1 := strconv.ParseFloat(c.Query("lat"), 64)
	lng, err2 := strconv.ParseFloat(c.Query("lng"), 64)
	if err1 != nil || err2 != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid lat/lng"})
		return
	}

	radius, _ := strconv.ParseFloat(c.DefaultQuery("radius", "10"), 64)

	var temples []models.Temple
	// Haversine formula in SQL
	h.db.Where("is_active = ?", true).
		Where(`(6371 * acos(cos(radians(?)) * cos(radians(latitude)) *
			cos(radians(longitude) - radians(?)) +
			sin(radians(?)) * sin(radians(latitude)))) < ?`,
			lat, lng, lat, radius).
		Limit(20).
		Find(&temples)

	c.JSON(http.StatusOK, gin.H{"data": temples})
}

// GET /temples/:id
func (h *Handler) GetTemple(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	var temple models.Temple
	if err := h.db.Preload("Services").Where("id = ? AND is_active = ?", id, true).First(&temple).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Temple not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": temple})
}

// GET /temples/:id/services
func (h *Handler) GetTempleServices(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	var services []models.PoojaService
	h.db.Where("temple_id = ? AND is_active = ?", id, true).Find(&services)

	c.JSON(http.StatusOK, gin.H{"data": services})
}

// GET /temples/:id/live-darshan
func (h *Handler) GetLiveDarshan(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	var darshans []models.LiveDarshan
	h.db.Where("temple_id = ?", id).Order("created_at desc").Limit(5).Find(&darshans)

	c.JSON(http.StatusOK, gin.H{"data": darshans})
}

// POST /temples (admin only)
func (h *Handler) CreateTemple(c *gin.Context) {
	var temple models.Temple
	if err := c.ShouldBindJSON(&temple); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.db.Create(&temple).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create temple"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"data": temple, "message": "Temple created successfully"})
}

// PUT /temples/:id (admin only)
func (h *Handler) UpdateTemple(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	var temple models.Temple
	if err := h.db.Where("id = ?", id).First(&temple).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Temple not found"})
		return
	}

	if err := c.ShouldBindJSON(&temple); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	h.db.Save(&temple)
	c.JSON(http.StatusOK, gin.H{"data": temple, "message": "Temple updated successfully"})
}

// DELETE /temples/:id (admin only)
func (h *Handler) DeleteTemple(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	h.db.Model(&models.Temple{}).Where("id = ?", id).Update("is_active", false)
	c.JSON(http.StatusOK, gin.H{"message": "Temple deleted successfully"})
}

// POST /temples/:id/services (admin only)
func (h *Handler) AddPoojaService(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	var service models.PoojaService
	if err := c.ShouldBindJSON(&service); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	service.TempleID = id
	if err := h.db.Create(&service).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add service"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"data": service, "message": "Service added successfully"})
}

// PUT /temples/:id/services/:sid (admin only)
func (h *Handler) UpdatePoojaService(c *gin.Context) {
	sid, err := uuid.Parse(c.Param("sid"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid service ID"})
		return
	}

	var service models.PoojaService
	if err := h.db.Where("id = ?", sid).First(&service).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
		return
	}

	if err := c.ShouldBindJSON(&service); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	h.db.Save(&service)
	c.JSON(http.StatusOK, gin.H{"data": service, "message": "Service updated successfully"})
}

// POST /temples/:id/live-darshan (admin only)
func (h *Handler) CreateLiveDarshan(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	var darshan models.LiveDarshan
	if err := c.ShouldBindJSON(&darshan); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	darshan.TempleID = id
	if err := h.db.Create(&darshan).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create live darshan"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"data": darshan, "message": "Live darshan created"})
}