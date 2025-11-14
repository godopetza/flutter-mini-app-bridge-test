import 'package:flutter/material.dart';
import '../models/ticket.dart';

class TicketPage extends StatelessWidget {
  final Ticket ticket;

  const TicketPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Ticket'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTicketHeader(),
            const SizedBox(height: 24),
            _buildTicketDetails(),
            const SizedBox(height: 24),
            _buildPassengerInfo(),
            const SizedBox(height: 24),
            if (ticket.qrCode != null) _buildQRCode(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ticket Number: ${ticket.ticketNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Journey Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('From', ticket.origin),
            const SizedBox(height: 8),
            _buildDetailRow('To', ticket.destination),
            const SizedBox(height: 8),
            _buildDetailRow('Departure Date', ticket.departureDate),
            const SizedBox(height: 8),
            _buildDetailRow('Seats', ticket.seatNumbers.join(', ')),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Amount Paid',
              '${ticket.currency} ${_formatNumber(ticket.amount)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Status', ticket.status.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Booking ID', ticket.bookingId),
            const SizedBox(height: 8),
            _buildDetailRow('Transaction ID', ticket.transactionId),
            const SizedBox(height: 8),
            _buildDetailRow('Booking Time', _formatDateTime(ticket.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Digital Ticket',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ticket.qrCode != null
                  ? Image.network(
                      ticket.qrCode!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'QR Code',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('QR Code', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Show this QR code to the bus conductor',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ticket saved to device')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Save Ticket'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Book Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  String _formatNumber(int number) {
    final String numberStr = number.toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < numberStr.length; i++) {
      if (i > 0 && (numberStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(numberStr[i]);
    }

    return buffer.toString();
  }
}
