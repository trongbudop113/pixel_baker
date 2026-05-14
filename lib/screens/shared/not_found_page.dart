import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routing/app_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.uri});
  final String? uri;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 48),
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pixel art style 404
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 32 : 48,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8A8A8A), width: 3),
                ),
                child: Column(
                  children: [
                    Text(
                      '404',
                      style: TextStyle(
                        fontSize: isMobile ? 72 : 96,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFE53935),
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🍞',
                      style: TextStyle(fontSize: isMobile ? 40 : 52),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy trang',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E88E5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trang bạn tìm kiếm không tồn tại\nhoặc đã được di chuyển.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8A8A),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _btn(
                          context,
                          label: '← Về trang chủ',
                          primary: true,
                          onTap: () => context.go(AppRoutePaths.home),
                        ),
                        const SizedBox(width: 12),
                        _btn(
                          context,
                          label: 'Xem thực đơn',
                          primary: false,
                          onTap: () => context.go(AppRoutePaths.menu),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PIXEL BAKERY | 404',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A8A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(
    BuildContext context, {
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: primary ? const Color(0xFFE53935) : const Color(0xFF8A8A8A),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primary ? Colors.white : const Color(0xFF8A8A8A),
          ),
        ),
      ),
    );
  }
}
