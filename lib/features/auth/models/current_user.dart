class CurrentUser {
  final int id;
  final int eventId;
  final String loginId;
  final String fullName;
  final DateTime issuedOn;
  final int tenantId;
  final DateTime expiresOn;
  final String accessToken;

  CurrentUser({
    required this.id,
    required this.eventId,
    required this.loginId,
    required this.fullName,
    required this.issuedOn,
    required this.tenantId,
    required this.expiresOn,
    required this.accessToken,
  });

  /// Factory constructor to create object from JSON
  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as int,
      eventId: json['event_id'] as int,
      loginId: json['login_id'] as String,
      fullName: json['full_name'] as String,
      issuedOn: DateTime.parse(json['issued_on']),
      tenantId: json['tenant_id'] as int,
      expiresOn: DateTime.parse(json['expires_on']),
      accessToken: json['access_token'] as String,
    );
  }

  /// Convert object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'login_id': loginId,
      'full_name': fullName,
      'issued_on': issuedOn.toIso8601String(),
      'tenant_id': tenantId,
      'expires_on': expiresOn.toIso8601String(),
      'access_token': accessToken,
    };
  }
}
