import 'dart:async';

import 'bank_bridge.dart';
import '../models/bank_user.dart';
import '../models/payment_result.dart';

class MockBridge extends BankBridge {
  final BankUser _mockUser = BankUser(
    userId: 'mock-user-456',
    name: 'Ben Minja (MOCK DATA)',
    email: 'ben.mock@email.com',
    phone: '+255712345999',
    token: 'mock-token-xyz789',
    accountNumber: '9876543210',
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

    print('[MockBridge] Mock payment completed: ${result.transactionId}');
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