import 'package:flutter/material.dart';

/// Shared footer bar — đồng bộ height và style với checkout page.
/// Web: height 56 | Mobile: height 42
class PixelFooter extends StatelessWidget {
  const PixelFooter({super.key, this.label = 'PIXEL BAKERY', this.mobile = false});

  final String label;
  final bool mobile;

  static const double webHeight = 56;
  static const double mobileHeight = 42;
  static const Color _bg = Color(0xFFF8F8F8);
  static const Color _border = Color(0xFF8A8A8A);
  static const Color _text = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: mobile ? mobileHeight : webHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _text,
          fontSize: mobile ? 8 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
