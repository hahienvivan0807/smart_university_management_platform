import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/academic_term.dart';
import 'package:smart_university_management_platform/data/services/academic_term_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'academic_term_form_screen.dart';
import 'course_offering_list_screen.dart';

// ============================================================================
// ACADEMIC TERM LIST SCREEN  —  danh sách học kỳ, tap → xem lớp HP
//
// Tab 2 "Học kỳ & Lớp HP" trong AppShell.
//   AcademicTermListScreen  →  (tap)  →  CourseOfferingListScreen(termId)
//
// Mỗi học kỳ hiển thị: nhãn (HK1 2024-2025), loại kỳ, ngày bắt đầu-kết thúc.
// Lifecycle: nằm trong IndexedStack, initState() chỉ chạy 1 lần.
// ============================================================================

class AcademicTermListScreen extends StatefulWidget {
  const AcademicTermListScreen({super.key, this.laManHinhDoc = false});

  /// true = màn này được `Navigator.push` như 1 màn độc lập (từ Admin
  /// Dashboard) → cần AppBar + nút quay về riêng. false (mặc định) = nhúng
  /// trong tab AppShell, AppShell đã có AppBar rồi.
  final bool laManHinhDoc;

  @override
  State<AcademicTermListScreen> createState() => _AcademicTermListScreenState();
}

class _AcademicTermListScreenState extends State<AcademicTermListScreen> {
  final _dichVu = AcademicTermService(authenticatedClient);

  List<AcademicTermItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  bool get _coQuyenGhi {
    final roles = session.roles;
    return roles.contains('Admin') || roles.contains('AcademicOffice');
  }

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

    final ketQua = await _dichVu.layDanhSach();

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data?.items ?? [];
      _loi = ketQua.error;
    });
  }

  Future<void> _moForm({AcademicTermItem? ky}) async {
    final daThayDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AcademicTermFormScreen(kyCanSua: ky)),
    );
    if (daThayDoi == true) _taiDanhSach();
  }

  void _xemLopHP(AcademicTermItem ky) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseOfferingListScreen(
          termId: ky.academicTermId,
          termLabel: ky.label,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: widget.laManHinhDoc
          ? AppBar(
              backgroundColor: context.canvas,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text('Học kỳ',
                  style: Theme.of(context).textTheme.headlineSmall),
            )
          : null,
      floatingActionButton: _coQuyenGhi
          ? FloatingActionButton.extended(
              heroTag: 'academic_term_list_fab',
              onPressed: () => _moForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm học kỳ'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 2,
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_dangTai) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDanhSach);
    }

    if (_danhSach.isEmpty) {
      return Center(
        child: Text('Chưa có học kỳ nào.',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiDanhSach,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _danhSach.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => _HocKyTile(
          ky: _danhSach[i],
          coQuyenGhi: _coQuyenGhi,
          onTap: () => _xemLopHP(_danhSach[i]),
          onSua: () => _moForm(ky: _danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _HocKyTile extends StatelessWidget {
  const _HocKyTile({
    required this.ky,
    required this.coQuyenGhi,
    required this.onTap,
    required this.onSua,
  });

  final AcademicTermItem ky;
  final bool coQuyenGhi;
  final VoidCallback onTap;
  final VoidCallback onSua;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: context.isDark ? 0.0 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: AppColors.accent, size: 20),
          ),
          title: Text(
            ky.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${ky.termTypeName} · ${_formatDate(ky.startDate)} – ${_formatDate(ky.endDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          trailing: coQuyenGhi
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded,
                          size: 18, color: context.text),
                      tooltip: 'Sửa',
                      onPressed: onSua,
                    ),
                    Icon(Icons.chevron_right_rounded, color: context.faint),
                  ],
                )
              : Icon(Icons.chevron_right_rounded, color: context.faint),
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
