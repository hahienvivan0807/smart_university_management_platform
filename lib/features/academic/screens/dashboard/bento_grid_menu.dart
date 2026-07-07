import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/dashboard_mock_data.dart';
import 'feature_bento_card.dart';

// ============================================================================
// BENTO GRID MENU — bố cục bất đối xứng kiểu "Bento Box" bằng widget Flutter
// chuẩn (Row/Column/GridView), KHÔNG dùng `flutter_staggered_grid_view` để
// tránh thêm dependency:
//
//   ┌─────────────────────────────┐   ← ô "featured" (config.featured=true),
//   │        Ô LỚN (2x1)          │     chiếm trọn 1 hàng, cao gấp đôi ô nhỏ
//   └─────────────────────────────┘
//   ┌───────┐ ┌───────┐ ┌───────┐
//   │  Ô 1  │ │  Ô 2  │ │  Ô 3  │      ← phần còn lại xếp lưới đều 3 cột
//   └───────┘ └───────┘ └───────┘
// ============================================================================

class BentoGridMenu extends StatelessWidget {
  const BentoGridMenu({super.key, required this.items});

  final List<DashboardFeatureConfig> items;

  @override
  Widget build(BuildContext context) {
    final featured = items.where((e) => e.featured).toList();
    final rest = items.where((e) => !e.featured).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final cfg in featured) ...[
          SizedBox(
            height: 92,
            child: FeatureBentoCard(config: cfg),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            // Cùng breakpoint với _FeatureGrid (dashboard_screen.dart) —
            // điện thoại 3 cột, tablet 4 cột, desktop/màn rộng 5 cột.
            final coRong = constraints.maxWidth;
            final soCot = coRong >= 900 ? 5 : (coRong >= 600 ? 4 : 3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rest.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: soCot,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                // 0.85 thay vì 0.92 — chừa thêm chỗ theo chiều dọc, tránh
                // RenderFlex overflow vài phần trăm pixel khi nhãn 2 dòng
                // sát mép ở 1 số bề rộng màn hình cụ thể.
                childAspectRatio: 0.85,
              ),
              itemBuilder: (_, i) => FeatureBentoCard(config: rest[i]),
            );
          },
        ),
      ],
    );
  }
}
