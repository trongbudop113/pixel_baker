import 'package:flutter/material.dart';

/// Floating back-to-top button. Place inside a Stack above the scroll content.
/// Pass the ScrollController of the scrollable widget.
class BackToTopButton extends StatefulWidget {
  const BackToTopButton({
    super.key,
    required this.scrollController,
    this.showAfterOffset = 300,
    this.color = const Color(0xFFE53935),
  });

  final ScrollController scrollController;
  final double showAfterOffset;
  final Color color;

  @override
  State<BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<BackToTopButton> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = widget.scrollController.offset > widget.showAfterOffset;
    if (shouldShow != _visible) {
      setState(() => _visible = shouldShow);
    }
  }

  void _scrollToTop() {
    widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 24,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !_visible,
          child: GestureDetector(
            onTap: _scrollToTop,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
