package wallet

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/http"
	"strconv"

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

	wallet := r.Group("/wallet")
	wallet.Use(middleware.AuthRequired(cfg.JWTSecret))
	{
		wallet.GET("", h.GetWallet)
		wallet.GET("/transactions", h.GetTransactions)
		wallet.POST("/donate", h.Donate)
		wallet.GET("/donations", h.MyDonations)

		// ── Razorpay top-up ──────────────────────────────────────────────
		wallet.POST("/create-order", h.CreateRazorpayOrder)
		wallet.POST("/verify-payment", h.VerifyAndCredit)
	}
}

// ── Existing handlers (unchanged) ─────────────────────────────────────────────

// GET /wallet
func (h *Handler) GetWallet(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var wallet models.Wallet
	if err := h.db.Where("user_id = ?", userID).First(&wallet).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wallet not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": wallet})
}

// GET /wallet/transactions
func (h *Handler) GetTransactions(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var wallet models.Wallet
	if err := h.db.Where("user_id = ?", userID).First(&wallet).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wallet not found"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	query := h.db.Where("wallet_id = ?", wallet.ID)
	if currency := c.Query("currency"); currency != "" {
		query = query.Where("currency = ?", currency)
	}
	if txType := c.Query("type"); txType != "" {
		query = query.Where("type = ?", txType)
	}
	if category := c.Query("category"); category != "" {
		query = query.Where("category = ?", category)
	}

	var transactions []models.WalletTransaction
	var total int64
	query.Model(&models.WalletTransaction{}).Count(&total)
	query.Order("created_at desc").Limit(limit).Offset(offset).Find(&transactions)

	c.JSON(http.StatusOK, gin.H{"data": transactions, "total": total, "page": page})
}

// POST /wallet/donate
func (h *Handler) Donate(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	type DonateRequest struct {
		TempleID    string  `json:"temple_id" binding:"required"`
		Amount      float64 `json:"amount" binding:"required,min=1"`
		Message     string  `json:"message"`
		IsAnonymous bool    `json:"is_anonymous"`
	}

	var req DonateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	templeID, err := uuid.Parse(req.TempleID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid temple ID"})
		return
	}

	var wallet models.Wallet
	if err := h.db.Where("user_id = ?", uid).First(&wallet).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wallet not found"})
		return
	}

	if wallet.INRBalance < req.Amount {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Insufficient wallet balance"})
		return
	}

	donation := models.Donation{
		UserID:      uid,
		TempleID:    templeID,
		Amount:      req.Amount,
		Message:     req.Message,
		IsAnonymous: req.IsAnonymous,
	}
	if err := h.db.Create(&donation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process donation"})
		return
	}

	newBalance := wallet.INRBalance - req.Amount
	h.db.Model(&wallet).Update("inr_balance", newBalance)
	h.db.Create(&models.WalletTransaction{
		WalletID:    wallet.ID,
		Type:        "debit",
		Category:    "donation",
		Amount:      req.Amount,
		Currency:    "INR",
		Description: "Donation to temple",
		ReferenceID: donation.ID.String(),
		Balance:     newBalance,
	})

	c.JSON(http.StatusCreated, gin.H{"data": donation, "message": "Donation successful. Jai Shree Ram! 🙏"})
}

// GET /wallet/donations
func (h *Handler) MyDonations(c *gin.Context) {
	userID, _ := c.Get("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset := (page - 1) * limit

	var donations []models.Donation
	var total int64
	h.db.Model(&models.Donation{}).Where("user_id = ?", userID).Count(&total)
	h.db.Where("user_id = ?", userID).Order("created_at desc").Limit(limit).Offset(offset).Find(&donations)

	c.JSON(http.StatusOK, gin.H{"data": donations, "total": total, "page": page})
}

// ── NEW: Razorpay Wallet Top-up ───────────────────────────────────────────────

// POST /wallet/create-order
// Flutter calls this before opening Razorpay checkout.
// For simple wallet top-up we don't need a Razorpay Order — just return
// the key so Flutter can open the checkout directly.
// (If you want full order-based flow later, integrate Razorpay Go SDK here.)
func (h *Handler) CreateRazorpayOrder(c *gin.Context) {
	type Req struct {
		Amount   float64 `json:"amount" binding:"required,min=10"`
		Currency string  `json:"currency"`
	}
	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Currency == "" {
		req.Currency = "INR"
	}

	// Return key + amount so Flutter can open checkout.
	// order_id is empty — Flutter will open keyless checkout (works for test mode).
	c.JSON(http.StatusOK, gin.H{
		"order_id": "",          // fill with real Razorpay order ID if you integrate Go SDK
		"amount":   req.Amount,
		"currency": req.Currency,
		"key":      h.cfg.RazorpayKey,
	})
}

// POST /wallet/verify-payment
// Flutter sends payment_id + order_id + signature after successful checkout.
// We verify HMAC signature, then credit the wallet.
func (h *Handler) VerifyAndCredit(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	type Req struct {
		PaymentID string  `json:"razorpay_payment_id" binding:"required"`
		OrderID   string  `json:"razorpay_order_id"`   // empty for keyless checkout
		Signature string  `json:"razorpay_signature"`  // empty for keyless checkout
		Amount    float64 `json:"amount" binding:"required,min=10"`
	}
	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// ── Signature verification (skip if order_id is empty — test/keyless mode) ──
	if req.OrderID != "" && req.Signature != "" {
		secret := h.cfg.RazorpaySecret
		payload := fmt.Sprintf("%s|%s", req.OrderID, req.PaymentID)
		mac := hmac.New(sha256.New, []byte(secret))
		mac.Write([]byte(payload))
		expected := hex.EncodeToString(mac.Sum(nil))
		if expected != req.Signature {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid payment signature"})
			return
		}
	}

	// ── Idempotency: check if this payment_id already credited ───────────────
	var existing models.WalletTransaction
	if err := h.db.Where("reference_id = ?", req.PaymentID).First(&existing).Error; err == nil {
		// Already credited — return current balance
		var wallet models.Wallet
		h.db.Where("user_id = ?", uid).First(&wallet)
		c.JSON(http.StatusOK, gin.H{
			"message": "Already credited",
			"balance": wallet.INRBalance,
		})
		return
	}

	// ── Credit wallet ─────────────────────────────────────────────────────────
	var wallet models.Wallet
	if err := h.db.Where("user_id = ?", uid).First(&wallet).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Wallet not found"})
		return
	}

	newBalance := wallet.INRBalance + req.Amount
	if err := h.db.Model(&wallet).Update("inr_balance", newBalance).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Balance update failed"})
		return
	}

	// ── Record transaction ────────────────────────────────────────────────────
	h.db.Create(&models.WalletTransaction{
		WalletID:    wallet.ID,
		Type:        "credit",
		Category:    "topup",
		Amount:      req.Amount,
		Currency:    "INR",
		Description: fmt.Sprintf("Wallet top-up via Razorpay"),
		ReferenceID: req.PaymentID,
		Balance:     newBalance,
	})

	c.JSON(http.StatusOK, gin.H{
		"message": "Wallet credited successfully 🙏",
		"balance": newBalance,
	})
}