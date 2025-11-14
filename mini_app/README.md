# Flutter Web Mini App

A Flutter web application demonstrating JavaScript bridge patterns for super app integrations. Features bus ticket booking with real and mock bridge implementations.

## 🎯 Purpose

This mini app demonstrates:
- **Bridge Communication**: PostMessage-based communication with host apps
- **State Management**: Reactive user state and payment flow handling
- **Dual Mode Operation**: Mock bridge for testing, real bridge for integration
- **Error Handling**: Comprehensive timeout and error management
- **Responsive UI**: Material Design 3 with web-optimized layouts

## 🏗️ Architecture

```
Flutter Mini App Structure:
├── lib/
│   ├── main.dart                   # App entry point
│   ├── services/                   # Bridge & API services
│   │   ├── bank_bridge.dart        # Real bridge implementation
│   │   ├── mock_bridge.dart        # Testing bridge (extends real)
│   │   └── api_service.dart        # Backend HTTP client
│   ├── models/                     # Data models
│   │   ├── bank_user.dart          # User information from host
│   │   ├── bus_route.dart          # Bus route details
│   │   ├── booking.dart            # Booking & passenger data
│   │   └── payment_result.dart     # Payment transaction result
│   └── pages/                      # UI screens
│       ├── home_page.dart          # Route listing
│       ├── booking_page.dart       # Seat selection & passenger forms
│       ├── checkout_page.dart      # Payment processing (bridge usage)
│       └── success_page.dart       # Booking confirmation
├── web/                           # Web platform configuration
├── pubspec.yaml                   # Flutter dependencies
└── analysis_options.yaml         # Code analysis rules
```

## 📋 Prerequisites

- **Flutter SDK**: 3.9.2 or higher with web support enabled
- **Web Browser**: Chrome, Firefox, Safari, or Edge
- **Backend API**: Running on localhost:8080 (for API calls)
- **Host App**: Running on localhost:3000 (for bridge integration)

## 🔧 Installation & Setup

1. **Navigate to mini app directory**
   ```bash
   cd mini_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run in different modes**

   **Standalone Mode (Mock Bridge)**
   ```bash
   flutter run -d chrome --web-port 8081
   ```

   **Integration Mode (Real Bridge)**
   ```bash
   # 1. Start backend API
   cd ../backend && go run cmd/server/main.go &

   # 2. Start mini app
   cd ../mini_app && flutter run -d chrome --web-port 8081 &

   # 3. Start host app
   cd ../host-app && npm start

   # 4. Open browser to: http://localhost:3000
   ```

## 🌉 Bridge Architecture

### Automatic Bridge Selection
```dart
// Automatically chooses bridge based on environment
_bridge = kDebugMode ? MockBridge() : BankBridge();
```

### Bridge Communication Flow

#### 1. Initialization
```dart
await _bridge.initialize();
// - Checks for window.BankApp availability
// - Sets up postMessage listeners
// - Requests user info from host
// - Handles timeouts (5 seconds)
```

#### 2. User Info Exchange
```dart
// Listens for user data from host app
_bridge.userStream.listen((user) {
  // Handle user information updates
  setState(() {
    _currentUser = user;
  });
});
```

#### 3. Payment Processing
```dart
// Initiate payment through bridge
final result = await _bridge.initiatePayment(
  amount: booking.amount,
  currency: booking.currency,
  reference: booking.paymentReference,
  description: 'Bus ticket payment'
);

// Handle payment result
if (result.success) {
  // Confirm booking with backend
  await _confirmBooking(result.transactionId);
}
```

## 🔄 Bridge Implementations

### Real Bridge (BankBridge)

**Features:**
- Detects host app via `window.BankApp` check
- Bidirectional postMessage communication
- Timeout handling (5s init, 5min payment)
- Error handling with custom exceptions
- Stream-based reactive updates

**Message Types:**
```dart
// Outgoing to host
READY              // Mini app initialized
REQUEST_USER_INFO  // Request user data
INITIATE_PAYMENT  // Start payment flow

// Incoming from host
USER_INFO         // User data response
PAYMENT_RESULT    // Payment completion
```

### Mock Bridge (MockBridge)

**Features:**
- Extends BankBridge for consistent API
- Provides fake user data immediately
- Simulates 3-second payment delay
- Always returns successful payments
- Perfect for development and testing

**Mock User Data:**
```dart
BankUser(
  userId: 'mock-user-123',
  name: 'Mock Test User',
  email: 'mock.user@test.com',
  phone: '+255712345678',
  token: 'mock-token-abc123',
  accountNumber: '9876543210',
)
```

## 📱 UI Pages

### Home Page
- **Purpose**: Display available bus routes
- **Data Source**: Backend API `/api/routes`
- **Features**: Pull-to-refresh, loading states, error handling
- **Navigation**: Tap route card → Booking Page

### Booking Page
- **Purpose**: Seat selection and passenger information
- **Features**:
  - Date picker (30 days forward)
  - Interactive seat grid (A1-A4, B1-B4, C1-C4)
  - Dynamic passenger forms (match selected seats)
  - Real-time price calculation
  - Form validation
- **Navigation**: Complete form → Checkout Page

### Checkout Page
- **Purpose**: Bridge integration and payment processing
- **Features**:
  - User info display from bridge
  - Booking summary
  - Bridge initialization loading
  - Payment progress indication
  - Error handling and retry logic
- **Bridge Usage**: Primary integration point

### Success Page
- **Purpose**: Booking confirmation display
- **Features**:
  - Success animation
  - Booking details display
  - QR code placeholder
  - Navigation back to home

## 🔌 API Integration

### Backend Communication
```dart
class ApiService {
  static const String defaultBaseUrl = 'http://localhost:8080';

  // Public endpoints
  Future<List<BusRoute>> getRoutes()

  // Protected endpoints (require auth token from bridge)
  Future<Booking> createBooking(CreateBookingRequest, String token)
  Future<Booking> getBooking(String bookingId, String token)
  Future<Booking> confirmPayment(String bookingId, ConfirmPaymentRequest, String token)
}
```

### Authentication Flow
1. Bridge provides user token during initialization
2. Token included in Authorization header for protected endpoints
3. Backend validates token (mock validation in test environment)

## 🎨 UI/UX Features

### Material Design 3
- Consistent theming and color schemes
- Responsive layouts for different screen sizes
- Loading indicators for async operations
- Error states with retry functionality

### Responsive Design
- Mobile-first approach
- Adaptive layouts for desktop/tablet/mobile
- Touch-friendly interaction areas
- Proper keyboard navigation support

### Loading States
```dart
// Page-level loading
if (_isLoading) {
  return Center(child: CircularProgressIndicator());
}

// Button-level loading
ElevatedButton(
  onPressed: _isLoading ? null : _handleAction,
  child: _isLoading
    ? CircularProgressIndicator()
    : Text('Action'),
)
```

## ⚠️ Error Handling

### Bridge Exceptions
```dart
class BridgeException implements Exception {
  final String message;
  final String? code;

  // Common error codes:
  // HOST_NOT_AVAILABLE, INIT_FAILED, USER_INFO_TIMEOUT,
  // NOT_INITIALIZED, PAYMENT_IN_PROGRESS, PAYMENT_TIMEOUT
}
```

### API Exceptions
```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  // HTTP status code-based error handling
}
```

### User-Friendly Error Display
- SnackBar for transient errors
- Full-screen error states for critical failures
- Retry buttons where appropriate
- Clear error messages (avoid technical jargon)

## 🧪 Testing Strategies

### Development Testing (Mock Bridge)
```bash
# Run with mock bridge for rapid development
flutter run -d chrome --web-port 8081

# Features:
# ✅ No host app dependency
# ✅ Immediate user data
# ✅ Predictable payment results
# ✅ Fast iteration cycles
```

### Integration Testing (Real Bridge)
```bash
# Full stack testing with host app
cd ../host-app && npm start &
flutter run -d chrome --web-port 8081 &
# Open: http://localhost:3000

# Features:
# ✅ Real bridge communication
# ✅ Actual postMessage flows
# ✅ Timeout and error testing
# ✅ End-to-end user journeys
```

### Manual Test Cases

#### Bridge Initialization
1. **Success Case**: Host app loads, bridge initializes, user info received
2. **Timeout Case**: Host app not available, 5-second timeout
3. **Invalid Host**: Wrong host environment, initialization failure

#### Payment Flow
1. **Success Case**: Payment initiated, processed, confirmed
2. **Timeout Case**: Payment takes too long, 5-minute timeout
3. **Failure Case**: Payment rejected by host, error handling
4. **Network Failure**: API calls fail, error recovery

#### User Interface
1. **Loading States**: All async operations show loading indicators
2. **Error States**: All error scenarios display appropriate messages
3. **Responsive Design**: Test on different screen sizes
4. **Navigation**: All page transitions work correctly

## 🔧 Configuration

### Environment Variables
```dart
// Default backend URL (can be configured)
static const String defaultBaseUrl = 'http://localhost:8080';

// Bridge selection
final bridge = kDebugMode ? MockBridge() : BankBridge();
```

### Web Configuration
```html
<!-- web/index.html -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<!-- Ensure proper iframe embedding -->
<meta http-equiv="Content-Security-Policy" content="frame-ancestors 'self' http://localhost:3000;">
```

## 📊 Performance Considerations

### Bridge Communication
- Minimal message overhead (structured JSON)
- Event-driven architecture (no polling)
- Timeout management to prevent hanging
- Stream-based reactive updates

### UI Performance
- Efficient state management with setState
- Lazy loading for large lists
- Image optimization for web deployment
- Minimal widget rebuilds

### Network Optimization
- HTTP client reuse
- Request timeout configuration
- Error retry with exponential backoff
- Caching strategies for static data

## 🐛 Troubleshooting

### Bridge Issues

**Bridge Not Initializing**
```dart
// Check browser console for errors
console.log(window.BankApp); // Should exist in host app

// Verify iframe communication
window.addEventListener('message', console.log);
```

**User Info Not Received**
- Verify host app is sending USER_INFO message
- Check message event listener setup
- Confirm window.parent.postMessage is working

**Payment Timeout**
- Check host app payment processing logic
- Verify PAYMENT_RESULT message format
- Confirm transaction ID is included in response

### API Issues

**CORS Errors**
```bash
# Ensure backend CORS allows Flutter origin
Allow-Origin: http://localhost:8081
```

**Authentication Failures**
```dart
// Verify token from bridge is included
headers['Authorization'] = 'Bearer ${user.token}';
```

**Network Failures**
- Check backend is running on port 8080
- Verify API endpoint URLs are correct
- Test with curl to isolate client vs server issues

### Development Issues

**Hot Reload Not Working**
```bash
# Web hot reload can be unreliable, use full restart
flutter run -d chrome --web-port 8081
```

**Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web
```

## 🚀 Production Deployment

### Build for Production
```bash
flutter build web --release
```

### Deployment Considerations
- Configure proper Content Security Policy headers
- Set up HTTPS for secure communication
- Implement proper error tracking (Sentry, Crashlytics)
- Add analytics for user behavior insights
- Optimize bundle size and loading performance

### Security Best Practices
- Validate all messages from host app
- Sanitize user inputs
- Implement proper authentication token handling
- Use HTTPS in production
- Add origin validation for postMessage communication

## 📈 Future Enhancements

### Additional Features
- Multi-language support (internationalization)
- Offline capability with local storage
- Push notifications for booking updates
- QR code generation for tickets
- Trip history and favorites

### Bridge Enhancements
- File upload/download capabilities
- Location services integration
- Camera access for document scanning
- Contact picker for passenger details
- Calendar integration for trip planning

### Performance Improvements
- Progressive Web App (PWA) features
- Service worker for caching
- Image lazy loading and optimization
- Code splitting for faster initial load
- Database integration for offline support