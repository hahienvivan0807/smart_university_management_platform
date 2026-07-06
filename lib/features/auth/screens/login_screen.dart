import 'package:flutter/material.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';
import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/login_response.dart';
import 'package:smart_university_management_platform/data/services/auth_service.dart';
import 'package:smart_university_management_platform/features/academic/app_shell.dart';
import 'package:smart_university_management_platform/features/auth/screens/role_picker_screen.dart';
import 'package:smart_university_management_platform/main.dart';


// ============================================================================
// LOGIN SCREEN  —  centered card on a soft canvas
//
// Visually identical to the original FE prototype. The difference is that it
// is now *functional*: the two fields are backed by controllers, the button
// calls AuthService.login(), tokens are stored securely on success, and a
// friendly inline error is shown on failure.
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService, this.selectedRole});

  /// Injectable for testing; defaults to a real service.
  final AuthService? authService;

  /// Display-only hint from the role-selection screen. NEVER sent to the API
  /// or used for authorization — the JWT's real roles decide that.
  final AppRole? selectedRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _auth =
      widget.authService ?? AuthService(storage: tokenStorage);

  final _loginCodeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _remember = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _loginCodeCtrl.dispose();
    _passwordCtrl.dispose();
    // Only dispose the service if we created it ourselves.
    if (widget.authService == null) _auth.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await _auth.login(
      loginCode: _loginCodeCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      _routeAfterLogin(result.data!);
    } else {
      setState(() {
        _submitting = false;
        _error = result.error;
      });
    }
  }

  void _routeAfterLogin(LoginResponse data) {
    session.login(data, loginCode: _loginCodeCtrl.text);

    final Widget next = data.requiresRoleSelection
        ? RolePickerScreen(roles: data.roles)
        : AppShell(activeRole: AppRole.fromBackendId(data.roles.first));

    Navigator.of(context).pushReplacement(_fade(next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.panel,
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
                  // Brand lockup.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Logo(size: 30),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Smart University',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (widget.selectedRole != null) ...[
                    _RoleHint(role: widget.selectedRole!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // The card.
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
                        Text('Đăng Nhập',
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Chào mừng trở lại. Vui lòng sử dụng tài khoản nhà trường để tiếp tục.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        _FieldLabel('Login Code'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _loginCodeCtrl,
                          icon: Icons.badge_outlined,
                          hint: 'e.g. DH21IT01',
                          enabled: !_submitting,
                          capitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        _FieldLabel('Password'),
                        const SizedBox(height: AppSpacing.xs),
                        _Field(
                          controller: _passwordCtrl,
                          icon: Icons.lock_outline_rounded,
                          hint: 'Enter your password',
                          obscure: _obscure,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          trailing: _RevealButton(
                            obscured: _obscure,
                            onTap: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Remember(
                              value: _remember,
                              onChanged: (v) => setState(() => _remember = v),
                            ),
                            _TextLink('Forgot password?', onTap: () {}),
                          ],
                        ),

                        // Inline error banner — only present on failure.
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: _error!),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        _PrimaryButton(
                          label: 'Đăng Nhập',
                          loading: _submitting,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const _AccountNotice(),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '© 2026 Smart Campus Platform · Chính sách bảo mật · Điều khoản sử dụng',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
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

// ----------------------------------------------------------------------------
// Login components
// ----------------------------------------------------------------------------

class _Logo extends StatelessWidget {
  const _Logo({this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E6ADE), AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.6),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w500, color: context.text));
  }
}

/// Now backed by a [controller] and supports [enabled] + submit handling.
class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.hint,
    this.controller,
    this.obscure = false,
    this.trailing,
    this.enabled = true,
    this.capitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
  });

  final IconData icon;
  final String hint;
  final TextEditingController? controller;
  final bool obscure;
  final Widget? trailing;
  final bool enabled;
  final TextCapitalization capitalization;
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
                textCapitalization: capitalization,
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
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.obscured, required this.onTap});
  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 18,
        color: context.faint,
      ),
    );
  }
}

class _Remember extends StatelessWidget {
  const _Remember({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              color: value ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: value ? AppColors.accent : context.border,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text('Remember me', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(label,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          )),
    );
  }
}

/// Friendly, theme-aware error banner shown on failed login.
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

/// Same look as the original; gains a [loading] state (spinner + disabled).
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
      cursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
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
          child: widget.loading
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

class _AccountNotice extends StatelessWidget {
  const _AccountNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: context.faint),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              'Tài khoản được cấp bởi trường của bạn. Vui lòng liên hệ với bộ phận học thuật.'
              'Office for access.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------

PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );
//-----------------------------------------------------------------------------
class _RoleHint extends StatelessWidget {
  const _RoleHint({required this.role});
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(role.icon, size: 15, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            'Đăng nhập với tư cách ${role.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('· Change',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: context.faint)),
        ],
      ),
    );
  }
}