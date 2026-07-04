import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/academic_term.dart';
import 'package:smart_university_management_platform/data/services/academic_term_service.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// ACADEMIC TERM FORM SCREEN  —  tạo mới hoặc sửa học kỳ
//
//   • [kyCanSua] == null  → chế độ Tạo mới (POST /api/academic-terms)
//   • [kyCanSua] != null  → chế độ Sửa (PUT /api/academic-terms/{id})
//   AcademicYear/TermNumber không sửa được sau khi tạo (per backend).
// ============================================================================

class AcademicTermFormScreen extends StatefulWidget {
  const AcademicTermFormScreen({super.key, this.kyCanSua});

  final AcademicTermItem? kyCanSua;

  @override
  State<AcademicTermFormScreen> createState() =>
      _AcademicTermFormScreenState();
}

class _AcademicTermFormScreenState extends State<AcademicTermFormScreen> {
  final _dichVu = AcademicTermService(authenticatedClient);

  late final TextEditingController _namHocCtrl;
  late final TextEditingController _hocKyCtrl;
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;
  int _loaiKy = 1; // 1 = Học kỳ chính, 2 = Học kỳ hè

  bool _dangGui = false;
  String? _loi;

  bool get _laSua => widget.kyCanSua != null;

  @override
  void initState() {
    super.initState();
    final ky = widget.kyCanSua;
    _namHocCtrl = TextEditingController(text: ky?.academicYear.toString() ?? '');
    _hocKyCtrl = TextEditingController(text: ky?.termNumber.toString() ?? '');
    _ngayBatDau = ky?.startDate;
    _ngayKetThuc = ky?.endDate;
    _loaiKy = ky?.termTypeName == 'Học kỳ hè' ? 2 : 1;
  }

  @override
  void dispose() {
    _namHocCtrl.dispose();
    _hocKyCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) => d == null
      ? 'Chọn ngày'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _chonNgay({required bool laNgayBatDau}) async {
    final chon = await showDatePicker(
      context: context,
      initialDate:
          (laNgayBatDau ? _ngayBatDau : _ngayKetThuc) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (chon == null) return;
    setState(() {
      if (laNgayBatDau) {
        _ngayBatDau = chon;
      } else {
        _ngayKetThuc = chon;
      }
    });
  }

  Future<void> _submit() async {
    if (_dangGui) return;
    FocusScope.of(context).unfocus();

    final namHoc = int.tryParse(_namHocCtrl.text.trim());
    final hocKy = int.tryParse(_hocKyCtrl.text.trim());

    if (!_laSua && namHoc == null) {
      setState(() => _loi = 'Năm học không hợp lệ.');
      return;
    }
    if (!_laSua && (hocKy == null || hocKy < 1 || hocKy > 3)) {
      setState(() => _loi = 'Học kỳ phải là 1, 2 hoặc 3 (hè).');
      return;
    }
    if (_ngayBatDau == null || _ngayKetThuc == null) {
      setState(() => _loi = 'Vui lòng chọn ngày bắt đầu và kết thúc.');
      return;
    }
    if (!_ngayBatDau!.isBefore(_ngayKetThuc!)) {
      setState(() => _loi = 'Ngày bắt đầu phải trước ngày kết thúc.');
      return;
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    String? loiTuApi;

    if (_laSua) {
      final ketQua = await _dichVu.capNhat(
        widget.kyCanSua!.academicTermId,
        UpdateAcademicTermRequest(
          startDate: _ngayBatDau!,
          endDate: _ngayKetThuc!,
          termType: _loaiKy,
        ),
      );
      loiTuApi = ketQua.error;
    } else {
      final ketQua = await _dichVu.taoMoi(CreateAcademicTermRequest(
        academicYear: namHoc!,
        termNumber: hocKy!,
        termType: _loaiKy,
        startDate: _ngayBatDau!,
        endDate: _ngayKetThuc!,
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
          _laSua ? 'Sửa học kỳ' : 'Thêm học kỳ',
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
                          _laSua ? 'Cập nhật học kỳ' : 'Tạo học kỳ mới',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _laSua
                              ? 'Năm học và số thứ tự kỳ không thể thay đổi.'
                              : 'Năm học + số thứ tự kỳ phải là duy nhất.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (!_laSua) ...[
                          const _FieldLabel('Năm học (VD: 2024 = 2024-2025)'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _namHocCtrl,
                            icon: Icons.event_rounded,
                            hint: 'VD: 2024',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('Học kỳ (1, 2, hoặc 3 = hè)'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _hocKyCtrl,
                            icon: Icons.filter_1_rounded,
                            hint: 'VD: 1',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        const _FieldLabel('Loại kỳ'),
                        const SizedBox(height: AppSpacing.xs),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('Chính')),
                            ButtonSegment(value: 2, label: Text('Hè')),
                          ],
                          selected: {_loaiKy},
                          onSelectionChanged: _dangGui
                              ? null
                              : (s) => setState(() => _loaiKy = s.first),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('Ngày bắt đầu'),
                        const SizedBox(height: AppSpacing.xs),
                        _DateField(
                          label: _formatDate(_ngayBatDau),
                          enabled: !_dangGui,
                          onTap: () => _chonNgay(laNgayBatDau: true),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _FieldLabel('Ngày kết thúc'),
                        const SizedBox(height: AppSpacing.xs),
                        _DateField(
                          label: _formatDate(_ngayKetThuc),
                          enabled: !_dangGui,
                          onTap: () => _chonNgay(laNgayBatDau: false),
                        ),

                        if (_loi != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: _loi!),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        _PrimaryButton(
                          label: _laSua ? 'Lưu thay đổi' : 'Tạo học kỳ',
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

// ── Private widgets ───────────────────────────────────────────────────────────

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
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool enabled;
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
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
              Icon(Icons.calendar_today_rounded, size: 16, color: context.faint),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
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
