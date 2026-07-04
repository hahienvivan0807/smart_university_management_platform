import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/admin_class.dart';
import 'package:smart_university_management_platform/data/services/admin_class_service.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// ADMIN CLASS FORM SCREEN  —  tạo mới hoặc sửa lớp hành chính
//
//   • [lopCanSua] == null  → chế độ Tạo mới (POST /api/admin-classes)
//   • [lopCanSua] != null  → chế độ Sửa (PUT /api/admin-classes/{id})
// ============================================================================

class AdminClassFormScreen extends StatefulWidget {
  const AdminClassFormScreen({
    super.key,
    this.defaultProgramId,
    this.lopCanSua,
  });

  final int? defaultProgramId;
  final AdminClassItem? lopCanSua;

  @override
  State<AdminClassFormScreen> createState() => _AdminClassFormScreenState();
}

class _AdminClassFormScreenState extends State<AdminClassFormScreen> {
  final _dichVu = AdminClassService(authenticatedClient);

  late final TextEditingController _tenCtrl;
  late final TextEditingController _maCtrl;
  late final TextEditingController _ctIdCtrl;
  late final TextEditingController _khoaHocCtrl;
  late final TextEditingController _coVanIdCtrl;

  bool _dangGui = false;
  String? _loi;

  bool get _laSua => widget.lopCanSua != null;

  @override
  void initState() {
    super.initState();
    final lop = widget.lopCanSua;
    _tenCtrl = TextEditingController(text: lop?.name ?? '');
    _maCtrl = TextEditingController(text: lop?.code ?? '');
    _ctIdCtrl = TextEditingController(
      text: (lop?.programId ?? widget.defaultProgramId)?.toString() ?? '',
    );
    _khoaHocCtrl =
        TextEditingController(text: lop?.intakeYear.toString() ?? '');
    _coVanIdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _maCtrl.dispose();
    _ctIdCtrl.dispose();
    _khoaHocCtrl.dispose();
    _coVanIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_dangGui) return;
    FocusScope.of(context).unfocus();

    final ten = _tenCtrl.text.trim();
    final ma = _maCtrl.text.trim();
    final ctId = int.tryParse(_ctIdCtrl.text.trim());
    final khoaHoc = int.tryParse(_khoaHocCtrl.text.trim());
    final coVanId = int.tryParse(_coVanIdCtrl.text.trim());

    if (!_laSua && ma.isEmpty) {
      setState(() => _loi = 'Vui lòng nhập mã lớp.');
      return;
    }
    if (!_laSua && ctId == null) {
      setState(() => _loi = 'ID chương trình không hợp lệ.');
      return;
    }
    if (!_laSua && khoaHoc == null) {
      setState(() => _loi = 'Khóa nhập học không hợp lệ.');
      return;
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    String? loiTuApi;

    if (_laSua) {
      final ketQua = await _dichVu.capNhat(
        widget.lopCanSua!.adminClassId,
        UpdateAdminClassRequest(
          name: ten.isEmpty ? null : ten,
          advisorUserId: coVanId,
        ),
      );
      loiTuApi = ketQua.error;
    } else {
      final ketQua = await _dichVu.taoMoi(CreateAdminClassRequest(
        programId: ctId!,
        code: ma,
        name: ten.isEmpty ? null : ten,
        intakeYear: khoaHoc!,
        advisorUserId: coVanId,
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
          _laSua ? 'Sửa lớp hành chính' : 'Thêm lớp hành chính',
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
                              ? 'Cập nhật lớp hành chính'
                              : 'Tạo lớp hành chính mới',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _laSua
                              ? 'Mã lớp, chương trình và khóa không thể thay đổi.'
                              : 'Mã lớp phải duy nhất trong cùng chương trình.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        const _FieldLabel('Tên lớp (không bắt buộc)'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _tenCtrl,
                          icon: Icons.groups_rounded,
                          hint: 'VD: KTPM 2023 A',
                          enabled: !_dangGui,
                          textInputAction: TextInputAction.next,
                        ),

                        if (!_laSua) ...[
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('Mã lớp'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _maCtrl,
                            icon: Icons.tag_rounded,
                            hint: 'VD: KTPM2023A',
                            enabled: !_dangGui,
                            capitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('ID Chương trình đào tạo'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _ctIdCtrl,
                            icon: Icons.menu_book_rounded,
                            hint: 'VD: 1',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('Khóa nhập học'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _khoaHocCtrl,
                            icon: Icons.event_rounded,
                            hint: 'VD: 2023',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ],

                        const SizedBox(height: AppSpacing.md),
                        const _FieldLabel('ID Cố vấn học tập (không bắt buộc)'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _coVanIdCtrl,
                          icon: Icons.person_rounded,
                          hint: 'VD: 4',
                          enabled: !_dangGui,
                          keyboardType: TextInputType.number,
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
