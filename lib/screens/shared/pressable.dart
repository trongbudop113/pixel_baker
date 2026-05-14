import 'package:flutter/material.dart';

/// Wrap any widget to add a subtle press animation (scale + opacity).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.opacity = 0.85,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double opacity;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _opacityAnim = Tween<double>(begin: 1.0, end: widget.opacity).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) { if (widget.onTap != null) _ctrl.forward(); }
  void _onTapUp(_) { _ctrl.reverse(); widget.onTap?.call(); }
  void _onTapCancel() { _ctrl.reverse(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(opacity: _opacityAnim.value, child: child),
        ),
        child: widget.child,
      ),
    );
  }
}
