import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/course_offering.dart';
import 'package:smart_university_management_platform/data/services/course_offering_service.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// COURSE OFFERING FORM SCREEN  —  tạo mới hoặc sửa lớp học phần
//
//   • [lopCanSua] == null  → chế độ Tạo mới (POST /api/course-offerings)
//   • [lopCanSua] != null  → chế độ Sửa sức chứa/lịch học (PUT .../{id})
// ============================================================================

class CourseOfferingFormScreen extends StatefulWidget {
  const CourseOfferingFormScreen({
    super.key,
    this.defaultTermId,
    this.lopCanSua,
  });

  final int? defaultTermId;
  final CourseOfferingItem? lopCanSua;

  @override
  State<CourseOfferingFormScreen> createState() =>
      _CourseOfferingFormScreenState();
}

class _CourseOfferingFormScreenState extends State<CourseOfferingFormScreen> {
  final _dichVu = CourseOfferingService(authenticatedClient);

  late final TextEditingController _maCtrl;
  late final TextEditingController _monHocIdCtrl;
  late final TextEditingController _hocKyIdCtrl;
  late final TextEditingController _giangVienIdCtrl;
  late final TextEditingController _sucChuaCtrl;
  late final TextEditingController _thuCtrl;
  late final TextEditingController _gioBatDauCtrl;
  late final TextEditingController _gioKetThucCtrl;
  late final TextEditingController _phongCtrl;

  bool _dangGui = false;
  String? _loi;

  bool get _laSua => widget.lopCanSua != null;

  @override
  void initState() {
    super.initState();
    final lop = widget.lopCanSua;
    _maCtrl = TextEditingController(text: lop?.code ?? '');
    _monHocIdCtrl = TextEditingController();
    _hocKyIdCtrl = TextEditingController(
        text: widget.defaultTermId?.toString() ?? '');
    _giangVienIdCtrl = TextEditingController();
    _sucChuaCtrl = TextEditingController(text: lop?.capacity?.toString() ?? '');
    _thuCtrl = TextEditingController(text: lop?.dayOfWeek?.toString() ?? '');
    _gioBatDauCtrl = TextEditingController(
        text: lop?.startTime?.substring(0, 5) ?? '');
    _gioKetThucCtrl =
        TextEditingController(text: lop?.endTime?.substring(0, 5) ?? '');
    _phongCtrl = TextEditingController(text: lop?.room ?? '');
  }

  @override
  void dispose() {
    _maCtrl.dispose();
    _monHocIdCtrl.dispose();
    _hocKyIdCtrl.dispose();
    _giangVienIdCtrl.dispose();
    _sucChuaCtrl.dispose();
    _thuCtrl.dispose();
    _gioBatDauCtrl.dispose();
    _gioKetThucCtrl.dispose();
    _phongCtrl.dispose();
    super.dispose();
  }

  /// Chuyển "HH:mm" nhập tay → "HH:mm:00" backend cần. Trả null nếu rỗng/sai.
  String? _chuanHoaGio(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final re = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
    final m = re.firstMatch(s);
    if (m == null) return null;
    return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}:00';
  }

  Future<void> _submit() async {
    if (_dangGui) return;
    FocusScope.of(context).unfocus();

    final ma = _maCtrl.text.trim();
    final monHocId = int.tryParse(_monHocIdCtrl.text.trim());
    final hocKyId = int.tryParse(_hocKyIdCtrl.text.trim());
    final giangVienId = int.tryParse(_giangVienIdCtrl.text.trim());
    final sucChua = int.tryParse(_sucChuaCtrl.text.trim());
    final thu = int.tryParse(_thuCtrl.text.trim());
    final gioBatDauRaw = _gioBatDauCtrl.text.trim();
    final gioKetThucRaw = _gioKetThucCtrl.text.trim();
    final phong = _phongCtrl.text.trim();

    if (!_laSua && ma.isEmpty) {
      setState(() => _loi = 'Vui lòng nhập mã lớp học phần.');
      return;
    }
    if (!_laSua && (monHocId == null || hocKyId == null || giangVienId == null)) {
      setState(() => _loi = 'ID môn học / học kỳ / giảng viên không hợp lệ.');
      return;
    }
    if (thu != null && (thu < 1 || thu > 7)) {
      setState(() => _loi = 'Thứ phải từ 1 (CN) đến 7.');
      return;
    }
    String? gioBatDau, gioKetThuc;
    if (gioBatDauRaw.isNotEmpty || gioKetThucRaw.isNotEmpty) {
      gioBatDau = _chuanHoaGio(gioBatDauRaw);
      gioKetThuc = _chuanHoaGio(gioKetThucRaw);
      if (gioBatDau == null || gioKetThuc == null) {
        setState(() => _loi = 'Giờ phải theo định dạng HH:mm, VD: 07:30.');
        return;
      }
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    String? loiTuApi;

    if (_laSua) {
      final ketQua = await _dichVu.capNhat(
        widget.lopCanSua!.courseOfferingId,
        UpdateCourseOfferingRequest(
          capacity: sucChua,
          dayOfWeek: thu,
          startTime: gioBatDau,
          endTime: gioKetThuc,
          room: phong.isEmpty ? null : phong,
        ),
      );
      loiTuApi = ketQua.error;
    } else {
      final ketQua = await _dichVu.taoMoi(CreateCourseOfferingRequest(
        courseId: monHocId!,
        academicTermId: hocKyId!,
        lecturerUserId: giangVienId!,
        code: ma,
        capacity: sucChua,
        dayOfWeek: thu,
        startTime: gioBatDau,
        endTime: gioKetThuc,
        room: phong.isEmpty ? null : phong,
      ));
      loiTuApi = ketQua.error;
    }

    if (!mounted) return;

    if (loiTuApi != null) {
      setState(() {
        _dangGui = false;
        _loi = loiTuApi;
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.panel,
      appBar: AppBar(
        backgroundColor: context.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _laSua ? 'Sửa lớp học phần' : 'Thêm lớp học phần',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: context.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: context.isDark ? 0.0 : 0.03),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _laSua
                              ? 'Cập nhật lớp học phần'
                              : 'Tạo lớp học phần mới',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _laSua
                              ? 'Mã lớp, môn học, học kỳ và giảng viên không thể đổi ở đây.\n'
                                  'Dùng menu "Đổi giảng viên" trong danh sách để đổi GV.'
                              : 'Mã lớp phải duy nhất trong cùng học kỳ.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (!_laSua) ...[
                          const _FieldLabel('Mã lớp học phần'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _maCtrl,
                            icon: Icons.tag_rounded,
                            hint: 'VD: IT001_HK1_2024',
                            enabled: !_dangGui,
                            capitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('ID Môn học'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _monHocIdCtrl,
                            icon: Icons.book_rounded,
                            hint: 'VD: 1',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('ID Học kỳ'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _hocKyIdCtrl,
                            icon: Icons.calendar_month_rounded,
                            hint: 'VD: 1',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('ID Giảng viên'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _giangVienIdCtrl,
                            icon: Icons.person_rounded,
                            hint: 'VD: 4',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        const _FieldLabel('Sức chứa (không bắt buộc)'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _sucChuaCtrl,
                          icon: Icons.event_seat_rounded,
                          hint: 'VD: 40 (để trống = không giới hạn)',
                          enabled: !_dangGui,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: AppSpacing.md),
                        const _FieldLabel('Thứ học (1=CN .. 7=Thứ 7)'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _thuCtrl,
                          icon: Icons.event_rounded,
                          hint: 'VD: 2',
                          enabled: !_dangGui,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Giờ bắt đầu'),
                                  const SizedBox(height: AppSpacing.xs),
                                  _Field(
                                    controller: _gioBatDauCtrl,
                                    icon: Icons.schedule_rounded,
                                    hint: 'HH:mm',
                                    enabled: !_dangGui,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Giờ kết thúc'),
                                  const SizedBox(height: AppSpacing.xs),
                                  _Field(
                                    controller: _gioKetThucCtrl,
                                    icon: Icons.schedule_rounded,
                                    hint: 'HH:mm',
                                    enabled: !_dangGui,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),
                        const _FieldLabel('Phòng học (không bắt buộc)'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _phongCtrl,
                          icon: Icons.room_rounded,
                          hint: 'VD: P.301',
                          enabled: !_dangGui,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),

                        if (_loi != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: _loi!),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        _PrimaryButton(
                          label: _laSua ? 'Lưu thay đổi' : 'Tạo lớp',
                          loading: _dangGui,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private widgets — nhất quán với DepartmentFormScreen ─────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.text,
          ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.icon,
    required this.hint,
    this.enabled = true,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool enabled;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.faint),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textCapitalization: capitalization,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                cursorColor: AppColors.accent,
                cursorWidth: 1.6,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: context.faint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: context.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.red),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    color: context.isDark
                        ? const Color(0xFFF1B0AC)
                        : const Color(0xFFB23A33),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.loading;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (_hover && !disabled)
                ? AppColors.accentHover
                : AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: disabled
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
