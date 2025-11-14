class PassengerDetail {
  final String name;
  final String phone;

  PassengerDetail({
    required this.name,
    required this.phone,
  });

  factory PassengerDetail.fromJson(Map<String, dynamic> json) {
    return PassengerDetail(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

class Booking {
  final String id;
  final String routeId;
  final String departureDate;
  final List<String> seatNumbers;
  final String userId;
  final List<PassengerDetail> passengerDetails;
  final int amount;
  final String currency;
  final String paymentReference;
  final String status;
  final String? transactionId;
  final String? paymentMethod;
  final String? ticketNumber;
  final String? qrCode;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.routeId,
    required this.departureDate,
    required this.seatNumbers,
    required this.userId,
    required this.passengerDetails,
    required this.amount,
    required this.currency,
    required this.paymentReference,
    required this.status,
    this.transactionId,
    this.paymentMethod,
    this.ticketNumber,
    this.qrCode,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['booking_id'] ?? '',
      routeId: json['route_id'] ?? '',
      departureDate: json['departure_date'] ?? '',
      seatNumbers: List<String>.from(json['seat_numbers'] ?? []),
      userId: json['user_id'] ?? '',
      passengerDetails: (json['passenger_details'] as List?)
          ?.map((e) => PassengerDetail.fromJson(e))
          .toList() ?? [],
      amount: json['amount']?.toInt() ?? 0,
      currency: json['currency'] ?? '',
      paymentReference: json['payment_reference'] ?? '',
      status: json['status'] ?? '',
      transactionId: json['transaction_id'],
      paymentMethod: json['payment_method'],
      ticketNumber: json['ticket_number'],
      qrCode: json['qr_code'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': id,
      'route_id': routeId,
      'departure_date': departureDate,
      'seat_numbers': seatNumbers,
      'user_id': userId,
      'passenger_details': passengerDetails.map((e) => e.toJson()).toList(),
      'amount': amount,
      'currency': currency,
      'payment_reference': paymentReference,
      'status': status,
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'ticket_number': ticketNumber,
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedAmount => '$amount $currency';
}