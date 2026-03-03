import 'dart:developer' as developer;
import '../../../config/app_constants.dart';
import '../models/response_message_model.dart';
import '../models/student_model.dart';
import 'supabase_api_helper.dart';
import 'edu_service.dart';

class SupabaseEduService implements EduService {
  @override
  Future<ResponseMessageModel> getSummaryCount() async {
    final response = await SupabaseApiHelper.post(ApiRoutes.summaryCount, null);
    return response;
  }

  @override
  Future<ResponseMessageModel> getHtmlContent(int pageId) async {
    final response = await SupabaseApiHelper.post(ApiRoutes.htmlContent, {
      "p_page_id": pageId,
    });
    return response;
  }

  @override
  Future<ResponseMessageModel> saveStudent(Student student) async {
    // Debug: Log student object values
    developer.log(
      'saveStudent called with: firstName=${student.firstName}, lastName=${student.lastName}, grade=${student.grade}, dob=${student.dob}',
      name: 'StudentService',
    );

    final payload = {
      if (student.id != null) 'p_id': student.id,
      'p_first_name': student.firstName,
      'p_last_name': student.lastName,
      'p_grade': student.grade,
      'p_dob': student.dob,
      'p_avatar_url': student.avatarUrl,
    };

    // Debug: Log the payload being sent
    developer.log(
      'API Payload: $payload',
      name: 'StudentService',
    );

    final response = await SupabaseApiHelper.post(ApiRoutes.addstudent, payload);

    // Debug: Log API response
    developer.log(
      'API Response: isSuccess=${response.isSuccess}, message=${response.message}, statusCode=${response.statusCode}',
      name: 'StudentService',
    );

    return response;
  }

  @override
  Future<ResponseMessageModel> getStudents({
    int pageIndex = 1,
    String searchText = '',
  }) async {
    final payload = {
      'p_page_index': pageIndex,
      'p_search_text': searchText,
    };
    final response = await SupabaseApiHelper.post(ApiRoutes.getStudents, payload);
    return response;
  }

  @override
  Future<ResponseMessageModel> saveQuestion(Map<String, dynamic> payload) async {
    developer.log(
      'saveQuestion called',
      name: 'QuestionService',
    );

    developer.log(
      'API Payload: $payload',
      name: 'QuestionService',
    );

    final response = await SupabaseApiHelper.post(ApiRoutes.addquestion, payload);

    developer.log(
      'API Response: isSuccess=${response.isSuccess}, message=${response.message}, statusCode=${response.statusCode}',
      name: 'QuestionService',
    );

    return response;
  }

  @override
  Future<ResponseMessageModel> saveQuestions(
    List<Map<String, dynamic>> questions,
  ) async {
    final payload = {'p_questions': questions};

    developer.log(
      'saveQuestions called with ${questions.length} questions',
      name: 'QuestionService',
    );
    developer.log(
      'API Payload: $payload',
      name: 'QuestionService',
    );

    final response = await SupabaseApiHelper.post(
      ApiRoutes.savequestions,
      payload,
    );

    developer.log(
      'API Response: isSuccess=${response.isSuccess}, message=${response.message}, statusCode=${response.statusCode}',
      name: 'QuestionService',
    );

    return response;
  }

  @override
  Future<ResponseMessageModel> getQuestions({
    int pageIndex = 1,
    String searchText = '',
  }) async {
    final payload = {
      'p_page_index': pageIndex,
      'p_search_text': searchText,
    };
    final response = await SupabaseApiHelper.post(ApiRoutes.getQuestions, payload);
    return response;
  }

  @override
  Future<ResponseMessageModel> getQuestionTypes() async {
    final response = await SupabaseApiHelper.post(
      ApiRoutes.getQuestionTypes,
      null,
    );
    return response;
  }

  @override
  Future<ResponseMessageModel> getConfig() async {
    final response = await SupabaseApiHelper.post(ApiRoutes.getConfig, null);
    return response;
  }

  @override
  Future<ResponseMessageModel> saveConfig({
    required int totalQuestions,
    required int totalDurationMinutes,
  }) async {
    final payload = {
      'p_name': 'Edu Configuration',
      'p_data': {
        'total_questions': totalQuestions,
        'total_duration_minutes': totalDurationMinutes,
      },
    };
    final response = await SupabaseApiHelper.post(ApiRoutes.saveConfig, payload);
    return response;
  }

  @override
  Future<ResponseMessageModel> getStudentSessions(int studentId) async {
    final payload = {
      'p_student_id': studentId,
    };
    final response = await SupabaseApiHelper.post(
      ApiRoutes.getStudentSessions,
      payload,
    );
    return response;
  }

  @override
  Future<ResponseMessageModel> startSession(
    int studentId, {
    int? sessionId,
  }) async {
    final payload = {
      'p_student_id': studentId,
      if (sessionId != null && sessionId > 0) 'p_session_id': sessionId,
    };
    final response = await SupabaseApiHelper.post(ApiRoutes.startSession, payload);
    return response;
  }

  @override
  Future<ResponseMessageModel> submitAnswer(
    int sessionId,
    int questionId,
    dynamic studentAnswer,
    int timeTakenSec,
    Map<String, dynamic>? data,
  ) async {
    final payload = {
      'p_session_id': sessionId,
      'p_question_id': questionId,
      'p_student_answer': studentAnswer,
      'p_time_taken_sec': timeTakenSec,
      'p_data': data,
    };
    final response = await SupabaseApiHelper.post(ApiRoutes.submitAnswer, payload);
    return response;
  }

  @override
  Future<ResponseMessageModel> completeSession(int sessionId, String status) async {
    final payload = {
      'p_session_id': sessionId,
      'p_status': status,
    };
    final response = await SupabaseApiHelper.post(
      ApiRoutes.completeSession,
      payload,
    );
    return response;
  }

  @override
  Future<ResponseMessageModel> getGuardians({
    int pageIndex = 1,
    String searchText = '',
  }) async {
    final payload = {
      'p_page_index': pageIndex,
      'p_search_text': searchText,
    };
    final response = await SupabaseApiHelper.post(ApiRoutes.getGuardians, payload);
    return response;
  }
}
