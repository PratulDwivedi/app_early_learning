class Guardian {
  final String email;
  final String fullName;
  final GuardianData data;

  Guardian({
    required this.email,
    required this.fullName,
    required this.data,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      data: GuardianData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'full_name': fullName,
      'data': data.toJson(),
    };
  }
}

class GuardianData {
  final bool? isAdmin;
  final String? dateFormat;
  final String? datetimeFormat;

  GuardianData({
    this.isAdmin,
    this.dateFormat,
    this.datetimeFormat,
  });

  factory GuardianData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return GuardianData();
    }

    return GuardianData(
      isAdmin: json['is_admin'] as bool?,
      dateFormat: json['date_format'] as String?,
      datetimeFormat: json['datetime_format'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_admin': isAdmin,
      'date_format': dateFormat,
      'datetime_format': datetimeFormat,
    };
  }
}
