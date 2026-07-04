import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/department.dart';
import 'package:smart_university_management_platform/data/services/department_service.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// DEPARTMENT FORM SCREEN  —  tạo mới hoặc sửa tên bộ môn
//
// Dùng chung cho 2 trường hợp:
//   • [boMonCanSua] == null  → chế độ Tạo mới (POST /api/departments)
//   • [boMonCanSua] != null  → chế độ Sửa tên (PUT /api/departments/{id})
//
// Khi hoàn thành (success), Navigator.pop(context, true) để màn hình gọi
// biết cần tải lại danh sách.
//
// Visual: card trắng trên nền panel — nhất quán với login_screen.dart.
// ============================================================================

class DepartmentFormScreen extends StatefulWidget {
  const DepartmentFormScreen({
    super.key,
    this.defaultFacultyId,
    this.boMonCanSua,
  });

  /// ID khoa cha mặc định khi tạo mới (từ màn hình list đang lọc theo khoa).
  final int? defaultFacultyId;

  /// Không null = chế độ sửa; null = chế độ tạo mới.
  final DepartmentItem? boMonCanSua;

  @override
  State<DepartmentFormScreen> createState() => _DepartmentFormScreenState();
}

class _DepartmentFormScreenState extends State<DepartmentFormScreen> {
  final _dichVu = DepartmentService(authenticatedClient);

  late final TextEditingController _tenCtrl;
  late final TextEditingController _maCtrl;
  late final TextEditingController _khoaIdCtrl;

  bool _dangGui = false;
  String? _loi;

  bool get _laSua => widget.boMonCanSua != null;

  @override
  void initState() {
    super.initState();
    final boMon = widget.boMonCanSua;
    _tenCtrl   = TextEditingController(text: boMon?.name ?? '');
    _maCtrl    = TextEditingController(text: boMon?.code ?? '');
    _khoaIdCtrl = TextEditingController(
      text: (boMon?.facultyId ?? widget.defaultFacultyId)?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _maCtrl.dispose();
    _khoaIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_dangGui) return;
    FocusScope.of(context).unfocus();

    // Validate cơ bản trước khi gọi API
    final ten   = _tenCtrl.text.trim();
    final ma    = _maCtrl.text.trim();
    final khoaId = int.tryParse(_khoaIdCtrl.text.trim());

    if (ten.isEmpty) {
      setState(() => _loi = 'Vui lòng nhập tên bộ môn.');
      return;
    }
    if (!_laSua && ma.isEmpty) {
      setState(() => _loi = 'Vui lòng nhập mã bộ môn.');
      return;
    }
    if (!_laSua && khoaId == null) {
      setState(() => _loi = 'ID khoa không hợp lệ.');
      return;
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    String? loiTuApi;

    if (_laSua) {
      final ketQua = await _dichVu.capNhat(
        widget.boMonCanSua!.departmentId,
        UpdateDepartmentRequest(name: ten),
      );
      loiTuApi = ketQua.error;
    } else {
      final ketQua = await _dichVu.taoMoi(CreateDepartmentRequest(
        facultyId: khoaId!,
        code: ma,
        name: ten,
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
      Navigator.pop(context, true); // báo list screen tải lại
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
          _laSua ? 'Sửa bộ môn' : 'Thêm bộ môn',
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
                  // ── Card ──────────────────────────────────────────────────
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
                          _laSua ? 'Cập nhật tên bộ môn' : 'Tạo bộ môn mới',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _laSua
                              ? 'Mã bộ môn không thể thay đổi sau khi tạo.'
                              : 'Mã bộ môn phải duy nhất trong cùng một khoa.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Trường Tên
                        const _FieldLabel('Tên bộ môn'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _tenCtrl,
                          icon: Icons.account_balance_rounded,
                          hint: 'VD: Bộ môn Kỹ thuật Phần mềm',
                          enabled: !_dangGui,
                          textInputAction: _laSua
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onSubmitted: _laSua ? (_) => _submit() : null,
                        ),

                        // Trường Mã — chỉ hiện khi tạo mới
                        if (!_laSua) ...[
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('Mã bộ môn'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _maCtrl,
                            icon: Icons.tag_rounded,
                            hint: 'VD: KTPM',
                            enabled: !_dangGui,
                            capitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                          ),
                        ],

                        // Trường Faculty ID — chỉ hiện khi tạo mới
                        if (!_laSua) ...[
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('ID Khoa'),
                          const SizedBox(height: AppSpacing.xs),
                          _Field(
                            controller: _khoaIdCtrl,
                            icon: Icons.corporate_fare_rounded,
                            hint: 'VD: 1',
                            enabled: !_dangGui,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                        ],

                        // Error banner
                        if (_loi != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: _loi!),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        _PrimaryButton(
                          label: _laSua ? 'Lưu thay đổi' : 'Tạo bộ môn',
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

// ── Private widgets — nhất quán với login_screen.dart ────────────────────────

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
      onExit:  (_) => setState(() => _hover = false),
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
