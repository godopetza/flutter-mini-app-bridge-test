import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/bank_bridge.dart';
import '../services/mock_bridge.dart';

class SuccessPage extends StatefulWidget {
  final Booking booking;
  final String transactionId;

  const SuccessPage({
    super.key,
    required this.booking,
    required this.transactionId,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  late final BankBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = kDebugMode ? MockBridge() : BankBridge();
    _initializeAndNotify();
  }

  Future<void> _initializeAndNotify() async {
    try {
      await _bridge.initialize();

      // Wait a moment for the user to see the success page, then notify the host
      await Future.delayed(const Duration(seconds: 2));

      _bridge.notifyBookingSuccess(
        bookingId: widget.booking.id,
        ticketNumber: widget.booking.ticketNumber ?? 'N/A',
        transactionId: widget.transactionId,
        amount: widget.booking.amount,
        currency: widget.booking.currency,
        route: '${widget.booking.routeId}', // Could be enhanced with actual route names
      );
    } catch (e) {
      print('[SuccessPage] Failed to notify host: $e');
      // Continue without bridge notification
    }
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Booking Confirmed!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your bus ticket has been successfully booked and payment confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildBookingDetails(),
              const SizedBox(height: 24),
              _buildQRCode(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToHome(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Booking ID', widget.booking.id),
            _buildDetailRow('Ticket Number', widget.booking.ticketNumber ?? 'N/A'),
            _buildDetailRow('Transaction ID', widget.transactionId),
            _buildDetailRow('Amount', widget.booking.formattedAmount),
            _buildDetailRow('Status', widget.booking.status.toUpperCase()),
            _buildDetailRow('Date', widget.booking.departureDate),
            _buildDetailRow('Seats', widget.booking.seatNumbers.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Ticket QR Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'QR Code\nPlaceholder',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Show this QR code when boarding the bus',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}