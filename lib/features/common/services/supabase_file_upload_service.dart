import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';
import '../../auth/models/file_models.dart';
import 'file_upload_service.dart';

class SupabaseFileUploadService implements FileUploadService {
  @override
  Future<FileUploadResponse?> uploadFileByPath({
    required String filePath,
    Map<String, dynamic>? data,
  }) async {
    return uploadFile(file: File(filePath), data: data);
  }

  @override
  Future<FileUploadResponse?> uploadFile({
    required File file,
    Map<String, dynamic>? data,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadFileBytes(
      fileBytes: bytes,
      fileName: file.path.split('/').last,
      data: data,
    );
  }

  @override
  Future<FileUploadResponse?> uploadFileBytes({
    required Uint8List fileBytes,
    required String fileName,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? "";

      // File size validation
      final fileSizeBytes = fileBytes.length;
      final fileSizeMb = fileSizeBytes / (1024 * 1024);

      if (fileSizeMb > 5) {
        throw Exception('File size too large. Maximum 5MB allowed.');
      }

      final uri = Uri.parse(
        '${appConfig.apiBaseUrl}/functions/v1/edu-file-upload',
      );

      final request = http.MultipartRequest('POST', uri);

      // ✅ Required headers (same as Postman)
      request.headers.addAll({
        'apikey': appConfig.localKey,
        'Authorization': 'Bearer $accessToken'
      });

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.body}');
      }

      // ✅ Proper JSON decoding
      final jsonData = jsonDecode(response.body);

      return FileUploadResponse.fromJson(jsonData);
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}
