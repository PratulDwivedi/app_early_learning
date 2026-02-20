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
}

class UserPreferences {
  final bool? isAdmin;
  final String? dateFormat;
  final String? datetimeFormat;
  final String? profilePic;

  UserPreferences({
    this.isAdmin,
    this.dateFormat,
    this.datetimeFormat,
    this.profilePic,
  });

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserPreferences();

    final dynamic isAdminVal = json['is_admin'];
    bool? isAdmin;
    if (isAdminVal is bool) {
      isAdmin = isAdminVal;
    } else if (isAdminVal is int) {
      isAdmin = isAdminVal == 1;
    } else if (isAdminVal is String) {
      final lower = isAdminVal.toLowerCase();
      if (lower == 'true' || lower == '1') {
        isAdmin = true;
      } else if (lower == 'false' || lower == '0') {
        isAdmin = false;
      }
    }

    return UserPreferences(
      isAdmin: isAdmin,
      dateFormat: json['date_format'] as String?,
      datetimeFormat: json['datetime_format'] as String?,
      profilePic: json['profile_pic'] as String?,
    );
  }

}
