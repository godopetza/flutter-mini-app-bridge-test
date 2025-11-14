package services

import (
	"fmt"
	"log"
	"strconv"
	"sync"
	"time"

	"mini-app-bridge-test/backend/internal/models"
)

type BookingService struct {
	bookings sync.Map
	routes   []models.BusRoute
}

func NewBookingService() *BookingService {
	service := &BookingService{}
	service.seedRoutes()
	return service
}

func (s *BookingService) seedRoutes() {
	s.routes = []models.BusRoute{
		{
			ID:            "DSM-MWZ-001",
			Origin:        "Dar es Salaam",
			Destination:   "Mwanza",
			Price:         45000,
			Currency:      "TZS",
			DurationHours: 22,
		},
		{
			ID:            "DSM-ARU-001",
			Origin:        "Dar es Salaam",
			Destination:   "Arusha",
			Price:         35000,
			Currency:      "TZS",
			DurationHours: 10,
		},
		{
			ID:            "DSM-MBY-001",
			Origin:        "Dar es Salaam",
			Destination:   "Mbeya",
			Price:         40000,
			Currency:      "TZS",
			DurationHours: 14,
		},
	}
}

func (s *BookingService) GetRoutes() []models.BusRoute {
	return s.routes
}

func (s *BookingService) findRouteByID(routeID string) *models.BusRoute {
	for _, route := range s.routes {
		if route.ID == routeID {
			return &route
		}
	}
	return nil
}

func (s *BookingService) CreateBooking(req models.CreateBookingRequest) (*models.Booking, error) {
	route := s.findRouteByID(req.RouteID)
	if route == nil {
		return nil, fmt.Errorf("route not found")
	}

	if len(req.SeatNumbers) == 0 {
		return nil, fmt.Errorf("at least one seat must be selected")
	}

	if len(req.PassengerDetails) != len(req.SeatNumbers) {
		return nil, fmt.Errorf("passenger details must match number of seats")
	}

	bookingID := fmt.Sprintf("BK-%d", time.Now().Unix())
	paymentRef := fmt.Sprintf("REF-%d", time.Now().Unix())

	totalAmount := route.Price * len(req.SeatNumbers)

	booking := &models.Booking{
		ID:                bookingID,
		RouteID:           req.RouteID,
		DepartureDate:     req.DepartureDate,
		SeatNumbers:       req.SeatNumbers,
		UserID:            req.UserID,
		PassengerDetails:  req.PassengerDetails,
		Amount:            totalAmount,
		Currency:          route.Currency,
		PaymentReference:  paymentRef,
		Status:            "pending_payment",
		CreatedAt:         time.Now(),
	}

	s.bookings.Store(bookingID, booking)
	return booking, nil
}

func (s *BookingService) GetBooking(bookingID string) (*models.Booking, error) {
	value, exists := s.bookings.Load(bookingID)
	if !exists {
		return nil, fmt.Errorf("booking not found")
	}

	booking, ok := value.(*models.Booking)
	if !ok {
		return nil, fmt.Errorf("invalid booking data")
	}

	return booking, nil
}

func (s *BookingService) ConfirmPayment(bookingID string, req models.ConfirmPaymentRequest) (*models.Booking, error) {
	log.Printf("[BookingService] Confirming payment for booking %s with transaction %s", bookingID, req.TransactionID)

	booking, err := s.GetBooking(bookingID)
	if err != nil {
		log.Printf("[BookingService] Error: booking %s not found: %v", bookingID, err)
		return nil, err
	}

	log.Printf("[BookingService] Current booking status: %s", booking.Status)

	if booking.Status != "pending_payment" {
		log.Printf("[BookingService] Error: booking %s is not in pending payment status, current: %s", bookingID, booking.Status)
		return nil, fmt.Errorf("booking is not in pending payment status, current status: %s", booking.Status)
	}

	if req.Amount != booking.Amount {
		log.Printf("[BookingService] Error: payment amount mismatch for booking %s. Expected: %d, Got: %d", bookingID, booking.Amount, req.Amount)
		return nil, fmt.Errorf("payment amount does not match booking amount. Expected: %d, Got: %d", booking.Amount, req.Amount)
	}

	// Validate transaction ID is not already used
	s.bookings.Range(func(key, value interface{}) bool {
		existingBooking, ok := value.(*models.Booking)
		if ok && existingBooking.TransactionID == req.TransactionID && existingBooking.ID != bookingID {
			log.Printf("[BookingService] Warning: Transaction ID %s already used by booking %s", req.TransactionID, existingBooking.ID)
		}
		return true
	})

	booking.TransactionID = req.TransactionID
	booking.PaymentMethod = req.PaymentMethod
	booking.Status = "confirmed"
	booking.TicketNumber = fmt.Sprintf("TKT-%s", strconv.FormatInt(time.Now().Unix(), 36))
	booking.QRCode = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

	s.bookings.Store(bookingID, booking)

	log.Printf("[BookingService] Successfully confirmed payment for booking %s, issued ticket %s", bookingID, booking.TicketNumber)
	return booking, nil
}

func (s *BookingService) ProcessWebhookPayment(req models.WebhookPaymentRequest) error {
	var targetBooking *models.Booking
	var targetBookingID string

	s.bookings.Range(func(key, value interface{}) bool {
		booking, ok := value.(*models.Booking)
		if ok && booking.PaymentReference == req.BookingReference {
			targetBooking = booking
			targetBookingID = key.(string)
			return false
		}
		return true
	})

	if targetBooking == nil {
		return fmt.Errorf("booking with reference %s not found", req.BookingReference)
	}

	if req.Status == "success" {
		targetBooking.TransactionID = req.TransactionID
		targetBooking.Status = "confirmed"
		targetBooking.TicketNumber = fmt.Sprintf("TKT-%s", strconv.FormatInt(time.Now().Unix(), 36))
		targetBooking.QRCode = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
		s.bookings.Store(targetBookingID, targetBooking)
	} else {
		targetBooking.Status = "failed"
		s.bookings.Store(targetBookingID, targetBooking)
	}

	return nil
}