import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';
import '../../../config/app_constants.dart';
import '../../auth/models/file_models.dart';
import 'file_upload_service.dart';
import 'supabase_api_helper.dart';

class SupabaseFileUploadService implements FileUploadService {
  @override
  Future<FileMetadataModel?> uploadFile({
    required File file,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id') ?? 0;

      // Check file size
      final fileSizeBytes = await file.length();
      final fileSizeMb = fileSizeBytes / (1024 * 1024);
      if (fileSizeMb > 5) {
        throw Exception('File size too large. Maximum 5MB allowed.');
      }

      // Build storage path
      final fileExt = file.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${userId}_profile.$fileExt';
      final storagePath = '${appConfig.storageUuid}/$fileName';

      // Upload via Edge Function
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${appConfig.apiBaseUrl}/${ApiRoutes.uploadFile}'),
      );

      // Add headers
      //request.headers['Authorization'] = 'Bearer ${appConfig.localKey}';

      // Add file and fields
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['path'] = storagePath;
      request.fields['bucket'] = appConfig.bucketName;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.body}');
      }

      final fileMetadata = FileMetadataModel(
        storedFileName: fileName,
        originalFilename: file.path.split('/').last,
        fileSizeBytes: fileSizeBytes,
        mimeType: _getMimeType(fileExt),
      );

      final responseFileMeta = await SupabaseApiHelper.post(
        ApiRoutes.fileMetadata,
        {
          "p_stored_filename": fileMetadata.storedFileName,
          "p_original_filename": fileMetadata.originalFilename,
          "p_file_size_bytes": fileMetadata.fileSizeBytes,
          "p_mime_type": fileMetadata.mimeType,
          "p_data": {"storage_type": "seminar-delegate"},
        },
      );

      if (responseFileMeta.isSuccess != true) {
        throw Exception('Metadata save failed: ${responseFileMeta.message}');
      }
      return FileMetadataModel.fromJson(responseFileMeta.data[0]);
    } catch (e) {
      return null;
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
