import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import '../models/bus_route.dart';
import '../models/booking.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message ${statusCode != null ? '(${statusCode})' : ''}';
}

class CreateBookingRequest {
  final String routeId;
  final String departureDate;
  final List<String> seatNumbers;
  final String userId;
  final List<PassengerDetail> passengerDetails;

  CreateBookingRequest({
    required this.routeId,
    required this.departureDate,
    required this.seatNumbers,
    required this.userId,
    required this.passengerDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'departure_date': departureDate,
      'seat_numbers': seatNumbers,
      'user_id': userId,
      'passenger_details': passengerDetails.map((e) => e.toJson()).toList(),
    };
  }
}

class ConfirmPaymentRequest {
  final String transactionId;
  final String paymentMethod;
  final int amount;

  ConfirmPaymentRequest({
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'amount': amount,
    };
  }
}

class ApiService {
  static const String localhostBaseUrl = 'http://localhost:8080';
  static const String productionBaseUrl = 'https://flutter-mini-app-bridge-test-production.up.railway.app';
  static const String defaultBaseUrl = productionBaseUrl;

  final String baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _getBaseUrl();

  // Auto-detect environment and return appropriate API URL
  static String _getBaseUrl() {
    // Check if running in production (GitHub Pages)
    final hostname = html.window.location.hostname!;
    final isGitHubPages = hostname.contains('github.io');
    final isLocalhost = hostname == 'localhost' || hostname == '127.0.0.1';

    if (isGitHubPages) {
      print('[ApiService] 🌍 Production environment detected - using Railway backend');
      return productionBaseUrl;
    } else if (isLocalhost) {
      print('[ApiService] 🏠 Development environment detected - using localhost backend');
      return defaultBaseUrl;
    } else {
      // Fallback for other domains
      print('[ApiService] ❓ Unknown environment ($hostname) - using localhost backend');
      return defaultBaseUrl;
    }
  }

  Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      return fromJson(data);
    } else {
      String errorMessage = 'Request failed with status ${response.statusCode}';

      try {
        final errorData = json.decode(response.body);
        if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
      } catch (e) {
        // Use default error message if JSON parsing fails
      }

      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<List<T>> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => fromJson(item)).toList();
    } else {
      String errorMessage = 'Request failed with status ${response.statusCode}';

      try {
        final errorData = json.decode(response.body);
        if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
      } catch (e) {
        // Use default error message if JSON parsing fails
      }

      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<List<BusRoute>> getRoutes() async {
    try {
      print('[ApiService] Fetching routes...');
      final response = await http.get(
        Uri.parse('$baseUrl/api/routes'),
        headers: _getHeaders(null),
      );

      final routes = await _handleListResponse(response, (json) => BusRoute.fromJson(json));
      print('[ApiService] Fetched ${routes.length} routes');
      return routes;
    } catch (e) {
      print('[ApiService] Error fetching routes: $e');
      rethrow;
    }
  }

  Future<Booking> createBooking(CreateBookingRequest request, String token) async {
    try {
      print('[ApiService] Creating booking for route: ${request.routeId}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: _getHeaders(token),
        body: json.encode(request.toJson()),
      );

      final booking = await _handleResponse(response, (json) => Booking.fromJson(json));
      print('[ApiService] Created booking: ${booking.id}');
      return booking;
    } catch (e) {
      print('[ApiService] Error creating booking: $e');
      rethrow;
    }
  }

  Future<Booking> getBooking(String bookingId, String token) async {
    try {
      print('[ApiService] Fetching booking: $bookingId');
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/$bookingId'),
        headers: _getHeaders(token),
      );

      final booking = await _handleResponse(response, (json) => Booking.fromJson(json));
      print('[ApiService] Fetched booking: ${booking.id} - ${booking.status}');
      return booking;
    } catch (e) {
      print('[ApiService] Error fetching booking: $e');
      rethrow;
    }
  }

  Future<Booking> confirmPayment(String bookingId, ConfirmPaymentRequest request, String token) async {
    try {
      print('[ApiService] Confirming payment for booking: $bookingId');
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings/$bookingId/confirm'),
        headers: _getHeaders(token),
        body: json.encode(request.toJson()),
      );

      final booking = await _handleResponse(response, (json) => Booking.fromJson(json));
      print('[ApiService] Payment confirmed: ${booking.id} - ${booking.status}');
      return booking;
    } catch (e) {
      print('[ApiService] Error confirming payment: $e');
      rethrow;
    }
  }
}