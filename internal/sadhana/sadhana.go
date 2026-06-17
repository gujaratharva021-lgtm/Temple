package sadhana

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"strings"
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

	sadhana := r.Group("/sadhana")
	{
		sadhana.GET("/mantras", h.GetMantras)
		sadhana.GET("/practices", h.GetPractices)
		sadhana.GET("/festivals", h.GetFestivals)
		sadhana.GET("/shloka/today", h.GetTodayShloka)
		sadhana.POST("/log", h.LogPractice)
		sadhana.GET("/log/today", h.GetTodayLog)
	}
}

// GET /sadhana/mantras
func (h *Handler) GetMantras(c *gin.Context) {
	var mantras []models.Mantra
	if err := h.db.Where("is_active = ?", true).Order("sort_order asc").Find(&mantras).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch mantras"})
		return
	}

	if len(mantras) == 0 {
		mantras = seedMantras()
		h.db.Create(&mantras)
	}

	c.JSON(http.StatusOK, gin.H{"data": mantras})
}

// GET /sadhana/practices
func (h *Handler) GetPractices(c *gin.Context) {
	var practices []models.SadhanaPractice
	if err := h.db.Where("is_active = ?", true).Order("sort_order asc").Find(&practices).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch practices"})
		return
	}

	if len(practices) == 0 {
		practices = seedPractices()
		h.db.Create(&practices)
	}

	c.JSON(http.StatusOK, gin.H{"data": practices})
}

// GET /sadhana/festivals
func (h *Handler) GetFestivals(c *gin.Context) {
	var festivals []models.Festival
	now := time.Now()

	if err := h.db.Where("festival_date >= ? AND festival_date <= ?",
		now, now.AddDate(0, 0, 60)).
		Order("festival_date asc").Find(&festivals).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch festivals"})
		return
	}

	if len(festivals) == 0 {
		if h.cfg.AstrologyAPIKey != "" {
			festivals = fetchFestivalsFromAPI(h.cfg)
		}
		if len(festivals) == 0 {
			festivals = seedFestivals()
		}
		h.db.Create(&festivals)
	}

	c.JSON(http.StatusOK, gin.H{"data": festivals})
}

// GET /sadhana/shloka/today
func (h *Handler) GetTodayShloka(c *gin.Context) {
	var shlokas []models.Shloka
	h.db.Where("is_active = ?", true).Find(&shlokas)

	if len(shlokas) == 0 {
		shlokas = seedShlokas()
		h.db.Create(&shlokas)
	}

	dayOfYear := time.Now().YearDay()
	shloka := shlokas[dayOfYear%len(shlokas)]

	c.JSON(http.StatusOK, gin.H{"data": shloka})
}

// POST /sadhana/log
func (h *Handler) LogPractice(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		userIDRaw = "00000000-0000-0000-0000-000000000001"
	}

	type LogRequest struct {
		PracticeKey string `json:"practice_key" binding:"required"`
		Completed   bool   `json:"completed"`
	}

	var req LogRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	uid, _ := uuid.Parse(userIDRaw.(string))
	today := time.Now().Truncate(24 * time.Hour)

	var log models.SadhanaLog
	result := h.db.Where("user_id = ? AND practice_key = ? AND log_date = ?",
		uid, req.PracticeKey, today).First(&log)

	if result.Error == gorm.ErrRecordNotFound {
		log = models.SadhanaLog{
			UserID:      uid,
			PracticeKey: req.PracticeKey,
			Completed:   req.Completed,
			LogDate:     today,
		}
		h.db.Create(&log)
	} else {
		h.db.Model(&log).Update("completed", req.Completed)
	}

	c.JSON(http.StatusOK, gin.H{"data": log, "message": "Practice logged"})
}

// GET /sadhana/log/today
func (h *Handler) GetTodayLog(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		userIDRaw = "00000000-0000-0000-0000-000000000001"
	}

	uid, _ := uuid.Parse(userIDRaw.(string))
	today := time.Now().Truncate(24 * time.Hour)

	var logs []models.SadhanaLog
	h.db.Where("user_id = ? AND log_date = ?", uid, today).Find(&logs)

	logMap := map[string]bool{}
	for _, l := range logs {
		logMap[l.PracticeKey] = l.Completed
	}

	c.JSON(http.StatusOK, gin.H{"data": logMap})
}

// ─── SEED DATA ────────────────────────────────────────────────────────────────

func seedMantras() []models.Mantra {
	return []models.Mantra{
		{Name: "Gayatri Mantra", NameHi: "गायत्री मंत्र", Deity: "Surya", DeityHi: "सूर्य",
			Text:    "ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं\nभर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्",
			Benefit: "Wisdom & clarity", BenefitHi: "ज्ञान और प्रकाश",
			Color: "#FF8C00", JapaCount: 108, SortOrder: 1, IsActive: true},
		{Name: "Om Namah Shivaya", NameHi: "ॐ नमः शिवाय", Deity: "Shiva", DeityHi: "शिव",
			Text:    "ॐ नमः शिवाय",
			Benefit: "Peace & liberation", BenefitHi: "शांति और मोक्ष",
			Color: "#5C6BC0", JapaCount: 108, SortOrder: 2, IsActive: true},
		{Name: "Om Namo Narayanaya", NameHi: "ॐ नमो नारायणाय", Deity: "Vishnu", DeityHi: "विष्णु",
			Text:    "ॐ नमो भगवते वासुदेवाय",
			Benefit: "Protection & grace", BenefitHi: "रक्षा और कृपा",
			Color: "#2E7D32", JapaCount: 108, SortOrder: 3, IsActive: true},
		{Name: "Mahamrityunjaya", NameHi: "महामृत्युंजय मंत्र", Deity: "Shiva", DeityHi: "शिव",
			Text:    "ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्\nउर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय माऽमृतात्",
			Benefit: "Health & longevity", BenefitHi: "स्वास्थ्य और दीर्घायु",
			Color: "#B71C1C", JapaCount: 108, SortOrder: 4, IsActive: true},
		{Name: "Ganesh Mantra", NameHi: "गणेश मंत्र", Deity: "Ganesha", DeityHi: "गणेश",
			Text:    "ॐ गं गणपतये नमः",
			Benefit: "Remove obstacles", BenefitHi: "विघ्न नाश",
			Color: "#E65100", JapaCount: 108, SortOrder: 5, IsActive: true},
		{Name: "Lakshmi Mantra", NameHi: "लक्ष्मी मंत्र", Deity: "Lakshmi", DeityHi: "लक्ष्मी",
			Text:    "ॐ श्रीं महालक्ष्म्यै नमः",
			Benefit: "Wealth & prosperity", BenefitHi: "धन और समृद्धि",
			Color: "#F9A825", JapaCount: 108, SortOrder: 6, IsActive: true},
	}
}

func seedPractices() []models.SadhanaPractice {
	return []models.SadhanaPractice{
		{Key: "morning_meditation", Name: "Morning Meditation", NameHi: "प्रातः ध्यान",
			Icon: "🧘", Duration: "15 min", DurationHi: "15 मिनट", SortOrder: 1, IsActive: true},
		{Key: "surya_namaskar", Name: "Surya Namaskar", NameHi: "सूर्य नमस्कार",
			Icon: "🌅", Duration: "12 rounds", DurationHi: "12 आवर्तन", SortOrder: 2, IsActive: true},
		{Key: "japa_mala", Name: "Japa Mala", NameHi: "जप माला",
			Icon: "📿", Duration: "108 counts", DurationHi: "108 जप", SortOrder: 3, IsActive: true},
		{Key: "evening_aarti", Name: "Evening Aarti", NameHi: "संध्या आरती",
			Icon: "🪔", Duration: "10 min", DurationHi: "10 मिनट", SortOrder: 4, IsActive: true},
		{Key: "gita_reading", Name: "Gita Reading", NameHi: "गीता पाठ",
			Icon: "📖", Duration: "1 chapter", DurationHi: "1 अध्याय", SortOrder: 5, IsActive: true},
		{Key: "water_offering", Name: "Water Offering", NameHi: "जल अर्पण",
			Icon: "💧", Duration: "Daily", DurationHi: "प्रतिदिन", SortOrder: 6, IsActive: true},
	}
}

func seedFestivals() []models.Festival {
	now := time.Now()
	year := now.Year()
	return []models.Festival{
		{Name: "Ekadashi", NameHi: "एकादशी", Icon: "🌙",
			FestivalDate: time.Date(year, 6, 17, 0, 0, 0, 0, time.UTC)},
		{Name: "Pradosh Vrat", NameHi: "प्रदोष व्रत", Icon: "🕉️",
			FestivalDate: time.Date(year, 6, 19, 0, 0, 0, 0, time.UTC)},
		{Name: "Purnima", NameHi: "पूर्णिमा", Icon: "🌕",
			FestivalDate: time.Date(year, 6, 22, 0, 0, 0, 0, time.UTC)},
		{Name: "Ashadha Begin", NameHi: "आषाढ़ प्रारंभ", Icon: "📅",
			FestivalDate: time.Date(year, 7, 1, 0, 0, 0, 0, time.UTC)},
		{Name: "Guru Purnima", NameHi: "गुरु पूर्णिमा", Icon: "🙏",
			FestivalDate: time.Date(year, 7, 10, 0, 0, 0, 0, time.UTC)},
		{Name: "Nag Panchami", NameHi: "नाग पंचमी", Icon: "🐍",
			FestivalDate: time.Date(year, 8, 1, 0, 0, 0, 0, time.UTC)},
		{Name: "Raksha Bandhan", NameHi: "रक्षा बंधन", Icon: "🎗️",
			FestivalDate: time.Date(year, 8, 9, 0, 0, 0, 0, time.UTC)},
		{Name: "Janmashtami", NameHi: "जन्माष्टमी", Icon: "🦚",
			FestivalDate: time.Date(year, 8, 16, 0, 0, 0, 0, time.UTC)},
		{Name: "Ganesh Chaturthi", NameHi: "गणेश चतुर्थी", Icon: "🐘",
			FestivalDate: time.Date(year, 8, 27, 0, 0, 0, 0, time.UTC)},
		{Name: "Navratri", NameHi: "नवरात्रि", Icon: "🌺",
			FestivalDate: time.Date(year, 10, 2, 0, 0, 0, 0, time.UTC)},
		{Name: "Dussehra", NameHi: "दशहरा", Icon: "🏹",
			FestivalDate: time.Date(year, 10, 12, 0, 0, 0, 0, time.UTC)},
		{Name: "Diwali", NameHi: "दीपावली", Icon: "🪔",
			FestivalDate: time.Date(year, 10, 20, 0, 0, 0, 0, time.UTC)},
	}
}

func seedShlokas() []models.Shloka {
	return []models.Shloka{
		{
			Text:          "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि॥",
			Translation:   "You have the right to perform your duties, but not to the fruits of your actions.",
			TranslationHi: "कर्म करने का अधिकार तेरा है, फल पर नहीं।",
			Source:        "Bhagavad Gita 2.47", SourceHi: "श्रीमद्भगवद्गीता २.४७", IsActive: true,
		},
		{
			Text:          "यदा यदा हि धर्मस्य ग्लानिर्भवति भारत।\nअभ्युत्थानमधर्मस्य तदात्मानं सृजाम्यहम्॥",
			Translation:   "Whenever righteousness declines, I manifest myself.",
			TranslationHi: "जब-जब धर्म की हानि होती है, मैं प्रकट होता हूं।",
			Source:        "Bhagavad Gita 4.7", SourceHi: "श्रीमद्भगवद्गीता ४.७", IsActive: true,
		},
		{
			Text:          "सर्वे भवन्तु सुखिनः सर्वे सन्तु निरामयाः।\nसर्वे भद्राणि पश्यन्तु मा कश्चिद्दुःखभाग्भवेत्॥",
			Translation:   "May all be happy, may all be free from illness.",
			TranslationHi: "सभी सुखी हों, सभी रोगमुक्त हों।",
			Source:        "Brihadaranyaka Upanishad", SourceHi: "बृहदारण्यक उपनिषद", IsActive: true,
		},
		{
			Text:          "असतो मा सद्गमय। तमसो मा ज्योतिर्गमय।\nमृत्योर्माऽमृतं गमय॥",
			Translation:   "Lead me from falsehood to truth, from darkness to light.",
			TranslationHi: "असत्य से सत्य की ओर, अंधकार से प्रकाश की ओर ले चलो।",
			Source:        "Brihadaranyaka Upanishad 1.3.28", SourceHi: "बृहदारण्यक उपनिषद १.३.२८", IsActive: true,
		},
		{
			Text:          "तेजस्विनावधीतमस्तु मा विद्विषावहै॥",
			Translation:   "May our study be brilliant and may we not hate each other.",
			TranslationHi: "हमारा अध्ययन तेजस्वी हो, हम एक-दूसरे से द्वेष न करें।",
			Source:        "Taittiriya Upanishad", SourceHi: "तैत्तिरीय उपनिषद", IsActive: true,
		},
	}
}

// ─── PANCHANG FESTIVAL API ──────────────────────────────────────────────────

func fetchPanchangFestivals(cfg *config.Config, date time.Time) []string {
	reqBody := map[string]interface{}{
		"day":   date.Day(),
		"month": int(date.Month()),
		"year":  date.Year(),
		"hour":  6,
		"min":   0,
		"lat":   28.6139,
		"lon":   77.2090,
		"tzone": 5.5,
	}
	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return nil
	}

	req, err := http.NewRequest("POST", "https://json.astrologyapi.com/v1/panchang_festival", bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil
	}
	req.SetBasicAuth(cfg.AstrologyUserID, cfg.AstrologyAPIKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept-Language", "en")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		log.Println("PANCHANG API ERROR (request failed):", err)
		return nil
	}
	defer resp.Body.Close()

	bodyBytes := new(bytes.Buffer)
	bodyBytes.ReadFrom(resp.Body)
	log.Println("PANCHANG API STATUS:", resp.StatusCode)
	log.Println("PANCHANG API RESPONSE:", bodyBytes.String())

	if resp.StatusCode != http.StatusOK {
		return nil
	}

	var result struct {
		Status    bool     `json:"status"`
		Festivals []string `json:"festivals"`
	}
	if err := json.NewDecoder(bytes.NewReader(bodyBytes.Bytes())).Decode(&result); err != nil {
		log.Println("PANCHANG API DECODE ERROR:", err)
		return nil
	}

	if !result.Status {
		return nil
	}

	var festivals []string
	for _, f := range result.Festivals {
		for _, part := range strings.Split(f, ",") {
			part = strings.TrimSpace(part)
			if part != "" {
				festivals = append(festivals, part)
			}
		}
	}
	return festivals
}

func fetchFestivalsFromAPI(cfg *config.Config) []models.Festival {
	var festivals []models.Festival
	now := time.Now()

	for i := 0; i < 60; i++ {
		date := now.AddDate(0, 0, i)
		names := fetchPanchangFestivals(cfg, date)

		for _, name := range names {
			festivals = append(festivals, models.Festival{
				Name:         name,
				NameHi:       name,
				Icon:         "🕉️",
				FestivalDate: time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC),
			})
		}
	}

	return festivals
}