class CurrentUser {
  final String id;
  final int uid;
  final UserPreferences data;
  final String email;
  final String fullName;
  final int tenantId;
  final String userName;
  final String tenantName;

  CurrentUser({
    required this.id,
    required this.uid,
    required this.data,
    required this.email,
    required this.fullName,
    required this.tenantId,
    required this.userName,
    required this.tenantName,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'],
      uid: json['uid'],
      data: UserPreferences.fromJson(json['data']),
      email: json['email'],
      fullName: json['full_name'],
      tenantId: json['tenant_id'],
      userName: json['user_name'],
      tenantName: json['tenant_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'data': data.toJson(),
      'email': email,
      'full_name': fullName,
      'tenant_id': tenantId,
      'user_name': userName,
      'tenant_name': tenantName,
    };
  }
}

class UserPreferences {
  final bool isAdmin;
  final String dateFormat;
  final String datetimeFormat;

  UserPreferences({
    required this.isAdmin,
    required this.dateFormat,
    required this.datetimeFormat,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      isAdmin: json['is_admin'],
      dateFormat: json['date_format'],
      datetimeFormat: json['datetime_format'],
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
