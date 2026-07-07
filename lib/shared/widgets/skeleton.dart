import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';

// ============================================================================
// SKELETON LOADING — dùng thay CircularProgressIndicator ở mọi màn loading
// toàn trang (list/detail). Không dùng cho spinner nhỏ trong nút submit form
// — đó là phản hồi hành động (đang lưu/đang gửi), khác với loading nội dung.
//
//   Shimmer            → hiệu ứng quét sáng, bọc quanh 1 nhóm SkeletonBox
//   SkeletonBox         → khối bo góc màu nền, đơn vị dựng hình cơ bản
//   SkeletonListTile     → khớp đúng shape "Container + leading box + 2 dòng
//                          chữ" mà hầu hết list screen trong app đang dùng
//   SkeletonListView     → tiện ích: Shimmer + danh sách SkeletonListTile,
//                          dùng thẳng thay cho `Center(CircularProgressIndicator())`
// ============================================================================

class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        context.isDark ? const Color(0xFF232328) : const Color(0xFFE9E9EC);
    final highlight =
        context.isDark ? const Color(0xFF38383F) : const Color(0xFFF7F7F8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlidingGradientTransform(slidePercent: _controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

/// Khối bo góc màu nền — đơn vị dựng hình cơ bản của mọi skeleton. Tự lấy màu
/// nền theo theme (không cần bọc trong Shimmer mới hiện được, chỉ cần Shimmer
/// để có hiệu ứng quét — không có Shimmer bao ngoài vẫn hiện đúng màu tĩnh).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius,
  });

  final double? width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF232328) : const Color(0xFFE9E9EC),
        borderRadius: BorderRadius.circular(radius ?? height / 3),
      ),
    );
  }
}

/// Khớp đúng shape "Container bo góc + leading box 40x40 + tiêu đề + phụ đề"
/// mà hầu hết list screen (Faculty/Course/Program/CourseOffering/...) đang dùng.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key, this.hasTrailing = true});

  final bool hasTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 160, height: 14),
                const SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: MediaQuery.of(context).size.width * 0.35, height: 11),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: AppSpacing.md),
            const SkeletonBox(width: 20, height: 20, radius: AppRadius.sm),
          ],
        ],
      ),
    );
  }
}

/// Thay thẳng cho `Center(child: CircularProgressIndicator())` ở mọi màn
/// list/detail đang tải — dùng: `if (_dangTai) return const SkeletonListView();`
class SkeletonListView extends StatelessWidget {
  const SkeletonListView({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.hasTrailing = true,
  });

  final int itemCount;
  final EdgeInsets padding;
  final bool hasTrailing;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, _) => SkeletonListTile(hasTrailing: hasTrailing),
      ),
    );
  }
}
