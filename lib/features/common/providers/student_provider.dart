import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/guardian_model.dart';
import '../services/edu_service.dart';
import '../models/student_model.dart';
import '../models/response_message_model.dart';

// Service Provider
final eduServiceProvider = Provider<EduService>((ref) {
  return EduService.instance;
});

// Student Save Provider - with autoDispose to prevent caching
final saveStudentProvider = FutureProvider.autoDispose
    .family<ResponseMessageModel, Student>(
  (ref, student) async {
    final service = ref.watch(eduServiceProvider);
    return service.saveStudent(student);
  },
);

// Students List Provider - with autoDispose for fresh data
final getStudentsProvider = FutureProvider.autoDispose<ResponseMessageModel>(
  (ref) async {
    final service = ref.watch(eduServiceProvider);
    return service.getStudents();
  },
);

// Student Form State Notifier
class StudentFormNotifier extends StateNotifier<Student> {
  StudentFormNotifier()
      : super(
          Student(
            firstName: '',
            lastName: '',
          ),
        );

  void updateFirstName(String value) {
    state = state.copyWith(firstName: value);
  }

  void updateLastName(String value) {
    state = state.copyWith(lastName: value);
  }

  void updateGrade(int? value) {
    state = state.copyWith(grade: value);
  }

  void updateDob(String? value) {
    state = state.copyWith(dob: value);
  }

  void updateAvatarUrl(String? value) {
    state = state.copyWith(avatarUrl: value);
  }

  void reset() {
    state = Student(
      firstName: '',
      lastName: '',
    );
  }
}

// Student Form Provider - with autoDispose to reset when screen closes
final studentFormProvider =
    StateNotifierProvider.autoDispose<StudentFormNotifier, Student>((ref) {
  return StudentFormNotifier();
});


// Guardians List Provider - with autoDispose for fresh data
final getGuardiansProvider = FutureProvider.autoDispose<List<Guardian>>(
  (ref) async {
    final service = ref.watch(eduServiceProvider);
    final response = await service.getGuardians();
    
    if (response.isSuccess && response.data.isNotEmpty) {
      // Parse the list of guardians from response data
      final guardiansList = (response.data as List)
          .map((item) => Guardian.fromJson(item as Map<String, dynamic>))
          .toList();
      return guardiansList;
    }
    return [];
  },
);

// Student Summary Provider - for charts (Pie and Bar)
final studentSummaryProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) async {
    final service = ref.watch(eduServiceProvider);
    final response = await service.getSummaryCount();
    
    if (response.isSuccess && response.data.isNotEmpty) {
      return response.data as List<dynamic>;
    }
    return [];
  },
);
