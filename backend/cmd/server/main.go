package main

import (
	"log"
	"net/http"

	"mini-app-bridge-test/backend/internal/handlers"
	"mini-app-bridge-test/backend/internal/middleware"
	"mini-app-bridge-test/backend/internal/services"

	"github.com/gin-gonic/gin"
)

func main() {
	gin.SetMode(gin.ReleaseMode)

	r := gin.Default()

	r.Use(middleware.CORS())
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	bookingService := services.NewBookingService()

	routeHandler := handlers.NewRouteHandler(bookingService)
	bookingHandler := handlers.NewBookingHandler(bookingService)
	webhookHandler := handlers.NewWebhookHandler(bookingService)

	api := r.Group("/api")
	{
		api.GET("/routes", routeHandler.GetRoutes)

		protected := api.Group("")
		protected.Use(middleware.Auth())
		{
			protected.POST("/bookings", bookingHandler.CreateBooking)
			protected.GET("/bookings/:id", bookingHandler.GetBooking)
			protected.POST("/bookings/:id/confirm", bookingHandler.ConfirmPayment)
		}
	}

	webhooks := r.Group("/webhooks")
	{
		webhooks.POST("/payment", webhookHandler.HandlePaymentWebhook)
	}

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"service": "mini-app-bridge-test backend",
		})
	})

	log.Println("Starting server on :8080...")
	log.Println("API Routes:")
	log.Println("  GET  /api/routes")
	log.Println("  POST /api/bookings (requires Authorization header)")
	log.Println("  GET  /api/bookings/:id (requires Authorization header)")
	log.Println("  POST /api/bookings/:id/confirm (requires Authorization header)")
	log.Println("  POST /webhooks/payment")
	log.Println("  GET  /health")

	if err := r.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}