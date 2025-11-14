import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import '../models/bus_route.dart';
import '../models/booking.dart';
import '../models/bank_user.dart';
import '../models/payment_result.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../services/bank_bridge.dart';
import '../services/mock_bridge.dart';
import 'success_page.dart';
import 'ticket_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const CheckoutPage({super.key, required this.bookingData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final BankBridge _bridge;
  late final ApiService _apiService;

  BankUser? _user;
  bool _isInitializing = true;
  bool _isPaymentInProgress = false;
  String? _errorMessage;
  Booking? _booking;

  @override
  void initState() {
    super.initState();

    // Use iframe detection to determine bridge type - same logic as booking page
    print('[CheckoutPage] 🚀 === CHECKOUT PAGE BRIDGE SELECTION ===');
    print('[CheckoutPage] 🔍 html.window: ${html.window}');
    print('[CheckoutPage] 🔍 html.window.parent: ${html.window.parent}');
    print('[CheckoutPage] 🔍 window == parent: ${html.window == html.window.parent}');

    final isInIframe = html.window.parent != html.window;
    print('[CheckoutPage] 🔍 Environment check:');
    print('[CheckoutPage] 🔍 Is in iframe: $isInIframe');
    print('[CheckoutPage] 🔍 kDebugMode: $kDebugMode');
    print('[CheckoutPage] 🔍 Current URL: ${html.window.location.href}');

    // Force explicit bridge selection
    BankBridge bridgeToUse;
    if (isInIframe) {
      bridgeToUse = BankBridge(); // Real bridge when in iframe (host app)
      print('[CheckoutPage] ✅ SELECTED: BankBridge (real bridge) - running in host app');
    } else {
      bridgeToUse = MockBridge(); // Mock bridge when standalone
      print('[CheckoutPage] ✅ SELECTED: MockBridge - running standalone');
    }

    _bridge = bridgeToUse;
    print('[CheckoutPage] 🎯 Final bridge type: ${_bridge.runtimeType}');
    print('[CheckoutPage] 🔍 Bridge is MockBridge: ${_bridge is MockBridge}');
    print('[CheckoutPage] 🔍 Bridge is BankBridge: ${_bridge is BankBridge}');
    print('[CheckoutPage] 🚀 === END BRIDGE SELECTION ===');

    _apiService = ApiService();

    _initializeBridge();
    _listenToStreams();
  }

  void _listenToStreams() {
    _bridge.userStream.listen(
      (user) {
        if (mounted) {
          setState(() {
            _user = user;
            if (user != null) {
              _isInitializing = false;
              _errorMessage = null;
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = error.toString();
          });
        }
      },
    );

    _bridge.paymentStream.listen(
      (paymentResult) {
        if (mounted) {
          _handlePaymentResult(paymentResult);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isPaymentInProgress = false;
            _errorMessage = error.toString();
          });
        }
      },
    );

    // Listen for tickets from host app
    _bridge.ticketStream.listen(
      (ticket) {
        if (mounted) {
          _handleTicketReceived(ticket);
        }
      },
      onError: (error) {
        print('[CheckoutPage] ❌ Ticket stream error: $error');
      },
    );
  }

  Future<void> _initializeBridge() async {
    try {
      await _bridge.initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Handle tickets received from host app
  void _handleTicketReceived(Ticket ticket) {
    print('[CheckoutPage] 🎫 Ticket received: ${ticket.ticketNumber}');

    setState(() {
      _isPaymentInProgress = false;
    });

    // Navigate to ticket page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketPage(ticket: ticket),
      ),
    );
  }

  Future<void> _handlePaymentResult(PaymentResult result) async {
    setState(() {
      _isPaymentInProgress = false;
    });

    if (result.success && result.transactionId != null && _booking != null) {
      try {
        final confirmRequest = ConfirmPaymentRequest(
          transactionId: result.transactionId!,
          paymentMethod: 'bank_account',
          amount: _booking!.amount,
        );

        final confirmedBooking = await _apiService.confirmPayment(
          _booking!.id,
          confirmRequest,
          _user!.token,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuccessPage(
                booking: confirmedBooking,
                transactionId: result.transactionId!,
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to confirm payment: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = result.error ?? 'Payment failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing payment system...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isInitializing = true;
                  });
                  _initializeBridge();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user information...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfo(),
          const SizedBox(height: 16),
          _buildBookingSummary(),
          const SizedBox(height: 24),
          _buildPaymentButton(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(_user!.name),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, size: 20),
                const SizedBox(width: 8),
                Text(_user!.email),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_balance, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account: ${_user!.accountNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (_user!.dataSource != null)
                        Text(
                          'Source: ${_user!.dataSource}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _user!.dataSource == 'HOST_APP' ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      // Show bridge type for debugging
                      Text(
                        'Bridge: ${_bridge.runtimeType}',
                        style: TextStyle(
                          fontSize: 10,
                          color: _bridge is MockBridge ? Colors.orange : Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    final route = BusRoute.fromJson(widget.bookingData['route']);
    final departureDate = widget.bookingData['departureDate'];
    final seats = List<String>.from(widget.bookingData['selectedSeats']);
    final passengers = (widget.bookingData['passengers'] as List)
        .map((p) => PassengerDetail.fromJson(p))
        .toList();
    final totalAmount = widget.bookingData['totalAmount'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Route', '${route.origin} → ${route.destination}'),
            _buildSummaryRow('Date', departureDate),
            _buildSummaryRow('Seats', seats.join(', ')),
            _buildSummaryRow('Passengers', passengers.length.toString()),
            const Divider(),
            for (int i = 0; i < passengers.length; i++)
              _buildSummaryRow(
                'Passenger ${i + 1}',
                '${passengers[i].name} (${passengers[i].phone})',
              ),
            const Divider(),
            _buildSummaryRow(
              'Total Amount',
              '$totalAmount ${route.currency}',
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPaymentInProgress ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isPaymentInProgress
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Processing Payment...'),
                ],
              )
            : const Text(
                'Pay Now',
                style: TextStyle(fontSize: 18),
              ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (_user == null || _isPaymentInProgress) return;

    setState(() {
      _isPaymentInProgress = true;
      _errorMessage = null;
    });

    try {
      final route = BusRoute.fromJson(widget.bookingData['route']);
      final departureDate = widget.bookingData['departureDate'];
      final seats = List<String>.from(widget.bookingData['selectedSeats']);
      final passengers = (widget.bookingData['passengers'] as List)
          .map((p) => PassengerDetail.fromJson(p))
          .toList();

      final createRequest = CreateBookingRequest(
        routeId: route.id,
        departureDate: departureDate,
        seatNumbers: seats,
        userId: _user!.userId,
        passengerDetails: passengers,
      );

      final booking = await _apiService.createBooking(createRequest, _user!.token);
      _booking = booking;

      print('[CheckoutPage] 📋 Created booking: ${booking.id}');

      await _bridge.initiatePayment(
        amount: booking.amount,
        currency: booking.currency,
        reference: booking.paymentReference,
        description: 'Bus ticket: ${route.origin} to ${route.destination}',
        bookingId: booking.id, // Add booking ID for host app verification
      );
    } catch (e) {
      setState(() {
        _isPaymentInProgress = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }
}