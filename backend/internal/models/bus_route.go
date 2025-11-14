package models

type BusRoute struct {
	ID            string `json:"id"`
	Origin        string `json:"origin"`
	Destination   string `json:"destination"`
	Price         int    `json:"price"`
	Currency      string `json:"currency"`
	DurationHours int    `json:"duration_hours"`
}