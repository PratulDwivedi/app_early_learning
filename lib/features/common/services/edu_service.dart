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
}
