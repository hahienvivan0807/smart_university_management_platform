import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/document.dart';
import 'package:smart_university_management_platform/data/services/document_service.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// DOCUMENT LIST SCREEN — dùng chung cho 2 scope
//
// Truyền đúng 1 trong 2: [courseId] (tài liệu chung của môn học) hoặc
// [courseOfferingId] (tài liệu riêng của 1 lớp học phần).
// [coTheTaiLen] = true khi mở từ ngữ cảnh người dùng có quyền ghi (giảng viên
// mở từ lớp học phần của mình, hoặc Admin/AcademicOffice) — giống quy ước đã
// dùng cho nút điểm danh trong CourseOfferingListScreen: chỉ gate thô ở
// client, quyền thật do server quyết định (403 nếu không đúng chủ lớp).
// ============================================================================

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({
    super.key,
    this.courseId,
    this.courseOfferingId,
    required this.tieuDe,
    this.coTheTaiLen = false,
  }) : assert(
          (courseId == null) != (courseOfferingId == null),
          'Phải truyền đúng 1 trong 2: courseId hoặc courseOfferingId',
        );

  final int? courseId;
  final int? courseOfferingId;
  final String tieuDe;
  final bool coTheTaiLen;

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _dichVu = DocumentService(authenticatedClient);

  List<DocumentItem> _danhSach = [];
  bool _dangTai = true;
  bool _dangTaiLen = false;
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

    final kq = await _dichVu.layDanhSach(
      courseId: widget.courseId,
      courseOfferingId: widget.courseOfferingId,
    );

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = kq.data ?? [];
      _loi = kq.error;
    });
  }

  Future<void> _chonVaTaiLen() async {
    final ketQuaChon = await FilePicker.platform.pickFiles(withData: true);
    if (ketQuaChon == null || ketQuaChon.files.isEmpty) return;

    final file = ketQuaChon.files.single;
    if (file.bytes == null) {
      _thongBao('Không đọc được nội dung file đã chọn.', loi: true);
      return;
    }
    if (!mounted) return;

    final moTaCtrl = TextEditingController();
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Tải lên "${file.name}"',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: TextField(
          controller: moTaCtrl,
          decoration: const InputDecoration(labelText: 'Mô tả (không bắt buộc)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tải lên'),
          ),
        ],
      ),
    );

    if (xacNhan != true || !mounted) return;

    setState(() => _dangTaiLen = true);
    final kq = await _dichVu.upload(
      courseId: widget.courseId,
      courseOfferingId: widget.courseOfferingId,
      fileName: file.name,
      fileBytes: file.bytes!,
      description: moTaCtrl.text.trim().isEmpty ? null : moTaCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _dangTaiLen = false);

    if (kq.error != null) {
      _thongBao(kq.error!, loi: true);
      return;
    }
    _thongBao('Đã tải lên "${file.name}".');
    _taiDanhSach();
  }

  Future<void> _taiXuong(DocumentItem taiLieu) async {
    _thongBao('Đang tải "${taiLieu.originalFileName}"...');
    final kq = await _dichVu.taiVe(taiLieu.documentId);
    if (!mounted) return;

    if (kq.error != null) {
      _thongBao(kq.error!, loi: true);
      return;
    }

    try {
      Directory? thuMuc = await getDownloadsDirectory();
      thuMuc ??= await getApplicationDocumentsDirectory();
      final duongDan =
          '${thuMuc.path}${Platform.pathSeparator}${taiLieu.originalFileName}';
      await File(duongDan).writeAsBytes(kq.bytes!);
      if (!mounted) return;
      _thongBao('Đã lưu: $duongDan');
    } catch (e) {
      if (!mounted) return;
      _thongBao('Không lưu được file: $e', loi: true);
    }
  }

  Future<void> _xacNhanVoHieuHoa(DocumentItem taiLieu) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Vô hiệu hóa tài liệu',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text('"${taiLieu.originalFileName}" sẽ bị gỡ khỏi danh sách.',
            style: Theme.of(ctx).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (dongY != true || !mounted) return;

    final kq = await _dichVu.voHieuHoa(taiLieu.documentId);
    if (!mounted) return;

    _thongBao(
      kq.ok ? 'Đã vô hiệu hóa tài liệu.' : (kq.error ?? 'Thất bại.'),
      loi: !kq.ok,
    );
    if (kq.ok) _taiDanhSach();
  }

  void _thongBao(String message, {bool loi = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: loi ? AppColors.red : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
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
        title: Text(widget.tieuDe, style: Theme.of(context).textTheme.headlineSmall),
      ),
      floatingActionButton: widget.coTheTaiLen
          ? FloatingActionButton.extended(
              heroTag: 'document_list_fab',
              onPressed: _dangTaiLen ? null : _chonVaTaiLen,
              icon: _dangTaiLen
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 20),
              label: Text(_dangTaiLen ? 'Đang tải lên...' : 'Tải lên'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 2,
            )
          : null,
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
                child: const Icon(Icons.attach_file_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Chưa có tài liệu nào.',
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
          widget.coTheTaiLen ? AppSpacing.xl + 56 : AppSpacing.md,
        ),
        itemCount: _danhSach.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => _TaiLieuTile(
          taiLieu: _danhSach[i],
          coTheXoa: widget.coTheTaiLen,
          onTaiXuong: () => _taiXuong(_danhSach[i]),
          onVoHieuHoa: () => _xacNhanVoHieuHoa(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _TaiLieuTile extends StatelessWidget {
  const _TaiLieuTile({
    required this.taiLieu,
    required this.coTheXoa,
    required this.onTaiXuong,
    required this.onVoHieuHoa,
  });

  final DocumentItem taiLieu;
  final bool coTheXoa;
  final VoidCallback onTaiXuong;
  final VoidCallback onVoHieuHoa;

  IconData get _icon {
    final ext = taiLieu.originalFileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.0 : 0.03),
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
          child: Icon(_icon, color: AppColors.accent, size: 20),
        ),
        title: Text(taiLieu.originalFileName,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            [
              if (taiLieu.description != null &&
                  taiLieu.description!.isNotEmpty)
                taiLieu.description!,
              taiLieu.uploadedByName,
              taiLieu.dungLuongHienThi,
            ].join(' · '),
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Tải xuống',
              icon: const Icon(Icons.download_rounded),
              onPressed: onTaiXuong,
            ),
            if (coTheXoa)
              PopupMenuButton<_MenuAction>(
                icon: Icon(Icons.more_vert_rounded, color: context.muted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: context.border),
                ),
                color: context.canvas,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _MenuAction.xoa,
                    child: Row(children: [
                      const Icon(Icons.block_rounded,
                          size: 17, color: AppColors.red),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Vô hiệu hóa',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.red)),
                    ]),
                  ),
                ],
                onSelected: (a) {
                  if (a == _MenuAction.xoa) onVoHieuHoa();
                },
              ),
          ],
        ),
      ),
    );
  }
}

enum _MenuAction { xoa }

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
                color: AppColors.red.withValues(alpha: context.isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
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
