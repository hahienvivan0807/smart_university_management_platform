import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/course_offering.dart';
import 'package:smart_university_management_platform/data/services/attendance_service.dart';
import 'package:smart_university_management_platform/data/services/course_offering_service.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'attendance_session_screen.dart';
import 'course_offering_form_screen.dart';
import 'document_list_screen.dart';
import 'my_enrollments_screen.dart';
import 'roster_screen.dart';

class CourseOfferingListScreen extends StatefulWidget {
  const CourseOfferingListScreen({
    super.key,
    this.termId,
    this.termLabel,
    this.laManHinhDoc = false,
  });

  final int? termId;
  final String? termLabel;

  /// true = ép hiện AppBar + nút quay về dù không có [termId] (VD: push từ
  /// Admin Dashboard xem tất cả lớp HP mọi học kỳ). Bình thường AppBar đã
  /// tự hiện khi có [termId] (drill-down từ AcademicTermListScreen).
  final bool laManHinhDoc;

  @override
  State<CourseOfferingListScreen> createState() =>
      _CourseOfferingListScreenState();
}

class _CourseOfferingListScreenState extends State<CourseOfferingListScreen> {
  final _dichVu = CourseOfferingService(authenticatedClient);
  final _enrollService = EnrollmentService(authenticatedClient);
  final _attendanceSv = AttendanceService(authenticatedClient);

  List<CourseOfferingItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  bool get _laSinhVien => session.roles.contains('Student');
  bool get _laGiangVien => session.roles.contains('Lecturer');
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

    final ketQua = await _dichVu.layDanhSach(termId: widget.termId);

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data?.items ?? [];
      _loi = ketQua.error;
    });
  }

  Future<void> _moDiemDanh(CourseOfferingItem lopHP) async {
    double? lat, lng;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 5));
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    if (!mounted) return;

    final kq = await _attendanceSv.moBuoi(
      lopHP.courseOfferingId,
      lat: lat,
      lng: lng,
    );

    if (!mounted) return;
    if (kq.error != null) {
      _showSnackBar(kq.error!, isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceSessionScreen(
          session: kq.data!,
          offeringCode: lopHP.code,
        ),
      ),
    );
  }

  void _xemTaiLieu(CourseOfferingItem lopHP) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentListScreen(
          courseOfferingId: lopHP.courseOfferingId,
          tieuDe: 'Tài liệu — ${lopHP.code}',
          coTheTaiLen: _laGiangVien || _coQuyenGhi,
        ),
      ),
    );
  }

  void _xemRoster(CourseOfferingItem lopHP) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RosterScreen(
          courseOfferingId: lopHP.courseOfferingId,
          offeringCode: lopHP.code,
        ),
      ),
    );
  }

  Future<void> _dangKy(CourseOfferingItem lopHP) async {
    final ketQua = await _enrollService.dangKy(lopHP.courseOfferingId);

    if (!mounted) return;
    if (ketQua.error != null) {
      _showSnackBar(ketQua.error!, isError: true);
      return;
    }

    _showSnackBar('Đăng ký "${lopHP.courseName}" thành công!');
    _taiDanhSach(); // reload để cập nhật SeatsTaken
  }

  Future<void> _moForm({CourseOfferingItem? lop}) async {
    final daThayDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CourseOfferingFormScreen(
          defaultTermId: widget.termId,
          lopCanSua: lop,
        ),
      ),
    );
    if (daThayDoi == true) _taiDanhSach();
  }

  Future<void> _huyLop(CourseOfferingItem lop) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Hủy lớp học phần',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text('Lớp "${lop.code}" sẽ bị hủy.',
            style: Theme.of(ctx).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Hủy lớp'),
          ),
        ],
      ),
    );

    if (dongY != true || !mounted) return;

    final ketQua = await _dichVu.huyLop(lop.courseOfferingId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ketQua.ok ? 'Đã hủy lớp học phần.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
  }

  Future<void> _doiGiangVien(CourseOfferingItem lop) async {
    final giangVienIdCtrl = TextEditingController();

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Đổi giảng viên — ${lop.code}',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: TextField(
          controller: giangVienIdCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'ID Giảng viên mới'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );

    if (xacNhan != true || !mounted) return;

    final lecturerUserId = int.tryParse(giangVienIdCtrl.text.trim());
    if (lecturerUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID giảng viên không hợp lệ.')),
      );
      return;
    }

    final ketQua =
        await _dichVu.doiGiangVien(lop.courseOfferingId, lecturerUserId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ketQua.ok ? 'Đã đổi giảng viên.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool laManhinhDoc = widget.termId != null || widget.laManHinhDoc;
    final body = _buildBody();

    if (!laManhinhDoc) {
      return Scaffold(
        backgroundColor: context.canvas,
        floatingActionButton: _buildFab(),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: context.canvas,
      floatingActionButton: _buildFab(),
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.termLabel ?? 'Lớp học phần',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          if (_laSinhVien)
            IconButton(
              tooltip: 'Đăng ký của tôi',
              icon: const Icon(Icons.checklist_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyEnrollmentsScreen(
                    termId: widget.termId!,
                    termLabel: widget.termLabel ?? 'Học kỳ',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget? _buildFab() {
    if (!_coQuyenGhi) return null;
    return FloatingActionButton.extended(
      heroTag: 'course_offering_list_fab',
      onPressed: () => _moForm(),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Thêm lớp HP'),
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 2,
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
                child: const Icon(Icons.class_outlined,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Chưa có lớp học phần nào.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiDanhSach,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          _coQuyenGhi ? AppSpacing.xl + 56 : AppSpacing.md,
        ),
        itemCount: _danhSach.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => _LopHPTile(
          lopHP: _danhSach[i],
          laSinhVien: _laSinhVien,
          laGiangVien: _laGiangVien,
          coQuyenGhi: _coQuyenGhi,
          onDangKy: () => _dangKy(_danhSach[i]),
          onXemRoster: () => _xemRoster(_danhSach[i]),
          onMoDiemDanh: () => _moDiemDanh(_danhSach[i]),
          onXemTaiLieu: () => _xemTaiLieu(_danhSach[i]),
          onSua: () => _moForm(lop: _danhSach[i]),
          onHuyLop: () => _huyLop(_danhSach[i]),
          onDoiGiangVien: () => _doiGiangVien(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _LopHPTile extends StatefulWidget {
  const _LopHPTile({
    required this.lopHP,
    required this.laSinhVien,
    required this.laGiangVien,
    required this.coQuyenGhi,
    required this.onDangKy,
    required this.onXemRoster,
    required this.onMoDiemDanh,
    required this.onXemTaiLieu,
    required this.onSua,
    required this.onHuyLop,
    required this.onDoiGiangVien,
  });

  final CourseOfferingItem lopHP;
  final bool laSinhVien;
  final bool laGiangVien;
  final bool coQuyenGhi;
  final VoidCallback onDangKy;
  final VoidCallback onXemRoster;
  final VoidCallback onMoDiemDanh;
  final VoidCallback onXemTaiLieu;
  final VoidCallback onSua;
  final VoidCallback onHuyLop;
  final VoidCallback onDoiGiangVien;

  @override
  State<_LopHPTile> createState() => _LopHPTileState();
}

class _LopHPTileState extends State<_LopHPTile> {
  bool _dangXuLy = false;

  Future<void> _xuLyDangKy() async {
    setState(() => _dangXuLy = true);
    widget.onDangKy();
    if (mounted) setState(() => _dangXuLy = false);
  }

  @override
  Widget build(BuildContext context) {
    final lopHP = widget.lopHP;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hàng trên: badge TC + info + status ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CreditsBadge(credits: lopHP.courseCredits),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lopHP.courseName,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '${lopHP.code} · ${lopHP.courseCode}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12.5),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 13, color: context.muted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              lopHP.lecturerName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Tài liệu',
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: widget.onXemTaiLieu,
                        ),
                        const SizedBox(width: 4),
                        _TrangThaiBadge(dangMo: lopHP.dangMo),
                        if (widget.coQuyenGhi)
                          _ActionMenu(
                            onSua: widget.onSua,
                            onHuyLop: lopHP.dangMo ? widget.onHuyLop : null,
                            onDoiGiangVien: widget.onDoiGiangVien,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ChoConLai(lopHP: lopHP),
                  ],
                ),
              ],
            ),

            // ── Nút đăng ký — chỉ hiện với sinh viên ─────────────────────
            if (widget.laSinhVien) ...[
              const SizedBox(height: AppSpacing.sm + 2),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: _dangXuLy
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ElevatedButton(
                        onPressed:
                            lopHP.dangMo && lopHP.conCho ? _xuLyDangKy : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor:
                              context.border,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          lopHP.conCho ? 'Đăng ký' : 'Hết chỗ',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: lopHP.conCho
                                    ? Colors.white
                                    : context.muted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
              ),
            ],

            // ── Nút GV: xem roster + mở điểm danh ────────────────────────
            if (widget.laGiangVien) ...[
              const SizedBox(height: AppSpacing.sm + 2),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: FilledButton.icon(
                        onPressed: widget.onMoDiemDanh,
                        icon: const Icon(Icons.qr_code_rounded, size: 15),
                        label: const Text('Mở điểm danh'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          textStyle: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: widget.onXemRoster,
                        icon: const Icon(Icons.people_outline_rounded,
                            size: 15),
                        label: const Text('Danh sách SV'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          padding: EdgeInsets.zero,
                          textStyle: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Badge tín chỉ ─────────────────────────────────────────────────────────────

class _CreditsBadge extends StatelessWidget {
  const _CreditsBadge({required this.credits});
  final int credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$credits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
          ),
          Text(
            'TC',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Action menu (3-dot) — staff only ─────────────────────────────────────────

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.onSua,
    required this.onHuyLop,
    required this.onDoiGiangVien,
  });

  final VoidCallback onSua;
  final VoidCallback? onHuyLop;
  final VoidCallback onDoiGiangVien;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, size: 18, color: context.muted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: context.border),
      ),
      color: context.canvas,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MenuAction.sua,
          child: Row(children: [
            Icon(Icons.edit_rounded, size: 17, color: context.text),
            const SizedBox(width: AppSpacing.sm),
            Text('Sửa sức chứa/lịch', style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
        PopupMenuItem(
          value: _MenuAction.doiGiangVien,
          child: Row(children: [
            Icon(Icons.swap_horiz_rounded, size: 17, color: context.text),
            const SizedBox(width: AppSpacing.sm),
            Text('Đổi giảng viên', style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
        PopupMenuItem(
          enabled: onHuyLop != null,
          value: _MenuAction.huyLop,
          child: Row(children: [
            Icon(Icons.cancel_rounded,
                size: 17,
                color: onHuyLop != null ? AppColors.red : context.faint),
            const SizedBox(width: AppSpacing.sm),
            Text('Hủy lớp',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: onHuyLop != null ? AppColors.red : context.faint)),
          ]),
        ),
      ],
      onSelected: (a) {
        if (a == _MenuAction.sua) onSua();
        if (a == _MenuAction.doiGiangVien) onDoiGiangVien();
        if (a == _MenuAction.huyLop) onHuyLop?.call();
      },
    );
  }
}

enum _MenuAction { sua, doiGiangVien, huyLop }

// ── Trạng thái lớp HP ─────────────────────────────────────────────────────────

class _TrangThaiBadge extends StatelessWidget {
  const _TrangThaiBadge({required this.dangMo});
  final bool dangMo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: dangMo
            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
            : AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        dangMo ? 'Đang mở' : 'Đã hủy',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: dangMo ? const Color(0xFF16A34A) : AppColors.red,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

// ── Số chỗ còn lại ────────────────────────────────────────────────────────────

class _ChoConLai extends StatelessWidget {
  const _ChoConLai({required this.lopHP});
  final CourseOfferingItem lopHP;

  @override
  Widget build(BuildContext context) {
    final soChoHienThi = lopHP.capacity == null
        ? '∞'
        : '${lopHP.enrollmentCount}/${lopHP.capacity}';

    final mauCho = lopHP.capacity == null
        ? context.muted
        : lopHP.conCho
            ? context.muted
            : AppColors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chair_outlined, size: 12, color: mauCho),
        const SizedBox(width: 2),
        Text(
          soChoHienThi,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mauCho,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
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
                border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.35)),
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
