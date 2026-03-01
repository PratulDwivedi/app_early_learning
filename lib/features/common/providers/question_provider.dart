import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/response_message_model.dart';
import '../services/edu_service.dart';

// Service Provider
final eduServiceProvider = Provider<EduService>((ref) {
  return EduService.instance;
});

class QuestionsPagingParams {
  final int pageIndex;
  final String searchText;

  const QuestionsPagingParams({
    this.pageIndex = 1,
    this.searchText = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionsPagingParams &&
        other.pageIndex == pageIndex &&
        other.searchText == searchText;
  }

  @override
  int get hashCode => Object.hash(pageIndex, searchText);
}

final getQuestionsProvider = FutureProvider.autoDispose
    .family<ResponseMessageModel, QuestionsPagingParams>((ref, params) async {
  final service = ref.watch(eduServiceProvider);
  return service.getQuestions(
    pageIndex: params.pageIndex,
    searchText: params.searchText,
  );
});

final getQuestionTypesProvider =
    FutureProvider.autoDispose<ResponseMessageModel>((ref) async {
  final service = ref.watch(eduServiceProvider);
  return service.getQuestionTypes();
});

final getStudentSessionsProvider = FutureProvider.autoDispose
    .family<ResponseMessageModel, int>((ref, studentId) async {
  final service = ref.watch(eduServiceProvider);
  return service.getStudentSessions(studentId);
});

class StartSessionArgs {
  final int studentId;
  final int? sessionId;

  const StartSessionArgs({
    required this.studentId,
    this.sessionId,
  });
}

final startSessionProvider =
    FutureProvider.autoDispose.family<ResponseMessageModel, StartSessionArgs>((
  ref,
  args,
) async {
  final service = ref.watch(eduServiceProvider);
  return service.startSession(
    args.studentId,
    sessionId: args.sessionId,
  );
});

final questionByIdProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, int>((
  ref,
  questionId,
) async {
  final service = ref.watch(eduServiceProvider);
  final response = await service.getQuestions(pageIndex: 0);
  if (!response.isSuccess) return null;

  for (final q in response.data) {
    final id = q['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (parsedId == questionId) {
      return q;
    }
  }
  return null;
});

// Question Form State Notifier
class QuestionFormNotifier extends StateNotifier<Question> {
  QuestionFormNotifier()
      : super(
          Question(
            questionText: '',
            questionMode: 'LETTER_SOUND_MCQ',
          ),
        );

  void updateQuestionText(String value) {
    state = state.copyWith(questionText: value);
  }

  void updateQuestionMode(String value) {
    state = state.copyWith(questionMode: value);
  }

  void updateOptionsCsv(String? value) {
    state = state.copyWith(optionsCsv: value);
  }

  void updateAudioPrompt(String? value) {
    state = state.copyWith(audioPrompt: value);
  }

  void updateDisplayLetter(String? value) {
    state = state.copyWith(displayLetter: value);
  }

  void updateCorrectAnswer(String? value) {
    state = state.copyWith(correctAnswer: value);
  }

  void updateHint(String? value) {
    state = state.copyWith(hint: value);
  }

  void updateImageUrl(String? value) {
    state = state.copyWith(imageUrl: value);
  }

  void updateAudioUrl(String? value) {
    state = state.copyWith(audioUrl: value);
  }

  void updateDifficulty(int? value) {
    state = state.copyWith(difficulty: value);
  }

  void updateSortOrder(int? value) {
    state = state.copyWith(sortOrder: value);
  }

  void reset() {
    state = Question(
      questionText: '',
      questionMode: 'LETTER_SOUND_MCQ',
    );
  }
}

// Question Form Provider - with autoDispose to reset when screen closes
final questionFormProvider =
    StateNotifierProvider.autoDispose<QuestionFormNotifier, Question>((ref) {
  return QuestionFormNotifier();
});
