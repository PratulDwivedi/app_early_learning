class Student {
  final int? id;
  final String firstName;
  final String lastName;
  final int? grade;
  final String? dob;
  final String? avatarUrl;

  Student({
    this.id,
    required this.firstName,
    required this.lastName,
    this.grade,
    this.dob,
    this.avatarUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['p_id'] as int?,
      firstName: json['p_first_name'] as String? ?? '',
      lastName: json['p_last_name'] as String? ?? '',
      grade: json['p_grade'] as int?,
      dob: json['p_dob'] as String?,
      avatarUrl: json['p_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p_first_name': firstName,
      'p_last_name': lastName,
      'p_grade': grade,
      'p_dob': dob,
      'p_avatar_url': avatarUrl,
    };
  }

  // Helper method for full name
  String get fullName => '$firstName $lastName';

  // Copy with method for updates
  Student copyWith({
    int? id,
    String? firstName,
    String? lastName,
    int? grade,
    String? dob,
    String? avatarUrl,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      grade: grade ?? this.grade,
      dob: dob ?? this.dob,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
