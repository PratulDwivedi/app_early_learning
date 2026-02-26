class Guardian {
  final String email;
  final String fullName;
  final GuardianData data;
  final List<GuardianStudent> students;

  Guardian({
    required this.email,
    required this.fullName,
    required this.data,
    required this.students,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    final studentsRaw = json['students'];
    final studentsList = studentsRaw is List
        ? studentsRaw
            .map(
              (item) => item is Map<String, dynamic>
                  ? GuardianStudent.fromJson(item)
                  : null,
            )
            .whereType<GuardianStudent>()
            .toList()
        : <GuardianStudent>[];

    return Guardian(
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      data: GuardianData.fromJson(json['data'] ?? {}),
      students: studentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'full_name': fullName,
      'data': data.toJson(),
      'students': students.map((student) => student.toJson()).toList(),
    };
  }
}

class GuardianStudent {
  final int id;
  final String firstName;
  final String lastName;
  final int? grade;

  GuardianStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.grade,
  });

  factory GuardianStudent.fromJson(Map<String, dynamic> json) {
    return GuardianStudent(
      id: _toInt(json['id']),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      grade: _tryToInt(json['grade']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'grade': grade,
    };
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _tryToInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
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
