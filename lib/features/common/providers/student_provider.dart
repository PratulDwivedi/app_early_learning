import 'package:flutter_riverpod/flutter_riverpod.dart';
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
class StudentsPagingParams {
  final int pageIndex;
  final String searchText;

  const StudentsPagingParams({
    this.pageIndex = 1,
    this.searchText = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentsPagingParams &&
        other.pageIndex == pageIndex &&
        other.searchText == searchText;
  }

  @override
  int get hashCode => Object.hash(pageIndex, searchText);
}

final getStudentsProvider = FutureProvider.autoDispose
    .family<ResponseMessageModel, StudentsPagingParams>(
  (ref, params) async {
    final service = ref.watch(eduServiceProvider);
    return service.getStudents(
      pageIndex: params.pageIndex,
      searchText: params.searchText,
    );
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


class GuardiansPagingParams {
  final int pageIndex;
  final String searchText;

  const GuardiansPagingParams({
    this.pageIndex = 1,
    this.searchText = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuardiansPagingParams &&
        other.pageIndex == pageIndex &&
        other.searchText == searchText;
  }

  @override
  int get hashCode => Object.hash(pageIndex, searchText);
}

// Guardians List Provider - paged
final getGuardiansProvider = FutureProvider.autoDispose
    .family<ResponseMessageModel, GuardiansPagingParams>(
  (ref, params) async {
    final service = ref.watch(eduServiceProvider);
    return service.getGuardians(
      pageIndex: params.pageIndex,
      searchText: params.searchText,
    );
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
