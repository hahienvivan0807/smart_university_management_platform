import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/me_info.dart';

// ============================================================================
// DIGITAL STUDENT CARD SHEET — bottom sheet phóng to thẻ sinh viên điện tử.
//
// DỮ LIỆU THẬT: mã sinh viên + họ tên lấy từ `session.me` (GET /api/auth/me).
// Mã QR mã hoá `loginCode` — dùng để xác minh danh tính SV (VD: nhân viên
// thư viện/nhà ăn quét kiểm tra), KHÁC với mã QR điểm danh của lớp học phần
// (mã đó do giảng viên tạo, xoay vòng theo `attendance_session_screen.dart`
// — không nhầm 2 khái niệm này).
// ============================================================================

Future<void> showDigitalStudentCardSheet(BuildContext context, MeInfo me) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DigitalStudentCardSheet(me: me),
  );
}

class _DigitalStudentCardSheet extends StatelessWidget {
  const _DigitalStudentCardSheet({required this.me});

  final MeInfo me;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.canvas,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6E6ADE), AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        const Text(
                          'THẺ SINH VIÊN ĐIỆN TỬ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: QrImageView(
                        data: me.loginCode,
                        version: QrVersions.auto,
                        size: 180,
                        gapless: false,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      me.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MSSV: ${me.loginCode}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                'Dùng để xác minh danh tính (thư viện, ký túc xá...). '
                'Đây không phải mã điểm danh của lớp học phần.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
