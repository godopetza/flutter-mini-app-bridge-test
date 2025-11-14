import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import '../models/bank_user.dart';
import '../models/payment_result.dart';
import '../models/ticket.dart';

class BridgeException implements Exception {
  final String message;
  final String? code;

  BridgeException(this.message, [this.code]);

  @override
  String toString() => 'BridgeException: $message ${code != null ? '($code)' : ''}';
}

class BankBridge {
  static const Duration _initTimeout = Duration(seconds: 5);
  static const Duration _paymentTimeout = Duration(minutes: 5);

  final StreamController<BankUser?> _userStreamController = StreamController<BankUser?>.broadcast();
  final StreamController<PaymentResult> _paymentStreamController = StreamController<PaymentResult>.broadcast();
  final StreamController<Ticket> _ticketStreamController = StreamController<Ticket>.broadcast();

  Stream<BankUser?> get userStream => _userStreamController.stream;
  Stream<PaymentResult> get paymentStream => _paymentStreamController.stream;
  Stream<Ticket> get ticketStream => _ticketStreamController.stream;

  BankUser? _currentUser;
  bool _isInitialized = false;
  bool _isPaymentInProgress = false;

  // Protected getters for subclasses
  StreamController<BankUser?> get userStreamController => _userStreamController;
  StreamController<PaymentResult> get paymentStreamController => _paymentStreamController;
  StreamController<Ticket> get ticketStreamController => _ticketStreamController;

  // Protected setters for subclasses
  set currentUser(BankUser? user) => _currentUser = user;
  set isInitialized(bool value) => _isInitialized = value;
  set isPaymentInProgress(bool value) => _isPaymentInProgress = value;

  BankUser? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isPaymentInProgress => _isPaymentInProgress;

  Future<void> initialize() async {
    print('[BridgeService] Initializing bridge...');

    if (!_isHostAppAvailable()) {
      throw BridgeException('Not running inside host app', 'HOST_NOT_AVAILABLE');
    }

    try {
      _setupMessageListener();

      // Wait a moment for the host app to be ready, then send READY signal
      await Future.delayed(const Duration(milliseconds: 1500));
      _postMessage({'type': 'READY'});

      await _requestUserInfo();
      _isInitialized = true;

      print('[BridgeService] Bridge initialized successfully');
    } catch (e) {
      throw BridgeException('Failed to initialize bridge: $e', 'INIT_FAILED');
    }
  }

  bool _isHostAppAvailable() {
    try {
      // Check if we're in an iframe (which means we're hosted by the bank app)
      return html.window.parent != html.window;
    } catch (e) {
      print('[BridgeService] Error checking host app: $e');
      return false;
    }
  }

  void _setupMessageListener() {
    html.window.addEventListener('message', (html.Event event) {
      final messageEvent = event as html.MessageEvent;
      _handleMessage(messageEvent.data);
    });
  }

  void _handleMessage(dynamic data) {
    print('[BridgeService] 📨 Received raw message: $data');
    print('[BridgeService] 📋 Message type: ${data.runtimeType}');

    try {
      // Convert to Map<String, dynamic> regardless of the actual type
      Map<String, dynamic> message;

      if (data is Map) {
        // Convert any Map type to Map<String, dynamic>
        message = Map<String, dynamic>.from(data);
        print('[BridgeService] ✅ Converted ${data.runtimeType} to Map<String, dynamic>');
      } else {
        print('[BridgeService] ❌ Data is not a Map type');
        return;
      }

      final type = message['type'];
      print('[BridgeService] 🎯 Processing message type: $type');

      switch (type) {
        case 'USER_INFO':
          print('[BridgeService] 👤 Handling USER_INFO message');
          _handleUserInfo(message['data']);
          break;
        case 'PAYMENT_RESULT':
          print('[BridgeService] 💳 Handling PAYMENT_RESULT message');
          _handlePaymentResult(message['data']);
          break;
        case 'TICKET_ISSUED':
          print('[BridgeService] 🎫 Handling TICKET_ISSUED message');
          _handleTicketIssued(message['data']);
          break;
        default:
          print('[BridgeService] ❓ Unknown message type: $type');
      }
    } catch (e) {
      print('[BridgeService] ❌ Error handling message: $e');
    }
  }

  void _handleUserInfo(dynamic userData) {
    try {
      Map<String, dynamic> userMap;

      if (userData is Map) {
        userMap = Map<String, dynamic>.from(userData);
        print('[BridgeService] 📋 Converted user data from ${userData.runtimeType}');
      } else {
        print('[BridgeService] ❌ User data is not a Map: ${userData.runtimeType}');
        return;
      }

      final user = BankUser.fromJson(userMap);
      _currentUser = user;
      _userStreamController.add(user);
      print('[BridgeService] ✅ User info received: ${user.name} from ${user.dataSource}');
    } catch (e) {
      print('[BridgeService] ❌ Error processing user info: $e');
    }
  }

  void _handlePaymentResult(dynamic paymentData) {
    _isPaymentInProgress = false;

    try {
      Map<String, dynamic> paymentMap;

      if (paymentData is Map) {
        paymentMap = Map<String, dynamic>.from(paymentData);
        print('[BridgeService] 📋 Converted payment data from ${paymentData.runtimeType}');
      } else {
        print('[BridgeService] ❌ Payment data is not a Map: ${paymentData.runtimeType}');
        return;
      }

      final result = PaymentResult.fromJson(paymentMap);
      _paymentStreamController.add(result);
      print('[BridgeService] ✅ Payment result received: ${result.success}');
    } catch (e) {
      print('[BridgeService] ❌ Error processing payment result: $e');
    }
  }

  Future<void> _requestUserInfo() async {
    print('[BridgeService] Requesting user info...');

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = _userStreamController.stream.timeout(_initTimeout).listen(
      (user) {
        if (user != null) {
          subscription.cancel();
          completer.complete();
        }
      },
      onError: (error) {
        subscription.cancel();
        completer.completeError(BridgeException('Timeout requesting user info', 'USER_INFO_TIMEOUT'));
      },
    );

    _postMessage({'type': 'REQUEST_USER_INFO'});

    return completer.future;
  }

  Future<PaymentResult> initiatePayment({
    required int amount,
    required String currency,
    required String reference,
    String? description,
    String? bookingId,
  }) async {
    if (!_isInitialized) {
      throw BridgeException('Bridge not initialized', 'NOT_INITIALIZED');
    }

    if (_isPaymentInProgress) {
      throw BridgeException('Payment already in progress', 'PAYMENT_IN_PROGRESS');
    }

    _isPaymentInProgress = true;
    print('[BridgeService] Initiating payment: $amount $currency');

    final completer = Completer<PaymentResult>();
    late StreamSubscription subscription;

    subscription = _paymentStreamController.stream.timeout(_paymentTimeout).listen(
      (result) {
        subscription.cancel();
        completer.complete(result);
      },
      onError: (error) {
        _isPaymentInProgress = false;
        subscription.cancel();
        completer.completeError(BridgeException('Payment timeout', 'PAYMENT_TIMEOUT'));
      },
    );

    final paymentData = {
      'type': 'INITIATE_PAYMENT',
      'data': {
        'amount': amount,
        'currency': currency,
        'reference': reference,
        'description': description,
        'bookingId': bookingId,
      },
    };

    _postMessage(paymentData);

    return completer.future;
  }

  void notifyBookingSuccess({
    required String bookingId,
    required String ticketNumber,
    required String transactionId,
    required int amount,
    required String currency,
    String? route,
  }) {
    if (!_isInitialized) {
      print('[BridgeService] Cannot notify booking success - bridge not initialized');
      return;
    }

    final successData = {
      'type': 'BOOKING_SUCCESS',
      'data': {
        'bookingId': bookingId,
        'ticketNumber': ticketNumber,
        'transactionId': transactionId,
        'amount': amount,
        'currency': currency,
        'route': route,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    _postMessage(successData);
    print('[BridgeService] Notified host of booking success: $bookingId');
  }

  void _postMessage(Map<String, dynamic> message) {
    try {
      print('[BridgeService] 📤 Attempting to post message: ${message['type']}');
      print('[BridgeService] 🔍 Is in iframe: ${html.window.parent != html.window}');
      print('[BridgeService] 🔍 Parent exists: ${html.window.parent != null}');

      if (html.window.parent != null) {
        html.window.parent!.postMessage(message, '*');
        print('[BridgeService] ✅ Posted message: ${message['type']}');
      } else {
        print('[BridgeService] ❌ No parent window to post to');
      }
    } catch (e) {
      print('[BridgeService] ❌ Error posting message: $e');
    }
  }

  void _handleTicketIssued(dynamic ticketData) {
    try {
      Map<String, dynamic> ticketMap;

      if (ticketData is Map) {
        ticketMap = Map<String, dynamic>.from(ticketData);
        print('[BridgeService] 📋 Converted ticket data from ${ticketData.runtimeType}');
      } else {
        print('[BridgeService] ❌ Ticket data is not a Map: ${ticketData.runtimeType}');
        return;
      }

      final ticket = Ticket.fromJson(ticketMap);
      _ticketStreamController.add(ticket);
      print('[BridgeService] ✅ Ticket received: ${ticket.ticketNumber} for booking ${ticket.bookingId}');
    } catch (e) {
      print('[BridgeService] ❌ Error processing ticket: $e');
    }
  }

  void dispose() {
    _userStreamController.close();
    _paymentStreamController.close();
    _ticketStreamController.close();
  }
}