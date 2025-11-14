class Ticket {
  final String bookingId;
  final String ticketNumber;
  final String transactionId;
  final int amount;
  final String currency;
  final String origin;
  final String destination;
  final List<String> seatNumbers;
  final String departureDate;
  final String status;
  final String? qrCode;
  final String createdAt;

  Ticket({
    required this.bookingId,
    required this.ticketNumber,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.origin,
    required this.destination,
    required this.seatNumbers,
    required this.departureDate,
    required this.status,
    this.qrCode,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      bookingId: json['bookingId'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      transactionId: json['transactionId'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? '',
      origin: json['route']['origin'] ?? '',
      destination: json['route']['destination'] ?? '',
      seatNumbers: List<String>.from(json['seatNumbers'] ?? []),
      departureDate: json['departureDate'] ?? '',
      status: json['status'] ?? '',
      qrCode: json['qrCode'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'ticketNumber': ticketNumber,
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'route': {
        'origin': origin,
        'destination': destination,
      },
      'seatNumbers': seatNumbers,
      'departureDate': departureDate,
      'status': status,
      'qrCode': qrCode,
      'createdAt': createdAt,
    };
  }
}