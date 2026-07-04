import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/services/auth_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'widgets/submit_status_dialog.dart';

// ============================================================================
// CHANGE PASSWORD SCREEN  —  đổi mật khẩu tự phục vụ.
// POST /api/auth/change-password (chỉ tồn tại kể từ phiên này).
// ============================================================================

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _dichVu = AuthService(client: authenticatedClient);

  final _hienTaiCtrl = TextEditingController();
  final _moiCtrl = TextEditingController();
  final _xacNhanCtrl = TextEditingController();

  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _hienTaiCtrl.dispose();
    _moiCtrl.dispose();
    _xacNhanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_dangGui) return;
    FocusScope.of(context).unfocus();

    final hienTai = _hienTaiCtrl.text;
    final moi = _moiCtrl.text;
    final xacNhan = _xacNhanCtrl.text;

    if (hienTai.isEmpty || moi.isEmpty) {
      setState(() => _loi = 'Vui lòng nhập đầy đủ mật khẩu.');
      return;
    }
    if (moi.length < 6) {
      setState(() => _loi = 'Mật khẩu mới phải có ít nhất 6 ký tự.');
      return;
    }
    if (moi != xacNhan) {
      setState(() => _loi = 'Xác nhận mật khẩu mới không khớp.');
      return;
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    final thanhCong = await showSubmitStatusDialog(
      context: context,
      loadingLabel: 'Đang đổi mật khẩu...',
      successLabel: 'Đã đổi mật khẩu!',
      action: () async {
        final ketQua = await _dichVu.doiMatKhau(
          matKhauHienTai: hienTai,
          matKhauMoi: moi,
        );
        return SubmitResult(ok: ketQua.ok, message: ketQua.error);
      },
    );

    if (!mounted) return;

    if (thanhCong) {
      Navigator.pop(context);
    } else {
      setState(() => _dangGui = false);
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
        title: Text('Đổi mật khẩu',
            style: Theme.of(context).textTheme.headlineSmall),
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
                        Text('Cập nhật mật khẩu',
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Mật khẩu mới nên có ít nhất 6 ký tự.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _FieldLabel('Mật khẩu hiện tại'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _hienTaiCtrl,
                          icon: Icons.lock_outline_rounded,
                          enabled: !_dangGui,
                          obscure: true,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _FieldLabel('Mật khẩu mới'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _moiCtrl,
                          icon: Icons.lock_rounded,
                          enabled: !_dangGui,
                          obscure: true,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _FieldLabel('Xác nhận mật khẩu mới'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _xacNhanCtrl,
                          icon: Icons.lock_rounded,
                          enabled: !_dangGui,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_loi != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: _loi!),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _PrimaryButton(
                          label: 'Đổi mật khẩu',
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

// ── Private widgets — nhất quán với các form khác ─────────────────────────────

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
    this.enabled = true,
    this.obscure = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool obscure;
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
                obscureText: obscure,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                cursorColor: AppColors.accent,
                cursorWidth: 1.6,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
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
