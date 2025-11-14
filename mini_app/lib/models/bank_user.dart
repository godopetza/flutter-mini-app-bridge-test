class BankUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String token;
  final String accountNumber;
  final String? dataSource;
  final String? bridgeVersion;
  final String? timestamp;

  BankUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.token,
    required this.accountNumber,
    this.dataSource,
    this.bridgeVersion,
    this.timestamp,
  });

  factory BankUser.fromJson(Map<String, dynamic> json) {
    return BankUser(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      token: json['token'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      dataSource: json['dataSource'],
      bridgeVersion: json['bridgeVersion'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'token': token,
      'accountNumber': accountNumber,
      if (dataSource != null) 'dataSource': dataSource,
      if (bridgeVersion != null) 'bridgeVersion': bridgeVersion,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}