package handlers

import (
	"net/http"

	"mini-app-bridge-test/backend/internal/models"
	"mini-app-bridge-test/backend/internal/services"

	"github.com/gin-gonic/gin"
)

type WebhookHandler struct {
	bookingService *services.BookingService
}

func NewWebhookHandler(bookingService *services.BookingService) *WebhookHandler {
	return &WebhookHandler{
		bookingService: bookingService,
	}
}

func (h *WebhookHandler) HandlePaymentWebhook(c *gin.Context) {
	var req models.WebhookPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.bookingService.ProcessWebhookPayment(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "payment webhook processed successfully"})
}