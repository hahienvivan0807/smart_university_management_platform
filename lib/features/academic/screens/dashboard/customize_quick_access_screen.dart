import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/dashboard_mock_data.dart';
import 'package:smart_university_management_platform/data/services/quick_access_prefs.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';

// ============================================================================
// CUSTOMIZE QUICK ACCESS SCREEN — ghim/bỏ ghim chức năng lên Dashboard.
//
// Mỗi lần bấm gạt (Switch) lưu NGAY xuống máy qua `QuickAccessPrefs` (không
// có nút "Lưu" riêng) — phản hồi tức thời, dễ học qua thao tác thay vì phải
// nhớ 1 bước riêng để xác nhận.
// ============================================================================

class CustomizeQuickAccessScreen extends StatefulWidget {
  const CustomizeQuickAccessScreen({
    super.key,
    required this.vaiTro,
    required this.chucNangCoDinh,
    required this.chucNangTuyChon,
  });

  /// Khóa vai trò dùng để lưu lựa chọn riêng (VD: "Lecturer").
  final String vaiTro;

  /// Luôn hiện trên Dashboard, không tắt được.
  final List<DashboardFeatureConfig> chucNangCoDinh;

  /// Người dùng tự chọn ghim/bỏ ghim.
  final List<DashboardFeatureConfig> chucNangTuyChon;

  @override
  State<CustomizeQuickAccessScreen> createState() =>
      _CustomizeQuickAccessScreenState();
}

class _CustomizeQuickAccessScreenState
    extends State<CustomizeQuickAccessScreen> {
  final _prefs = const QuickAccessPrefs();

  Set<String> _daGhim = {};
  bool _dangTai = true;

  @override
  void initState() {
    super.initState();
    _taiDaGhim();
  }

  Future<void> _taiDaGhim() async {
    final daGhim = await _prefs.layDaGhim(widget.vaiTro);
    if (!mounted) return;
    setState(() {
      _daGhim = daGhim;
      _dangTai = false;
    });
  }

  Future<void> _bat(String id) async {
    setState(() => _daGhim = {..._daGhim, id});
    await _prefs.ghim(widget.vaiTro, id);
  }

  Future<void> _tat(String id) async {
    setState(() => _daGhim = {..._daGhim}..remove(id));
    await _prefs.boGhim(widget.vaiTro, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title:
            Text('Tùy chỉnh Trang chủ', style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: _dangTai
          ? const SkeletonListView(hasTrailing: false)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Chọn chức năng bạn muốn ghim lên Trang chủ để thao tác nhanh hơn.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final cfg in widget.chucNangCoDinh)
                  _HangChucNang(config: cfg, luonHien: true, daGhim: true),
                if (widget.chucNangCoDinh.isNotEmpty)
                  const SizedBox(height: AppSpacing.sm),
                for (final cfg in widget.chucNangTuyChon)
                  _HangChucNang(
                    config: cfg,
                    luonHien: false,
                    daGhim: _daGhim.contains(cfg.id),
                    onDoi: (bat) => bat ? _bat(cfg.id) : _tat(cfg.id),
                  ),
              ],
            ),
    );
  }
}

class _HangChucNang extends StatelessWidget {
  const _HangChucNang({
    required this.config,
    required this.luonHien,
    required this.daGhim,
    this.onDoi,
  });

  final DashboardFeatureConfig config;
  final bool luonHien;
  final bool daGhim;
  final ValueChanged<bool>? onDoi;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: config.gradient),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(config.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.label, style: Theme.of(context).textTheme.titleMedium),
                if (luonHien)
                  Text('Luôn hiển thị',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 11.5, color: context.muted)),
              ],
            ),
          ),
          Switch(
            value: daGhim,
            onChanged: luonHien ? null : (v) => onDoi?.call(v),
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
