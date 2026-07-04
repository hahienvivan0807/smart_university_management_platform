// ============================================================================
// ACADEMIC TERM MODEL  —  ánh xạ AcademicTermListDto từ backend
// ============================================================================

class AcademicTermItem {
  const AcademicTermItem({
    required this.academicTermId,
    required this.academicYear,
    required this.termNumber,
    required this.termTypeName,
    required this.startDate,
    required this.endDate,
  });

  final int academicTermId;

  /// Năm học bắt đầu. VD: 2024 = năm học 2024-2025
  final int academicYear;

  /// Số thứ tự kỳ: 1 = HK1, 2 = HK2, 3 = Hè
  final int termNumber;

  /// "Học kỳ chính" hoặc "Học kỳ hè"
  final String termTypeName;

  final DateTime startDate;
  final DateTime endDate;

  /// Nhãn hiển thị. VD: "HK1 2024-2025"
  String get label => 'HK$termNumber $academicYear-${academicYear + 1}';

  factory AcademicTermItem.fromJson(Map<String, dynamic> json) =>
      AcademicTermItem(
        academicTermId: json['academicTermId'] as int,
        academicYear: json['academicYear'] as int,
        termNumber: json['termNumber'] as int,
        termTypeName: json['termTypeName'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
      );
}

String _formatDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CreateAcademicTermRequest {
  const CreateAcademicTermRequest({
    required this.academicYear,
    required this.termNumber,
    required this.termType,
    required this.startDate,
    required this.endDate,
  });

  final int academicYear;
  final int termNumber; // 1=HK1, 2=HK2, 3=Hè
  final int termType; // 1=Học kỳ chính, 2=Học kỳ hè
  final DateTime startDate;
  final DateTime endDate;

  Map<String, dynamic> toJson() => {
        'academicYear': academicYear,
        'termNumber': termNumber,
        'termType': termType,
        'startDate': _formatDateOnly(startDate),
        'endDate': _formatDateOnly(endDate),
      };
}

class UpdateAcademicTermRequest {
  const UpdateAcademicTermRequest({
    required this.startDate,
    required this.endDate,
    required this.termType,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int termType;

  Map<String, dynamic> toJson() => {
        'startDate': _formatDateOnly(startDate),
        'endDate': _formatDateOnly(endDate),
        'termType': termType,
      };
}
