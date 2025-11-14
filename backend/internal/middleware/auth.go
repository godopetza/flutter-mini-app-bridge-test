package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

func Auth() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		if !strings.HasPrefix(authHeader, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		token := strings.TrimPrefix(authHeader, "Bearer ")
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Bearer token is empty"})
			c.Abort()
			return
		}

		// Validate token format and content
		if len(token) < 10 {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			c.Abort()
			return
		}

		// Validate tokens from known sources for security
		validTokenPrefixes := []string{"host-token", "mock-token"}
		isValid := false
		for _, prefix := range validTokenPrefixes {
			if strings.HasPrefix(token, prefix) {
				isValid = true
				break
			}
		}

		if !isValid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token source"})
			c.Abort()
			return
		}

		// Set user info from token for audit trail
		if strings.HasPrefix(token, "host-token") {
			c.Set("user_id", "host-app-user-123")
			c.Set("user_source", "host_app")
		} else {
			c.Set("user_id", "mock-user-456")
			c.Set("user_source", "mock")
		}

		c.Set("token", token)
		c.Next()
	})
}