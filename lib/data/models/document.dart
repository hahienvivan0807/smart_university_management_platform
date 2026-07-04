// ============================================================================
// DOCUMENT MODEL — khớp với DocumentDto bên backend
//
// Scope đúng 1 trong 2: courseId (tài liệu chung của môn) HOẶC
// courseOfferingId (tài liệu riêng của 1 lớp học phần).
// ============================================================================

class DocumentItem {
  const DocumentItem({
    required this.documentId,
    this.courseId,
    this.courseOfferingId,
    required this.originalFileName,
    required this.contentType,
    required this.fileSizeBytes,
    this.description,
    required this.uploadedAtUtc,
    required this.uploadedByName,
  });

  final int documentId;
  final int? courseId;
  final int? courseOfferingId;
  final String originalFileName;
  final String contentType;
  final int fileSizeBytes;
  final String? description;
  final DateTime uploadedAtUtc;
  final String uploadedByName;

  /// Dung lượng hiển thị dễ đọc (VD: "1.2 MB").
  String get dungLuongHienThi {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
        documentId: json['documentId'] as int,
        courseId: json['courseId'] as int?,
        courseOfferingId: json['courseOfferingId'] as int?,
        originalFileName: json['originalFileName'] as String,
        contentType: json['contentType'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        description: json['description'] as String?,
        uploadedAtUtc: DateTime.parse(json['uploadedAtUtc'] as String),
        uploadedByName: json['uploadedByName'] as String,
      );
}
