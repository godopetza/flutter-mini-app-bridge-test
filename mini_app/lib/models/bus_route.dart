class BusRoute {
  final String id;
  final String origin;
  final String destination;
  final int price;
  final String currency;
  final int durationHours;

  BusRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.price,
    required this.currency,
    required this.durationHours,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      price: json['price']?.toInt() ?? 0,
      currency: json['currency'] ?? '',
      durationHours: json['duration_hours']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'price': price,
      'currency': currency,
      'duration_hours': durationHours,
    };
  }

  String get formattedPrice => '$price $currency';
  String get formattedDuration => '${durationHours}h';
}