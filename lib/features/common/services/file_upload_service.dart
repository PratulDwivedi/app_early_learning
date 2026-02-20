import 'dart:io';
import '../../../config/app_config.dart';
import '../../auth/models/file_models.dart';
import 'supabase_file_upload_service.dart';

abstract class FileUploadService {
  static FileUploadService get instance {
    if (appConfig.serviceType == ServiceType.supabase) {
      return SupabaseFileUploadService();
    } else {
      return SupabaseFileUploadService();
    }
  }

  // File upload methods
  Future<FileMetadataModel?> uploadFile({
    required File file,
    Map<String, dynamic>? data,
  });
}
