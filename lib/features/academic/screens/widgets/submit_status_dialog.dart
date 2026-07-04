import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';

// ============================================================================
// SUBMIT STATUS DIALOG  —  dialog phản hồi dùng chung cho mọi form CRUD
// trong hệ thống quản trị (Thêm khoa, Thêm ngành, ...).
//
// Luồng: mở dialog không tắt tay được → chạy [action] → xoay tròn trong
// lúc chờ → thành công: dấu tick xanh rồi tự đóng; trùng dữ liệu: dấu !
// cam; lỗi khác (mạng/server): dấu X đỏ, có nút "Đóng" để quay lại form.
// ============================================================================

/// Kết quả 1 thao tác submit — dùng cho [showSubmitStatusDialog].
class SubmitResult {
  const SubmitResult({required this.ok, this.isConflict = false, this.message});

  /// true = thành công.
  final bool ok;

  /// Chỉ có ý nghĩa khi [ok] == false. true = lỗi trùng dữ liệu (409) →
  /// hiện dấu !; false = lỗi khác (validate/mạng/server) → hiện dấu X.
  final bool isConflict;

  /// Thông báo hiện khi thất bại.
  final String? message;
}

enum _TrangThai { dangXuLy, thanhCong, trungLap, loi }

/// Hiện dialog trạng thái trong lúc [action] chạy. Trả về true nếu thành
/// công (màn gọi nên `Navigator.pop` luôn); false nếu thất bại (ở lại form).
Future<bool> showSubmitStatusDialog({
  required BuildContext context,
  required String loadingLabel,
  required String successLabel,
  required Future<SubmitResult> Function() action,
}) async {
  final ketQua = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SubmitStatusDialog(
      loadingLabel: loadingLabel,
      successLabel: successLabel,
      action: action,
    ),
  );
  return ketQua ?? false;
}

class _SubmitStatusDialog extends StatefulWidget {
  const _SubmitStatusDialog({
    required this.loadingLabel,
    required this.successLabel,
    required this.action,
  });

  final String loadingLabel;
  final String successLabel;
  final Future<SubmitResult> Function() action;

  @override
  State<_SubmitStatusDialog> createState() => _SubmitStatusDialogState();
}

class _SubmitStatusDialogState extends State<_SubmitStatusDialog> {
  _TrangThai _trangThai = _TrangThai.dangXuLy;
  String? _thongBao;

  @override
  void initState() {
    super.initState();
    _chay();
  }

  Future<void> _chay() async {
    final ketQua = await widget.action();
    if (!mounted) return;

    if (ketQua.ok) {
      setState(() => _trangThai = _TrangThai.thanhCong);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _trangThai = ketQua.isConflict ? _TrangThai.trungLap : _TrangThai.loi;
        _thongBao = ketQua.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coTheDong = _trangThai != _TrangThai.dangXuLy;

    return PopScope(
      canPop: coTheDong,
      child: Dialog(
        backgroundColor: context.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _buildIcon(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _label(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_trangThai != _TrangThai.dangXuLy &&
                  _trangThai != _TrangThai.thanhCong &&
                  _thongBao != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _thongBao!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (coTheDong && _trangThai != _TrangThai.thanhCong) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (_trangThai) {
      case _TrangThai.dangXuLy:
        return const SizedBox(
          key: ValueKey('loading'),
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case _TrangThai.thanhCong:
        return const Icon(
          Icons.check_circle_rounded,
          key: ValueKey('ok'),
          color: Color(0xFF16A34A),
          size: 56,
        );
      case _TrangThai.trungLap:
        return const Icon(
          Icons.error_rounded,
          key: ValueKey('conflict'),
          color: Color(0xFFF59E0B),
          size: 56,
        );
      case _TrangThai.loi:
        return const Icon(
          Icons.cancel_rounded,
          key: ValueKey('error'),
          color: AppColors.red,
          size: 56,
        );
    }
  }

  String _label() {
    switch (_trangThai) {
      case _TrangThai.dangXuLy:
        return widget.loadingLabel;
      case _TrangThai.thanhCong:
        return widget.successLabel;
      case _TrangThai.trungLap:
        return 'Dữ liệu bị trùng';
      case _TrangThai.loi:
        return 'Đã xảy ra lỗi';
    }
  }
}
