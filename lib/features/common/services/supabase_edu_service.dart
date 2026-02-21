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
    final response = await SupabaseApiHelper.post(ApiRoutes.addstudent, {
      if (student.id != null) 'p_id': student.id,
      'p_first_name': student.firstName,
      'p_last_name': student.lastName,
      'p_grade': student.grade,
      'p_dob': student.dob,
      'p_avatar_url': student.avatarUrl,
    });
    return response;
  }
}
