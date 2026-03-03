class FileMetadataModel {
  final String? storedFileName;
  final String originalFilename;
  final int fileSizeBytes;
  final String? mimeType;

  FileMetadataModel({
    required this.originalFilename,
    required this.fileSizeBytes,
    this.storedFileName,
    this.mimeType,
  });

  factory FileMetadataModel.fromJson(Map<String, dynamic> json) {
    return FileMetadataModel(
      originalFilename: json['original_filename'],
      fileSizeBytes: json['file_size_bytes'],
      storedFileName: json['stored_filename'],
      mimeType: json['mime_type'],
    );
  }
}


class FileUploadResponse {
  final String message;
  final String fileName;
  final String publicUrl;

  FileUploadResponse({
    required this.message,
    required this.fileName,
    required this.publicUrl,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      message: json['message'] ?? '',
      fileName: json['file_name'] ?? '',
      publicUrl: json['public_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'file_name': fileName,
      'public_url': publicUrl,
    };
  }
}