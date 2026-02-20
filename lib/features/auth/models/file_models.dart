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
