package handlers

import (
	"net/http"

	"mini-app-bridge-test/backend/internal/services"

	"github.com/gin-gonic/gin"
)

type RouteHandler struct {
	bookingService *services.BookingService
}

func NewRouteHandler(bookingService *services.BookingService) *RouteHandler {
	return &RouteHandler{
		bookingService: bookingService,
	}
}

func (h *RouteHandler) GetRoutes(c *gin.Context) {
	routes := h.bookingService.GetRoutes()
	c.JSON(http.StatusOK, routes)
}