import 'package:smart_university_management_platform/data/models/program.dart';

class MajorItem {
  const MajorItem({
    required this.majorId,
    required this.facultyId,
    required this.facultyName,
    required this.code,
    required this.name,
  });

  final int majorId;
  final int facultyId;
  final String facultyName;
  final String code;
  final String name;

  factory MajorItem.fromJson(Map<String, dynamic> json) => MajorItem(
        majorId: json['majorId'] as int,
        facultyId: json['facultyId'] as int,
        facultyName: json['facultyName'] as String? ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class MajorDetail extends MajorItem {
  const MajorDetail({
    required super.majorId,
    required super.facultyId,
    required super.facultyName,
    required super.code,
    required super.name,
    required this.programs,
  });

  final List<ProgramItem> programs;

  factory MajorDetail.fromJson(Map<String, dynamic> json) => MajorDetail(
        majorId: json['majorId'] as int,
        facultyId: json['facultyId'] as int,
        facultyName: json['facultyName'] as String? ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        programs: (json['programs'] as List<dynamic>? ?? [])
            .map((e) => ProgramItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CreateMajorRequest {
  const CreateMajorRequest({
    required this.facultyId,
    required this.code,
    required this.name,
  });

  final int facultyId;
  final String code;
  final String name;

  Map<String, dynamic> toJson() =>
      {'facultyId': facultyId, 'code': code, 'name': name};
}

class UpdateMajorRequest {
  const UpdateMajorRequest({required this.name});
  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
