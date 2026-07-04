import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/services/attendance_service.dart';
import 'package:smart_university_management_platform/main.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, required this.courseName});
  final String courseName;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _sv = AttendanceService(authenticatedClient);
  final _controller = MobileScannerController();

  bool _dangXuLy = false;
  bool _xongRoi = false; // ngăn scan nhiều lần

  @override
  void initState() {
    super.initState();
    _xinQuyenViTri();
  }

  Future<void> _xinQuyenViTri() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _xuLyQuet(String token) async {
    if (_dangXuLy || _xongRoi) return;
    setState(() => _dangXuLy = true);
    await _controller.stop();

    // Lấy GPS
    double? lat, lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 5));
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      // GPS lỗi hoặc bị từ chối — vẫn thử check-in (server quyết định)
    }

    final loi = await _sv.checkIn(token, lat: lat, lng: lng);

    if (!mounted) return;
    setState(() {
      _dangXuLy = false;
      _xongRoi = loi == null;
    });

    if (loi != null) {
      _hienThongBao(loi, isError: true);
      await _controller.start(); // cho scan lại nếu lỗi
      setState(() => _xongRoi = false);
    } else {
      _hienThanhCong();
    }
  }

  void _hienThongBao(String message, {bool isError = false}) {
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

  void _hienThanhCong() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF16A34A), size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Điểm danh thành công!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.courseName,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // đóng dialog
              Navigator.pop(context); // đóng scan screen
            },
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Quét QR điểm danh',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _xuLyQuet(barcode!.rawValue!);
              }
            },
          ),

          // Khung ngắm giữa màn hình
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 3),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),

          // Loading overlay
          if (_dangXuLy)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),

          // Hướng dẫn
          Positioned(
            bottom: AppSpacing.xl * 2,
            left: 0,
            right: 0,
            child: Text(
              'Đưa mã QR vào khung để điểm danh',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}