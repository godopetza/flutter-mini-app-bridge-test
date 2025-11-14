# Mini App Bridge Test Project

A complete mini app ecosystem test environment for learning and testing JavaScript bridge patterns used in super apps (WeChat, Alipay style). This project demonstrates bidirectional communication between a host application and embedded mini apps.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Complete Test Environment                        │
├─────────────────────────────────────────────────────────────────────┤
│  🌐 Browser                                                         │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ 🏦 Host App (Bank App Simulation)                             │  │
│  │ ┌─────────────────────────────────────────────────────────┐   │  │
│  │ │ 📱 Flutter Mini App (Bus Booking)                      │   │  │
│  │ │ ┌─────────────────────────────────────────────────┐     │   │  │
│  │ │ │ 🔗 JavaScript Bridge                           │     │   │  │
│  │ │ │ • User Info Exchange                            │     │   │  │
│  │ │ │ • Payment Initiation                            │     │   │  │
│  │ │ │ • Result Handling                               │     │   │  │
│  │ │ └─────────────────────────────────────────────────┘     │   │  │
│  │ └─────────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                               │                                     │
│                               │ HTTP API                            │
│                               ▼                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ 🚀 Go Backend API Server                                     │  │
│  │ • Bus routes management                                       │  │
│  │ • Booking creation & confirmation                             │  │
│  │ • Payment processing                                          │  │
│  │ • In-memory storage                                           │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## 🎯 Learning Objectives

- **Bridge Pattern Implementation**: Understand how super apps communicate with mini apps
- **Message Passing**: Learn bidirectional postMessage communication
- **State Management**: Handle user state and payment flows across app boundaries
- **Error Handling**: Implement timeout and error handling for bridge operations
- **Testing Strategies**: Test with both mock and real bridge implementations

## 📦 Tech Stack

- **Backend**: Go 1.21+ with Gin framework
- **Mini App**: Flutter Web with custom bridge services
- **Host App**: Node.js Express server with JavaScript bridge
- **Communication**: PostMessage API, HTTP REST APIs

## 🚀 Quick Start

### Prerequisites

- **Go**: Version 1.21 or higher
- **Flutter**: Version 3.9.2 or higher with web support
- **Node.js**: Version 18 or higher
- **Web Browser**: Chrome, Firefox, Safari, or Edge

### Development Setup

1. **Clone and Setup**
   ```bash
   git clone <your-repo>
   cd mini-app-bridge-test
   ```

2. **Start Backend API** (Terminal 1)
   ```bash
   cd backend
   go run cmd/server/main.go
   ```

3. **Start Flutter Mini App** (Terminal 2)
   ```bash
   cd mini_app
   flutter run -d chrome --web-port 8081
   ```

4. **Start Host App** (Terminal 3)
   ```bash
   cd host-app
   npm install
   npm start
   ```

5. **Open Browser**
   ```
   http://localhost:3000
   ```

## 🧪 Testing Workflows

### Phase 1: Backend Only Testing
Test the API endpoints independently:
```bash
cd backend
go run cmd/server/main.go

# Test routes
curl http://localhost:8080/api/routes

# Test booking creation (requires auth token)
curl -H "Authorization: Bearer test-token" \
     -H "Content-Type: application/json" \
     -d '{"route_id":"DSM-MWZ-001","departure_date":"2025-11-20","seat_numbers":["A1"],"user_id":"test-user","passenger_details":[{"name":"Test User","phone":"+255712345678"}]}' \
     http://localhost:8080/api/bookings
```

### Phase 2: Flutter with Mock Bridge
Test the mini app without host dependency:
```bash
cd mini_app
flutter run -d chrome --web-port 8081
```

The app automatically uses `MockBridge` in debug mode:
- Provides fake user data immediately
- Simulates 3-second payment delay
- Always returns successful payment results

### Phase 3: Full Integration Testing
Test complete bridge communication:
```bash
# Ensure all three components are running:
# 1. Backend (port 8080)
# 2. Flutter (port 8081)
# 3. Host app (port 3000)

# Open browser to: http://localhost:3000
```

Expected flow:
1. Host app loads with bank branding
2. Flutter mini app loads in iframe
3. Bridge initializes and exchanges user info
4. User can book bus tickets
5. Payment flows through bridge to host
6. Booking confirmation completes

## 📁 Project Structure

```
mini-app-bridge-test/
├── README.md                    # This file
├── backend/                     # Go API server
│   ├── cmd/server/main.go       # Server entry point
│   ├── internal/
│   │   ├── handlers/            # HTTP request handlers
│   │   │   ├── routes.go        # Routes endpoints
│   │   │   ├── bookings.go      # Booking endpoints
│   │   │   └── webhooks.go      # Webhook endpoints
│   │   ├── models/              # Data structures
│   │   │   ├── bus_route.go     # Bus route model
│   │   │   └── booking.go       # Booking model
│   │   ├── services/            # Business logic
│   │   │   └── booking_service.go # Booking service
│   │   └── middleware/          # HTTP middleware
│   │       ├── cors.go          # CORS configuration
│   │       └── auth.go          # Authentication
│   ├── go.mod                   # Go dependencies
│   └── README.md                # Backend documentation
│
├── mini_app/                    # Flutter web application
│   ├── lib/
│   │   ├── main.dart            # Flutter app entry
│   │   ├── services/            # Bridge services
│   │   │   ├── bank_bridge.dart # Real bridge implementation
│   │   │   ├── mock_bridge.dart # Testing bridge
│   │   │   └── api_service.dart # Backend API client
│   │   ├── models/              # Data models
│   │   │   ├── bank_user.dart   # User model
│   │   │   ├── bus_route.dart   # Route model
│   │   │   ├── booking.dart     # Booking model
│   │   │   └── payment_result.dart # Payment result
│   │   └── pages/               # UI pages
│   │       ├── home_page.dart   # Routes listing
│   │       ├── booking_page.dart # Seat selection
│   │       ├── checkout_page.dart # Payment processing
│   │       └── success_page.dart # Confirmation
│   ├── web/                     # Web configuration
│   ├── pubspec.yaml            # Flutter dependencies
│   └── README.md               # Mini app documentation
│
├── host-app/                   # Mock banking app
│   ├── server.js               # Express server
│   ├── public/index.html       # WebView page with bridge
│   ├── package.json            # Node.js dependencies
│   └── README.md               # Host app documentation
```

## 🔗 API Endpoints

### Public Endpoints
- `GET /api/routes` - List available bus routes
- `GET /health` - Backend health check
- `POST /webhooks/payment` - Payment webhook (simulated)

### Protected Endpoints (Require Authorization header)
- `POST /api/bookings` - Create new booking
- `GET /api/bookings/:id` - Get booking details
- `POST /api/bookings/:id/confirm` - Confirm payment

## 🌉 Bridge Communication Flow

### 1. Initialization
```javascript
// Host → Mini App
window.addEventListener('message', (event) => {
  if (event.data.type === 'READY') {
    // Mini app is ready, send user info
  }
});
```

### 2. User Info Exchange
```javascript
// Host → Mini App: User information
{
  type: 'USER_INFO',
  data: {
    userId: 'test-user-123',
    name: 'Ben Minja',
    email: 'ben.test@email.com',
    phone: '+255712345678',
    token: 'mock-token-abc123',
    accountNumber: '1234567890'
  }
}
```

### 3. Payment Flow
```javascript
// Mini App → Host: Payment request
{
  type: 'INITIATE_PAYMENT',
  data: {
    amount: 90000,
    currency: 'TZS',
    reference: 'REF-1731513600000',
    description: 'Bus ticket: Dar es Salaam to Mwanza'
  }
}

// Host → Mini App: Payment result
{
  type: 'PAYMENT_RESULT',
  data: {
    success: true,
    transactionId: 'TXN-1731513905123',
    timestamp: '2025-11-13T10:05:00Z'
  }
}
```

## ⚠️ Production Considerations

This is a **test environment**. For production use:

- ✅ Implement real authentication & authorization
- ✅ Use proper database instead of in-memory storage
- ✅ Add comprehensive error handling & logging
- ✅ Implement real payment gateway integration
- ✅ Add rate limiting and security headers
- ✅ Validate message origins in bridge communication
- ✅ Add comprehensive testing (unit, integration, e2e)
- ✅ Implement proper CI/CD pipelines
- ✅ Add monitoring and analytics

## 🐛 Troubleshooting

### Common Issues

1. **Flutter app not loading in iframe**
   - Ensure Flutter is running on port 8081
   - Check browser console for CORS errors
   - Verify iframe src URL in host-app/public/index.html

2. **Bridge communication failing**
   - Check browser console for postMessage errors
   - Ensure `window.BankApp` is available before bridge init
   - Verify message event listeners are properly set up

3. **API calls failing**
   - Confirm backend is running on port 8080
   - Check CORS configuration in middleware
   - Verify Authorization header format

4. **Payment flow not working**
   - Check bridge logs in host app UI
   - Verify payment data structure matches expected format
   - Ensure timeout values are appropriate

### Debug Mode

The mini app automatically uses mock bridge in debug mode:
```dart
_bridge = kDebugMode ? MockBridge() : BankBridge();
```

To force real bridge testing, temporarily disable:
```dart
_bridge = BankBridge(); // Always use real bridge
```

## 📖 Additional Documentation

- [Backend API Documentation](backend/README.md)
- [Flutter Mini App Guide](mini_app/README.md)
- [Host App Bridge Guide](host-app/README.md)

## 🤝 Contributing

This is a learning project. Feel free to:
- Add new mini app features
- Enhance bridge communication patterns
- Implement additional payment methods
- Add new API endpoints
- Improve error handling

#Setup Commands

  Terminal 1: Backend API Server

  cd /Users/godopetza/development/mini-app-bridge-test/backend
  go run cmd/server/main.go

  Terminal 2: Host App (Node.js)

  cd /Users/godopetza/development/mini-app-bridge-test/host-app
  npm install  # if not already done
  npm start

  Terminal 3: Flutter Mini App

  cd /Users/godopetza/development/mini-app-bridge-test/mini_app
  flutter run -d web-server --web-port=8081

## 📄 License

MIT License - feel free to use this for learning and experimentation.