import 'package:flutter/material.dart';

/// Shared footer bar — đồng bộ height và style với checkout page.
/// Web: height 56 | Mobile: height 42
class PixelFooter extends StatelessWidget {
  const PixelFooter({super.key, this.label = 'PIXEL BAKERY', this.mobile = false});

  final String label;
  final bool mobile;

  static const double webHeight = 56;
  static const double mobileHeight = 42;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: mobile ? mobileHeight : webHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          fontSize: mobile ? 8 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
