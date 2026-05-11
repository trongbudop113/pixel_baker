import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppHeaderColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const gray = Color(0xFF8A8A8A);
}

class PixelHeaderBar extends StatelessWidget {
  final String rightLabel;
  final String? centerLabel;
  final Widget? rightWidget;
  final bool showBack;
  final bool showBrand;
  final String backFallbackRoute;

  const PixelHeaderBar({
    super.key,
    required this.rightLabel,
    this.centerLabel,
    this.rightWidget,
    this.showBack = false,
    this.showBrand = true,
    this.backFallbackRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppHeaderColors.gray, width: 2),
      ),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go(backFallbackRoute);
              },
              child: const Icon(Icons.arrow_back, size: 18, color: AppHeaderColors.blue),
            )
          else if (showBrand)
            GestureDetector(
              onTap: () => context.go('/'),
              child: _txt('PIXEL BAKERY', AppHeaderColors.red, 12, FontWeight.w900),
            )
          else
            const SizedBox(width: 18),
          if (centerLabel != null) ...[
            const Spacer(),
            _txt(centerLabel!, AppHeaderColors.blue, 10, FontWeight.w700),
            const Spacer(),
          ] else
            const Spacer(),
          if (rightWidget != null) rightWidget! else _txt(rightLabel, AppHeaderColors.blue, 12, FontWeight.w800),
        ],
      ),
    );
  }

  Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      );
}
