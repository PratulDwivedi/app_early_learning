import 'supabase_edu_service.dart';
import '../../../config/app_config.dart';
import '../models/response_message_model.dart';
import '../models/student_model.dart';

abstract class EduService {
  static EduService get instance {
    if (appConfig.serviceType == ServiceType.supabase) {
      return SupabaseEduService();
    } else {
      return SupabaseEduService();
    }
  }

  Future<ResponseMessageModel> getSummaryCount();
  Future<ResponseMessageModel> getHtmlContent(int pageId);
  Future<ResponseMessageModel> saveStudent(Student student);
  Future<ResponseMessageModel> getStudents({
    int pageIndex = 1,
    String searchText = '',
  });
  Future<ResponseMessageModel> saveQuestion(Map<String, dynamic> payload);
  Future<ResponseMessageModel> saveQuestions(
    List<Map<String, dynamic>> questions,
  );
  Future<ResponseMessageModel> getQuestions({
    int pageIndex = 1,
    String searchText = '',
  });
  Future<ResponseMessageModel> getQuestionTypes();
  Future<ResponseMessageModel> getStudentSessions(int studentId);
  Future<ResponseMessageModel> startSession(
    int studentId, {
    int? sessionId,
  });
  Future<ResponseMessageModel> submitAnswer(
    int sessionId,
    int questionId,
    dynamic studentAnswer,
    int timeTakenSec,
  );
  Future<ResponseMessageModel> completeSession(int sessionId, String status);
  Future<ResponseMessageModel> getGuardians({
    int pageIndex = 1,
    String searchText = '',
  });
}
