package store

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

	store := r.Group("/store")
	{
		// Public routes
		store.GET("/products", h.ListProducts)
		store.GET("/products/:id", h.GetProduct)

		// Auth required
		auth := store.Group("")
		auth.Use(middleware.AuthRequired(cfg.JWTSecret))
		{
			auth.POST("/orders", h.CreateOrder)
			auth.GET("/orders", h.MyOrders)
			auth.GET("/orders/:id", h.GetOrder)
			auth.PUT("/orders/:id/cancel", h.CancelOrder)

			// Admin only
			auth.POST("/products", h.CreateProduct)
			auth.PUT("/products/:id", h.UpdateProduct)
			auth.DELETE("/products/:id", h.DeleteProduct)
		}
	}
}

// GET /store/products?category=prasad&temple_id=xxx&page=1
func (h *Handler) ListProducts(c *gin.Context) {
	query := h.db.Where("is_active = ?", true)

	if category := c.Query("category"); category != "" {
		query = query.Where("category = ?", category)
	}
	if templeID := c.Query("temple_id"); templeID != "" {
		query = query.Where("temple_id = ?", templeID)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("name ILIKE ? OR description ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	var products []models.Product
	var total int64

	query.Model(&models.Product{}).Count(&total)
	query.Order("created_at desc").Limit(limit).Offset(offset).Find(&products)

	c.JSON(http.StatusOK, gin.H{
		"data":  products,
		"total": total,
		"page":  page,
	})
}

// GET /store/products/:id
func (h *Handler) GetProduct(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	var product models.Product
	if err := h.db.Where("id = ? AND is_active = ?", id, true).First(&product).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": product})
}

// POST /store/products (admin)
func (h *Handler) CreateProduct(c *gin.Context) {
	var product models.Product
	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.db.Create(&product).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create product"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"data": product, "message": "Product created successfully"})
}

// PUT /store/products/:id (admin)
func (h *Handler) UpdateProduct(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	var product models.Product
	if err := h.db.Where("id = ?", id).First(&product).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	h.db.Save(&product)
	c.JSON(http.StatusOK, gin.H{"data": product, "message": "Product updated successfully"})
}

// DELETE /store/products/:id (admin)
func (h *Handler) DeleteProduct(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	h.db.Model(&models.Product{}).Where("id = ?", id).Update("is_active", false)
	c.JSON(http.StatusOK, gin.H{"message": "Product deleted successfully"})
}

// POST /store/orders
func (h *Handler) CreateOrder(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	type OrderItemRequest struct {
		ProductID string `json:"product_id" binding:"required"`
		Quantity  int    `json:"quantity" binding:"required,min=1"`
	}

	type OrderRequest struct {
		Items           []OrderItemRequest `json:"items" binding:"required,min=1"`
		ShippingAddress string             `json:"shipping_address" binding:"required"`
	}

	var req OrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Calculate total and validate stock
	var total float64
	var orderItems []models.OrderItem

	for _, item := range req.Items {
		productID, err := uuid.Parse(item.ProductID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID: " + item.ProductID})
			return
		}

		var product models.Product
		if err := h.db.Where("id = ? AND is_active = ?", productID, true).First(&product).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found: " + item.ProductID})
			return
		}

		if product.Stock < item.Quantity {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Insufficient stock for: " + product.Name})
			return
		}

		total += product.Price * float64(item.Quantity)

		orderItems = append(orderItems, models.OrderItem{
			ProductID: productID,
			Quantity:  item.Quantity,
			Price:     product.Price,
		})
	}

	// Create order
	order := models.Order{
		UserID:          uid,
		TotalAmount:     total,
		Status:          "pending",
		ShippingAddress: req.ShippingAddress,
	}

	if err := h.db.Create(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create order"})
		return
	}

	// Create order items and deduct stock
	for i := range orderItems {
		orderItems[i].OrderID = order.ID
		h.db.Create(&orderItems[i])
		h.db.Model(&models.Product{}).
			Where("id = ?", orderItems[i].ProductID).
			UpdateColumn("stock", gorm.Expr("stock - ?", orderItems[i].Quantity))
	}

	// Load items in response
	h.db.Preload("Items").Where("id = ?", order.ID).First(&order)

	c.JSON(http.StatusCreated, gin.H{
		"data":    order,
		"message": "Order placed successfully. Complete payment to confirm.",
	})
}

// GET /store/orders?status=pending
func (h *Handler) MyOrders(c *gin.Context) {
	userID, _ := c.Get("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	query := h.db.Where("user_id = ?", userID)

	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	var orders []models.Order
	var total int64

	query.Model(&models.Order{}).Count(&total)
	query.Preload("Items").Order("created_at desc").Limit(limit).Offset(offset).Find(&orders)

	c.JSON(http.StatusOK, gin.H{
		"data":  orders,
		"total": total,
		"page":  page,
	})
}

// GET /store/orders/:id
func (h *Handler) GetOrder(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid order ID"})
		return
	}

	var order models.Order
	if err := h.db.Preload("Items").Where("id = ? AND user_id = ?", id, userID).First(&order).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": order})
}

// PUT /store/orders/:id/cancel
func (h *Handler) CancelOrder(c *gin.Context) {
	userID, _ := c.Get("user_id")

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid order ID"})
		return
	}

	var order models.Order
	if err := h.db.Preload("Items").Where("id = ? AND user_id = ?", id, userID).First(&order).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	if order.Status == "completed" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot cancel a completed order"})
		return
	}

	if order.Status == "cancelled" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Order already cancelled"})
		return
	}

	// Restore stock
	for _, item := range order.Items {
		h.db.Model(&models.Product{}).
			Where("id = ?", item.ProductID).
			UpdateColumn("stock", gorm.Expr("stock + ?", item.Quantity))
	}

	h.db.Model(&order).Update("status", "cancelled")
	c.JSON(http.StatusOK, gin.H{"message": "Order cancelled successfully"})
}