import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/main.dart';

/// Danh sách sinh viên đã đăng ký một lớp học phần — dành cho giảng viên / staff.
class RosterScreen extends StatefulWidget {
  const RosterScreen({
    super.key,
    required this.courseOfferingId,
    required this.offeringCode,
  });

  final int courseOfferingId;
  final String offeringCode;

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _dichVu = EnrollmentService(authenticatedClient);

  List<RosterItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiDanhSach();
  }

  Future<void> _taiDanhSach() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final ketQua = await _dichVu.layRoster(widget.courseOfferingId);
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data ?? [];
      _loi = ketQua.error;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danh sách sinh viên',
                style: Theme.of(context).textTheme.headlineSmall),
            Text(
              widget.offeringCode,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11.5, color: context.muted),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDanhSach);
    }

    if (_danhSach.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.people_outline_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Chưa có sinh viên đăng ký.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header tổng số
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Row(
            children: [
              Icon(Icons.people_rounded, size: 14, color: context.muted),
              const SizedBox(width: 4),
              Text(
                '${_danhSach.length} sinh viên',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _taiDanhSach,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _danhSach.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (_, i) => _SinhVienTile(
                sinhVien: _danhSach[i],
                soThuTu: i + 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tile một sinh viên ────────────────────────────────────────────────────────

class _SinhVienTile extends StatelessWidget {
  const _SinhVienTile({required this.sinhVien, required this.soThuTu});

  final RosterItem sinhVien;
  final int soThuTu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            // Số thứ tự
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                '$soThuTu',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Thông tin sinh viên
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sinhVien.fullName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        sinhVien.loginCode,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                      if (sinhVien.adminClassName.isNotEmpty) ...[
                        Text(' · ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontSize: 12, color: context.muted)),
                        Text(
                          sinhVien.adminClassName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12, color: context.muted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.red
                    .withValues(alpha: context.isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border:
                    Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
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
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
