import 'dart:async';

import 'bank_bridge.dart';
import '../models/bank_user.dart';
import '../models/payment_result.dart';
import '../models/ticket.dart';

class MockBridge extends BankBridge {
  final BankUser _mockUser = BankUser(
    userId: 'mock-user-456',
    name: 'Ben Minja (MOCK DATA)',
    email: 'ben.mock@email.com',
    phone: '+255712345999',
    token: 'mock-token-xyz789',
    accountNumber: '9999888877776666', // Clearly different from host
    dataSource: 'MOCK_BRIDGE',
  );

  @override
  Future<void> initialize() async {
    print('[MockBridge] Initializing mock bridge...');

    await Future.delayed(const Duration(milliseconds: 500));

    currentUser = _mockUser;
    isInitialized = true;

    userStreamController.add(_mockUser);
    print('[MockBridge] Mock bridge initialized with user: ${_mockUser.name}');
  }

  @override
  Future<PaymentResult> initiatePayment({
    required int amount,
    required String currency,
    required String reference,
    String? description,
    String? bookingId,
  }) async {
    if (!isInitialized) {
      throw BridgeException('Bridge not initialized', 'NOT_INITIALIZED');
    }

    if (isPaymentInProgress) {
      throw BridgeException('Payment already in progress', 'PAYMENT_IN_PROGRESS');
    }

    isPaymentInProgress = true;
    print('[MockBridge] Initiating mock payment: $amount $currency');

    await Future.delayed(const Duration(seconds: 3));

    isPaymentInProgress = false;

    final result = PaymentResult.success('MOCK-TXN-${DateTime.now().millisecondsSinceEpoch}');
    paymentStreamController.add(result);

    // Also generate a mock ticket
    final ticket = Ticket(
      bookingId: bookingId ?? 'MOCK-BK-${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: 'MOCK-TK-${DateTime.now().millisecondsSinceEpoch}',
      transactionId: result.transactionId!,
      amount: amount,
      currency: currency,
      origin: 'Dar es Salaam',
      destination: 'Mwanza',
      seatNumbers: ['A1'], // Mock seat
      departureDate: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
      status: 'confirmed',
      qrCode: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      createdAt: DateTime.now().toIso8601String(),
    );
    ticketStreamController.add(ticket);

    print('[MockBridge] Mock payment completed: ${result.transactionId}');
    print('[MockBridge] Mock ticket issued: ${ticket.ticketNumber}');
    return result;
  }

  @override
  void notifyBookingSuccess({
    required String bookingId,
    required String ticketNumber,
    required String transactionId,
    required int amount,
    required String currency,
    String? route,
  }) {
    print('[MockBridge] Mock booking success notification: $bookingId');
    // In mock mode, we just log the notification
    // In real integration, this would send to the host app
  }
}