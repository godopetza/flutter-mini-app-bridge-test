package models

import "time"

type PassengerDetail struct {
	Name  string `json:"name"`
	Phone string `json:"phone"`
}

type Booking struct {
	ID                 string             `json:"booking_id"`
	RouteID            string             `json:"route_id"`
	DepartureDate      string             `json:"departure_date"`
	SeatNumbers        []string           `json:"seat_numbers"`
	UserID             string             `json:"user_id"`
	PassengerDetails   []PassengerDetail  `json:"passenger_details"`
	Amount             int                `json:"amount"`
	Currency           string             `json:"currency"`
	PaymentReference   string             `json:"payment_reference"`
	Status             string             `json:"status"`
	TransactionID      string             `json:"transaction_id,omitempty"`
	PaymentMethod      string             `json:"payment_method,omitempty"`
	TicketNumber       string             `json:"ticket_number,omitempty"`
	QRCode             string             `json:"qr_code,omitempty"`
	CreatedAt          time.Time          `json:"created_at"`
}

type CreateBookingRequest struct {
	RouteID            string            `json:"route_id" binding:"required"`
	DepartureDate      string            `json:"departure_date" binding:"required"`
	SeatNumbers        []string          `json:"seat_numbers" binding:"required"`
	UserID             string            `json:"user_id" binding:"required"`
	PassengerDetails   []PassengerDetail `json:"passenger_details" binding:"required"`
}

type ConfirmPaymentRequest struct {
	TransactionID string `json:"transaction_id" binding:"required"`
	PaymentMethod string `json:"payment_method" binding:"required"`
	Amount        int    `json:"amount" binding:"required"`
}

type WebhookPaymentRequest struct {
	TransactionID     string    `json:"transaction_id" binding:"required"`
	BookingReference  string    `json:"booking_reference" binding:"required"`
	Status            string    `json:"status" binding:"required"`
	Amount            int       `json:"amount" binding:"required"`
	Timestamp         time.Time `json:"timestamp" binding:"required"`
}