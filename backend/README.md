# Backend API Server

Go-based REST API server for the Mini App Bridge Test project. Provides bus booking functionality with in-memory storage and CORS support for web clients.

## 🚀 Features

- **Bus Routes Management**: CRUD operations for bus routes
- **Booking System**: Create, retrieve, and manage bookings
- **Payment Processing**: Confirm payments and handle webhooks
- **Authentication**: Bearer token validation middleware
- **CORS Support**: Configured for localhost development
- **Structured Logging**: Request/response logging with Gin

## 🏗️ Architecture

```
Backend Structure:
├── cmd/server/main.go          # Server entry point & route setup
├── internal/
│   ├── handlers/               # HTTP request handlers
│   │   ├── routes.go           # Bus routes endpoints
│   │   ├── bookings.go         # Booking management
│   │   └── webhooks.go         # Payment webhooks
│   ├── models/                 # Data structures
│   │   ├── bus_route.go        # Route model
│   │   └── booking.go          # Booking & request models
│   ├── services/               # Business logic layer
│   │   └── booking_service.go  # Core booking operations
│   └── middleware/             # HTTP middleware
│       ├── cors.go             # CORS configuration
│       └── auth.go             # Bearer token validation
├── go.mod                      # Go module definition
└── go.sum                      # Dependency checksums
```

## 📋 Prerequisites

- **Go**: Version 1.21 or higher
- **Dependencies**: Gin framework, Gin CORS middleware

## 🔧 Installation & Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   go mod download
   ```

3. **Run the server**
   ```bash
   go run cmd/server/main.go
   ```

The server will start on `http://localhost:8080`

## 📡 API Endpoints

### Health Check
```http
GET /health
```
Response:
```json
{
  "status": "healthy",
  "service": "mini-app-bridge-test backend"
}
```

### Bus Routes

#### Get All Routes
```http
GET /api/routes
```

Response:
```json
[
  {
    "id": "DSM-MWZ-001",
    "origin": "Dar es Salaam",
    "destination": "Mwanza",
    "price": 45000,
    "currency": "TZS",
    "duration_hours": 22
  },
  {
    "id": "DSM-ARU-001",
    "origin": "Dar es Salaam",
    "destination": "Arusha",
    "price": 35000,
    "currency": "TZS",
    "duration_hours": 10
  }
]
```

### Bookings (Protected Endpoints)

All booking endpoints require `Authorization: Bearer <token>` header.

#### Create Booking
```http
POST /api/bookings
Authorization: Bearer <token>
Content-Type: application/json
```

Request:
```json
{
  "route_id": "DSM-MWZ-001",
  "departure_date": "2025-11-20",
  "seat_numbers": ["A12", "A13"],
  "user_id": "user-123",
  "passenger_details": [
    {
      "name": "Ben Minja",
      "phone": "+255712345678"
    }
  ]
}
```

Response:
```json
{
  "booking_id": "BK-1731513600000",
  "route_id": "DSM-MWZ-001",
  "departure_date": "2025-11-20",
  "seat_numbers": ["A12", "A13"],
  "user_id": "user-123",
  "passenger_details": [
    {
      "name": "Ben Minja",
      "phone": "+255712345678"
    }
  ],
  "amount": 90000,
  "currency": "TZS",
  "payment_reference": "REF-1731513600000",
  "status": "pending_payment",
  "created_at": "2025-11-13T10:00:00Z"
}
```

#### Get Booking
```http
GET /api/bookings/:id
Authorization: Bearer <token>
```

Response: Full booking details (same structure as create response)

#### Confirm Payment
```http
POST /api/bookings/:id/confirm
Authorization: Bearer <token>
Content-Type: application/json
```

Request:
```json
{
  "transaction_id": "BANK-TXN-456",
  "payment_method": "bank_account",
  "amount": 90000
}
```

Response:
```json
{
  "booking_id": "BK-1731513600000",
  "status": "confirmed",
  "ticket_number": "TKT-789ABC",
  "qr_code": "data:image/png;base64,...",
  "transaction_id": "BANK-TXN-456",
  "payment_method": "bank_account",
  ...
}
```

### Webhooks

#### Payment Webhook
```http
POST /webhooks/payment
Content-Type: application/json
```

Request:
```json
{
  "transaction_id": "BANK-TXN-456",
  "booking_reference": "REF-1731513600000",
  "status": "success",
  "amount": 90000,
  "timestamp": "2025-11-13T10:05:00Z"
}
```

Response:
```json
{
  "message": "payment webhook processed successfully"
}
```

## 🧪 Testing with curl

### Test Routes Endpoint
```bash
curl -X GET http://localhost:8080/api/routes
```

### Test Booking Creation
```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Authorization: Bearer test-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "route_id": "DSM-MWZ-001",
    "departure_date": "2025-11-20",
    "seat_numbers": ["A12"],
    "user_id": "test-user",
    "passenger_details": [
      {
        "name": "Test User",
        "phone": "+255712345678"
      }
    ]
  }'
```

### Test Payment Confirmation
```bash
# First create a booking to get booking_id, then:
curl -X POST http://localhost:8080/api/bookings/BK-1731513600000/confirm \
  -H "Authorization: Bearer test-token-123" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TEST-TXN-123",
    "payment_method": "bank_account",
    "amount": 45000
  }'
```

### Test Webhook
```bash
curl -X POST http://localhost:8080/webhooks/payment \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "WEBHOOK-TXN-456",
    "booking_reference": "REF-1731513600000",
    "status": "success",
    "amount": 45000,
    "timestamp": "2025-11-13T10:05:00Z"
  }'
```

## ⚙️ Configuration

### CORS Settings
The server accepts requests from:
- `http://localhost:3000` (Host app)
- `http://localhost:8081` (Flutter mini app)
- `http://localhost:8080` (Backend itself)
- `http://127.0.0.1:*` (Alternative localhost)

### Authentication
- Mock validation: Just checks if Authorization header exists
- Format: `Authorization: Bearer <any-token>`
- For production: Implement proper JWT validation

### Data Storage
- **In-Memory**: Uses Go maps with sync.Map for thread safety
- **Persistence**: Data is lost on server restart
- **Production**: Replace with PostgreSQL, MongoDB, etc.

## 🔍 Error Handling

### Standard Error Responses
```json
{
  "error": "Error message description"
}
```

### Common Error Codes
- `400 Bad Request`: Invalid request data or missing fields
- `401 Unauthorized`: Missing or invalid Authorization header
- `404 Not Found`: Booking or route not found
- `500 Internal Server Error`: Server-side errors

## 📊 Sample Data

### Pre-loaded Routes
```json
[
  {
    "id": "DSM-MWZ-001",
    "origin": "Dar es Salaam",
    "destination": "Mwanza",
    "price": 45000,
    "currency": "TZS",
    "duration_hours": 22
  },
  {
    "id": "DSM-ARU-001",
    "origin": "Dar es Salaam",
    "destination": "Arusha",
    "price": 35000,
    "currency": "TZS",
    "duration_hours": 10
  },
  {
    "id": "DSM-MBY-001",
    "origin": "Dar es Salaam",
    "destination": "Mbeya",
    "price": 40000,
    "currency": "TZS",
    "duration_hours": 14
  }
]
```

## 🐛 Troubleshooting

### Server Won't Start
- Check if port 8080 is already in use: `lsof -i :8080`
- Verify Go installation: `go version`
- Check for missing dependencies: `go mod tidy`

### CORS Errors
- Verify origin in CORS middleware configuration
- Check browser developer tools for specific CORS error
- Ensure frontend is running on expected ports

### Authentication Errors
- Verify Authorization header format: `Bearer <token>`
- Check middleware implementation for token validation
- Ensure protected endpoints have auth middleware applied

### Database Errors
- Data is stored in memory and lost on restart
- Check for nil pointer dereferences in booking operations
- Verify thread safety with multiple concurrent requests

## 🚀 Production Deployment

### Environment Variables
```bash
export PORT=8080
export GIN_MODE=release
export CORS_ORIGINS="https://your-domain.com,https://app.your-domain.com"
```

### Docker Support
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -o main cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

### Health Monitoring
The `/health` endpoint provides basic health checks. For production:
- Add database connectivity checks
- Monitor memory usage and goroutine counts
- Implement graceful shutdown handling
- Add structured logging with correlation IDs

## 📈 Performance Considerations

### Current Limitations
- In-memory storage (not suitable for multiple instances)
- No connection pooling (using default HTTP client)
- No rate limiting implemented
- No caching layer

### Optimization Recommendations
- Implement proper database with connection pooling
- Add Redis for caching frequently accessed data
- Implement request rate limiting
- Add database query optimization
- Use structured logging for better observability
- Implement circuit breaker pattern for external dependencies