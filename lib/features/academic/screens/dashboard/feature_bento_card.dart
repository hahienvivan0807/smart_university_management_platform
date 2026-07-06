import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/dashboard_mock_data.dart';

// ============================================================================
// FEATURE BENTO CARD — 1 ô trong Bento Grid.
//
//   • Nền gradient theo `config.gradient`.
//   • Bấm/nhấn giữ → scale nhỏ lại (0.95) rồi nảy về 1.0 khi thả — micro-
//     interaction bằng AnimatedScale, không cần package animation ngoài.
//   • `BentoStatus.comingSoon` → làm mờ (opacity 0.6), thêm badge khoá +
//     "Sắp ra mắt", bấm vào chỉ hiện SnackBar (không điều hướng, vì không có
//     màn thật để mở).
// ============================================================================

class FeatureBentoCard extends StatefulWidget {
  const FeatureBentoCard({super.key, required this.config});

  final DashboardFeatureConfig config;

  @override
  State<FeatureBentoCard> createState() => _FeatureBentoCardState();
}

class _FeatureBentoCardState extends State<FeatureBentoCard> {
  bool _dangNhan = false;

  bool get _sapRaMat => widget.config.status == BentoStatus.comingSoon;

  void _xuLyBam(BuildContext context) {
    if (_sapRaMat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.config.label}" đang được phát triển.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
      return;
    }
    widget.config.onTap?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;

    return GestureDetector(
      onTapDown: (_) => setState(() => _dangNhan = true),
      onTapCancel: () => setState(() => _dangNhan = false),
      onTapUp: (_) => setState(() => _dangNhan = false),
      onTap: () => _xuLyBam(context),
      child: AnimatedScale(
        scale: _dangNhan ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: _sapRaMat ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cfg.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: cfg.gradient.last.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(cfg.icon, color: Colors.white, size: 19),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        cfg.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_sapRaMat)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded,
                              size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Sắp ra mắt',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
