import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import '../models/bus_route.dart';
import '../models/booking.dart';
import '../models/bank_user.dart';
import '../services/bank_bridge.dart';
import '../services/mock_bridge.dart';
import 'checkout_page.dart';

class BookingPage extends StatefulWidget {
  final BusRoute route;

  const BookingPage({super.key, required this.route});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDate;
  final Set<String> _selectedSeats = {};
  final List<PassengerDetail> _passengers = [];

  late final BankBridge _bridge;
  BankUser? _currentUser;
  bool _isBridgeInitialized = false;

  static const List<String> _availableSeats = [
    'A1',
    'A2',
    'A3',
    'A4',
    'B1',
    'B2',
    'B3',
    'B4',
    'C1',
    'C2',
    'C3',
    'C4',
  ];

  @override
  void initState() {
    super.initState();
    // Force use real bridge when loaded in iframe (host app)
    final isInIframe = html.window.parent != html.window;
    print('[BookingPage] 🔍 Environment check:');
    print('[BookingPage] 📱 Debug mode: $kDebugMode');
    print('[BookingPage] 🖼️ In iframe: $isInIframe');

    if (isInIframe) {
      print('[BookingPage] 🌐 Using real bridge (in host app)');
      _bridge = BankBridge();
    } else {
      print('[BookingPage] 🧪 Using mock bridge (standalone)');
      _bridge = MockBridge();
    }
    _initializeBridge();
  }

  Future<void> _initializeBridge() async {
    try {
      await _bridge.initialize();

      // Listen for user updates
      _bridge.userStream.listen((user) {
        if (mounted && user != null) {
          print('[BookingPage] 🎉 Received user data from bridge:');
          print('[BookingPage] 📋 Full user data: ${user.toJson()}');
          print(
            '[BookingPage] 🔍 Data source: ${user.dataSource ?? 'UNKNOWN'}',
          );

          setState(() {
            _currentUser = user;
            _isBridgeInitialized = true;

            // If we already have passengers selected, update the first one with user data
            if (_passengers.isNotEmpty) {
              _passengers[0] = PassengerDetail(
                name: user.name,
                phone: user.phone,
              );
            }
          });

          print(
            '[BookingPage] Bridge user received: ${user.name}, ${user.phone}',
          );
        }
      });
    } catch (e) {
      print('[BookingPage] Bridge initialization failed: $e');
      // Continue without bridge functionality
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
        title: const Text('Book Seats'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data source verification widget
            _buildDataSourceInfo(),
            _buildRouteInfo(),
            const SizedBox(height: 24),
            _buildDateSelection(),
            const SizedBox(height: 24),
            _buildSeatSelection(),
            const SizedBox(height: 24),
            _buildPassengerForms(),
            const SizedBox(height: 24),
            _buildSummaryAndContinue(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.route.origin,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.arrow_downward, size: 20),
                      const SizedBox(height: 8),
                      Text(
                        widget.route.destination,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.route.formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'per seat',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.route.formattedDuration,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Departure Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Tap to select date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Seats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _availableSeats.length,
              itemBuilder: (context, index) {
                final seat = _availableSeats[index];
                final isSelected = _selectedSeats.contains(seat);
                return InkWell(
                  onTap: () => _toggleSeat(seat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        seat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerForms() {
    if (_selectedSeats.isEmpty) {
      return Container();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passenger Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Validate state consistency before building forms
            ..._buildPassengerFormsList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPassengerFormsList() {
    // Validate state consistency
    if (_selectedSeats.length != _passengers.length) {
      print(
        '[BookingPage] ⚠️ State mismatch: ${_selectedSeats.length} seats but ${_passengers.length} passengers',
      );
      // Fix the mismatch by adjusting passengers
      while (_passengers.length < _selectedSeats.length) {
        _passengers.add(PassengerDetail(name: '', phone: ''));
      }
      while (_passengers.length > _selectedSeats.length) {
        _passengers.removeLast();
      }
    }

    return List.generate(_selectedSeats.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPassengerForm(index),
      );
    });
  }

  Widget _buildPassengerForm(int index) {
    final seat = _selectedSeats.elementAt(index);

    // Passenger should already exist from _toggleSeat, but safety check
    if (index >= _passengers.length) {
      print(
        '[BookingPage] ⚠️ Warning: Passenger missing for index $index, creating empty passenger',
      );
      _passengers.add(PassengerDetail(name: '', phone: ''));
    }

    // Create controllers with pre-filled data
    final nameController = TextEditingController(text: _passengers[index].name);
    final phoneController = TextEditingController(
      text: _passengers[index].phone,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger ${index + 1} (Seat $seat)',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: const OutlineInputBorder(),
              helperText: index == 0 && _currentUser != null
                  ? 'Auto-filled from your account'
                  : null,
            ),
            onChanged: (value) {
              _passengers[index] = PassengerDetail(
                name: value,
                phone: _passengers[index].phone,
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: const OutlineInputBorder(),
              helperText: index == 0 && _currentUser != null
                  ? 'Auto-filled from your account'
                  : null,
            ),
            onChanged: (value) {
              _passengers[index] = PassengerDetail(
                name: _passengers[index].name,
                phone: value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndContinue() {
    final totalAmount = widget.route.price * _selectedSeats.length;
    final canProceed =
        _selectedDate != null &&
        _selectedSeats.isNotEmpty &&
        _passengers.length == _selectedSeats.length &&
        _passengers.every((p) => p.name.isNotEmpty && p.phone.isNotEmpty);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selected seats:'),
                Text(_selectedSeats.join(', ')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Number of passengers:'),
                Text(_selectedSeats.length.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price per seat:'),
                Text(widget.route.formattedPrice),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$totalAmount ${widget.route.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: _buildProceedButton()),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final maxDate = today.add(const Duration(days: 30));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: maxDate,
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  void _toggleSeat(String seat) {
    setState(() {
      if (_selectedSeats.contains(seat)) {
        // Remove seat and corresponding passenger
        final seatIndex = _selectedSeats.toList().indexOf(seat);
        _selectedSeats.remove(seat);
        if (seatIndex < _passengers.length) {
          _passengers.removeAt(seatIndex);
        }
        print(
          '[BookingPage] 🪑 Removed seat $seat and passenger at index $seatIndex',
        );
      } else {
        // Add seat and create corresponding passenger
        _selectedSeats.add(seat);

        // Auto-fill passenger data from bridge user
        String passengerName = '';
        String passengerPhone = '';

        if (_currentUser != null) {
          // For first passenger, use the bridge user data
          if (_passengers.isEmpty) {
            passengerName = _currentUser!.name;
            passengerPhone = _currentUser!.phone;

            final dataSource = _currentUser!.dataSource ?? 'UNKNOWN';
            print(
              '[BookingPage] 🎯 Auto-filling first passenger from $dataSource:',
            );
            print('[BookingPage] 📝 Name: ${_currentUser!.name}');
            print('[BookingPage] 📞 Phone: ${_currentUser!.phone}');
            print('[BookingPage] 🆔 User ID: ${_currentUser!.userId}');
            print('[BookingPage] 💳 Account: ${_currentUser!.accountNumber}');
            print(
              '[BookingPage] 🔗 Bridge Version: ${_currentUser!.bridgeVersion ?? 'N/A'}',
            );
            print(
              '[BookingPage] ⏰ Timestamp: ${_currentUser!.timestamp ?? 'N/A'}',
            );
          } else {
            // For additional passengers, leave empty for manual entry
            print(
              '[BookingPage] 📝 Adding empty passenger for additional seat',
            );
          }
        } else {
          print('[BookingPage] ⚠️ No current user available for autofill');
        }

        // Always add a new passenger for the new seat
        final newPassenger = PassengerDetail(
          name: passengerName,
          phone: passengerPhone,
        );
        _passengers.add(newPassenger);
        print(
          '[BookingPage] ✅ Added passenger ${_passengers.length}: $passengerName for seat $seat',
        );
      }

      // Ensure passenger list matches selected seats
      print(
        '[BookingPage] 📊 State: ${_selectedSeats.length} seats, ${_passengers.length} passengers',
      );
    });
  }

  void _proceedToCheckout() {
    final bookingData = {
      'route': widget.route.toJson(),
      'departureDate': _selectedDate!.toIso8601String().split('T')[0],
      'selectedSeats': _selectedSeats.toList(),
      'passengers': _passengers
          .take(_selectedSeats.length)
          .map((p) => p.toJson())
          .toList(),
      'totalAmount': widget.route.price * _selectedSeats.length,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(bookingData: bookingData),
      ),
    );
  }

  Widget _buildDataSourceInfo() {
    if (!_isBridgeInitialized || _currentUser == null) {
      return Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Bridge initializing...',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dataSource = _currentUser!.dataSource ?? 'UNKNOWN';
    final isFromHost = dataSource == 'HOST_APP';
    final color = isFromHost ? Colors.green : Colors.blue;
    final icon = isFromHost ? Icons.cloud_done : Icons.memory;
    final text = isFromHost
        ? 'Connected to Host App ✅'
        : 'Using Mock Data ($dataSource)';

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User: ${_currentUser!.name}',
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Account: ${_currentUser!.accountNumber}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Source: ${_currentUser!.dataSource ?? 'UNKNOWN'}',
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                  if (_currentUser!.bridgeVersion != null)
                    Text(
                      'Bridge v${_currentUser!.bridgeVersion}',
                      style: TextStyle(color: color, fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _areAllPassengerDetailsFilled() {
    return _passengers.length == _selectedSeats.length &&
        _passengers.every((p) => p.name.isNotEmpty && p.phone.isNotEmpty);
  }

  Widget _buildProceedButton() {
    final isHostConnected = _currentUser?.dataSource == 'HOST_APP';
    final canProceed =
        _selectedSeats.isNotEmpty &&
        _selectedDate != null &&
        _areAllPassengerDetailsFilled() &&
        isHostConnected;

    String buttonText;
    if (!isHostConnected) {
      buttonText = '🔒 Host App Connection Required';
    } else if (_selectedSeats.isEmpty) {
      buttonText = 'Select at least one seat';
    } else if (_selectedDate == null) {
      buttonText = 'Select departure date';
    } else if (!_areAllPassengerDetailsFilled()) {
      buttonText = 'Fill in passenger details';
    } else {
      buttonText =
          'Proceed to Checkout (TZS ${widget.route.price * _selectedSeats.length})';
    }

    return ElevatedButton(
      onPressed: canProceed ? _proceedToCheckout : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: !isHostConnected ? Colors.red : null,
        foregroundColor: !isHostConnected ? Colors.white : null,
      ),
      child: Text(buttonText, style: const TextStyle(fontSize: 16)),
    );
  }
}
