import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_upload_service.dart';

final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService.instance;
});

// Provider for profile picture upload
final profilePictureUploadProvider = FutureProvider.family<String?, File>((
  ref,
  file,
) async {
  final service = ref.watch(fileUploadServiceProvider);
  final metadata = await service.uploadFile(file: file);

  if (metadata != null) {
    return metadata.storedFileName;
  }
  return null;
});
