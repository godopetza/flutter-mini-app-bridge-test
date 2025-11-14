class PaymentResult {
  final bool success;
  final String? transactionId;
  final DateTime? timestamp;
  final String? error;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.timestamp,
    this.error,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? false,
      transactionId: json['transactionId'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'timestamp': timestamp?.toIso8601String(),
      'error': error,
    };
  }

  factory PaymentResult.success(String transactionId) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResult.failure(String error) {
    return PaymentResult(
      success: false,
      error: error,
    );
  }
}