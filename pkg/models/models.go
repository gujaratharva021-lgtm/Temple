package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ─── BASE MODEL ─────────────────────────────────────────────────────────────

type Base struct {
	ID        uuid.UUID      `gorm:"type:uuid;primary_key" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

func (b *Base) BeforeCreate(tx *gorm.DB) error {
	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}
	return nil
}

// ─── USER ────────────────────────────────────────────────────────────────────

type UserRole string

const (
	RoleDevotee    UserRole = "devotee"
	RolePriest     UserRole = "priest"
	RoleAstrologer UserRole = "astrologer"
	RoleAdmin      UserRole = "admin"
	RoleTrustee    UserRole = "trustee"
)

type User struct {
	Base
	Phone        string   `gorm:"uniqueIndex;not null" json:"phone"`
	Email        string   `gorm:"uniqueIndex" json:"email"`
	PasswordHash string   `gorm:"->;-:migration" json:"-"`
	Role         UserRole `gorm:"default:devotee" json:"role"`
	IsVerified   bool     `gorm:"default:false" json:"is_verified"`
	IsActive     bool     `gorm:"default:true" json:"is_active"`
	FCMToken     string   `json:"fcm_token,omitempty"`

	Profile  *UserProfile `gorm:"foreignKey:UserID" json:"profile,omitempty"`
	Wallet   *Wallet      `gorm:"foreignKey:UserID" json:"wallet,omitempty"`
}

type UserProfile struct {
	Base
	UserID      uuid.UUID  `gorm:"type:uuid;not null" json:"user_id"`
	FullName    string     `json:"full_name"`
	DateOfBirth *time.Time `json:"date_of_birth,omitempty"`
	Gender      string     `json:"gender"`
	AvatarURL   string     `json:"avatar_url"`
	City        string     `json:"city"`
	State       string     `json:"state"`
	Language    string     `gorm:"default:hi" json:"language"`
	Gotra       string     `json:"gotra,omitempty"`
	Nakshatra   string     `json:"nakshatra,omitempty"`
}

// ─── FAMILY ──────────────────────────────────────────────────────────────────

type FamilyMember struct {
	Base
	UserID      uuid.UUID  `gorm:"type:uuid;not null" json:"user_id"`
	FullName    string     `json:"full_name"`
	Relation    string     `json:"relation"` // spouse, son, daughter, parent
	DateOfBirth *time.Time `json:"date_of_birth,omitempty"`
	Gender      string     `json:"gender"`
	Gotra       string     `json:"gotra,omitempty"`
	Nakshatra   string     `json:"nakshatra,omitempty"`
}

// ─── TEMPLE ──────────────────────────────────────────────────────────────────

type Temple struct {
	Base
	Name       string  `gorm:"not null" json:"name"`
	Description string `json:"description"`
	Deity      string  `json:"deity"`
	Address    string  `json:"address"`
	City       string  `json:"city"`
	State      string  `json:"state"`
	Pincode    string  `json:"pincode"`
	Latitude   float64 `json:"latitude"`
	Longitude  float64 `json:"longitude"`
	Phone      string  `json:"phone"`
	Email      string  `json:"email"`
	Website    string  `json:"website"`
	ImageURL   string  `json:"image_url"`
	IsVerified bool    `gorm:"default:false" json:"is_verified"`
	IsActive   bool    `gorm:"default:true" json:"is_active"`
	TrustRegNo string  `json:"trust_reg_no"`
	OpenTime   string  `json:"open_time"`
	CloseTime  string  `json:"close_time"`

	Staff    []TempleStaff  `gorm:"foreignKey:TempleID" json:"staff,omitempty"`
	Services []PoojaService `gorm:"foreignKey:TempleID" json:"services,omitempty"`
}

type TempleStaff struct {
	Base
	TempleID uuid.UUID `gorm:"type:uuid;not null" json:"temple_id"`
	UserID   uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	Role     string    `json:"role"` // head_priest, priest, manager
	IsActive bool      `gorm:"default:true" json:"is_active"`
}

// ─── POOJA ───────────────────────────────────────────────────────────────────

type PoojaService struct {
	Base
	TempleID    uuid.UUID `gorm:"type:uuid;not null" json:"temple_id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Duration    int       `json:"duration_minutes"`
	Price       float64   `json:"price"`
	MaxPersons  int       `json:"max_persons"`
	ImageURL    string    `json:"image_url"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	IsOnline    bool      `gorm:"default:false" json:"is_online"`
}

type BookingStatus string

const (
	BookingPending   BookingStatus = "pending"
	BookingConfirmed BookingStatus = "confirmed"
	BookingCompleted BookingStatus = "completed"
	BookingCancelled BookingStatus = "cancelled"
)

type PoojaBooking struct {
	Base
	UserID         uuid.UUID     `gorm:"type:uuid;not null" json:"user_id"`
	TempleID       uuid.UUID     `gorm:"type:uuid;not null" json:"temple_id"`
	PoojaServiceID uuid.UUID     `gorm:"type:uuid;not null" json:"pooja_service_id"`
	BookingDate    time.Time     `json:"booking_date"`
	BookingTime    string        `json:"booking_time"`
	Persons        int           `gorm:"default:1" json:"persons"`
	Sankalp        string        `json:"sankalp"`
	Amount         float64       `json:"amount"`
	Status         BookingStatus `gorm:"default:pending" json:"status"`
	PaymentID      string        `json:"payment_id"`
	PriestID       *uuid.UUID    `gorm:"type:uuid" json:"priest_id,omitempty"`
	Notes          string        `json:"notes"`
}

// ─── STORE ───────────────────────────────────────────────────────────────────

type Product struct {
	Base
	TempleID    *uuid.UUID `gorm:"type:uuid" json:"temple_id,omitempty"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	Category    string     `json:"category"` // prasad, samagri, books, mala
	Price       float64    `json:"price"`
	Stock       int        `json:"stock"`
	ImageURL    string     `json:"image_url"`
	IsActive    bool       `gorm:"default:true" json:"is_active"`
	Weight      float64    `json:"weight_grams"`
}

type Order struct {
	Base
	UserID          uuid.UUID   `gorm:"type:uuid;not null" json:"user_id"`
	TotalAmount     float64     `json:"total_amount"`
	Status          string      `gorm:"default:pending" json:"status"`
	PaymentID       string      `json:"payment_id"`
	ShippingAddress string      `json:"shipping_address"`
	Items           []OrderItem `gorm:"foreignKey:OrderID" json:"items,omitempty"`
}

type OrderItem struct {
	Base
	OrderID   uuid.UUID `gorm:"type:uuid;not null" json:"order_id"`
	ProductID uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	Quantity  int       `json:"quantity"`
	Price     float64   `json:"price"`
}

// ─── ASTROLOGY ───────────────────────────────────────────────────────────────

type AstrologyConsultation struct {
	Base
	UserID       uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	AstrologerID uuid.UUID `gorm:"type:uuid;not null" json:"astrologer_id"`
	Type         string    `json:"type"` // kundli, horoscope, matchmaking, muhurat, vastu
	Mode         string    `json:"mode"` // chat, call, video
	ScheduledAt  time.Time `json:"scheduled_at"`
	Duration     int       `json:"duration_minutes"`
	Amount       float64   `json:"amount"`
	Status       string    `gorm:"default:pending" json:"status"`
	Notes        string    `json:"notes"`
	ReportURL    string    `json:"report_url"`
}

// ─── WALLET ──────────────────────────────────────────────────────────────────

type Wallet struct {
	Base
	UserID     uuid.UUID `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	OBCBalance float64   `gorm:"default:0" json:"obc_balance"`
	INRBalance float64   `gorm:"default:0" json:"inr_balance"`
	IsActive   bool      `gorm:"default:true" json:"is_active"`

	Transactions []WalletTransaction `gorm:"foreignKey:WalletID" json:"transactions,omitempty"`
}

type WalletTransaction struct {
	Base
	WalletID    uuid.UUID `gorm:"type:uuid;not null" json:"wallet_id"`
	Type        string    `json:"type"`     // credit, debit
	Category    string    `json:"category"` // donation, booking, purchase, reward, cashback
	Amount      float64   `json:"amount"`
	Currency    string    `gorm:"default:INR" json:"currency"` // INR, OBC
	Description string    `json:"description"`
	ReferenceID string    `json:"reference_id"`
	Balance     float64   `json:"balance_after"`
}

// ─── DONATION ────────────────────────────────────────────────────────────────

type Donation struct {
	Base
	UserID      uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	TempleID    uuid.UUID `gorm:"type:uuid;not null" json:"temple_id"`
	Amount      float64   `json:"amount"`
	Message     string    `json:"message"`
	PaymentID   string    `json:"payment_id"`
	IsAnonymous bool      `gorm:"default:false" json:"is_anonymous"`
}

// ─── LIVE DARSHAN ────────────────────────────────────────────────────────────

type LiveDarshan struct {
	Base
	TempleID     uuid.UUID  `gorm:"type:uuid;not null" json:"temple_id"`
	Title        string     `json:"title"`
	StreamURL    string     `json:"stream_url"`
	ThumbnailURL string     `json:"thumbnail_url"`
	IsLive       bool       `gorm:"default:false" json:"is_live"`
	ViewerCount  int        `gorm:"default:0" json:"viewer_count"`
	ScheduledAt  *time.Time `json:"scheduled_at,omitempty"`
}

// ─── NOTIFICATION ────────────────────────────────────────────────────────────

type Notification struct {
	Base
	UserID uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	Title  string    `json:"title"`
	Body   string    `json:"body"`
	Type   string    `json:"type"` // booking, payment, festival, general
	IsRead bool      `gorm:"default:false" json:"is_read"`
	Data   string    `json:"data"` // JSON extra data
}

// ─── SADHANA ─────────────────────────────────────────────────────────────────

type Mantra struct {
	Base
	Name      string `json:"name"`
	NameHi    string `json:"name_hi"`
	Deity     string `json:"deity"`
	DeityHi   string `json:"deity_hi"`
	Text      string `json:"text"`
	Benefit   string `json:"benefit"`
	BenefitHi string `json:"benefit_hi"`
	Color     string `json:"color"`
	JapaCount int    `gorm:"default:108" json:"japa_count"`
	SortOrder int    `json:"sort_order"`
	IsActive  bool   `gorm:"default:true" json:"is_active"`
}

type SadhanaPractice struct {
	Base
	Key        string `gorm:"uniqueIndex" json:"key"`
	Name       string `json:"name"`
	NameHi     string `json:"name_hi"`
	Icon       string `json:"icon"`
	Duration   string `json:"duration"`
	DurationHi string `json:"duration_hi"`
	SortOrder  int    `json:"sort_order"`
	IsActive   bool   `gorm:"default:true" json:"is_active"`
}

type SadhanaLog struct {
	Base
	UserID      uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	PracticeKey string    `json:"practice_key"`
	Completed   bool      `gorm:"default:false" json:"completed"`
	LogDate     time.Time `json:"log_date"`
}

type Festival struct {
	Base
	Name         string    `json:"name"`
	NameHi       string    `json:"name_hi"`
	Icon         string    `json:"icon"`
	FestivalDate time.Time `json:"festival_date"`
	Description  string    `json:"description"`
}

type Shloka struct {
	Base
	Text          string `json:"text"`
	Translation   string `json:"translation"`
	TranslationHi string `json:"translation_hi"`
	Source        string `json:"source"`
	SourceHi      string `json:"source_hi"`
	IsActive      bool   `gorm:"default:true" json:"is_active"`
}