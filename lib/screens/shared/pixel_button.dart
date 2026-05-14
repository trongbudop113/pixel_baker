import 'package:flutter/material.dart';
import 'pressable.dart';

class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFE53935),
    this.textColor = Colors.white,
    this.height = 46.0,
    this.width,
    this.fontSize = 14.0,
    this.borderRadius = 8.0,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double height;
  final double? width;
  final double fontSize;
  final double borderRadius;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (isLoading || onTap == null) ? color.withOpacity(0.6) : color,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0xFF8A8A8A), width: 2),
        ),
        child: isLoading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(textColor)),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: fontSize + 2),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  }
}
