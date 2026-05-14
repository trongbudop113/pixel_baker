import 'package:flutter/material.dart';
import 'shimmer_box.dart';

/// Generic page skeleton — renders a list of shimmer rows.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({
    super.key,
    this.rowCount = 5,
    this.mobile = false,
    this.padding = const EdgeInsets.all(12),
  });

  final int rowCount;
  final bool mobile;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(rowCount, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _skeletonCard(i),
        )),
      ),
    );
  }

  Widget _skeletonCard(int index) {
    // Vary widths for visual variation
    final widths = [1.0, 0.75, 0.9, 0.6, 0.85];
    final w = widths[index % widths.length];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 48, height: 48, borderRadius: 6),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: double.infinity * w, height: 14, borderRadius: 4),
                    const SizedBox(height: 6),
                    ShimmerBox(width: double.infinity * 0.5, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ShimmerBox(width: 60, height: 28, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for order list items
class OrdersListSkeleton extends StatelessWidget {
  const OrdersListSkeleton({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(compact ? 4 : 5, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: compact ? 80 : 120, height: 12, borderRadius: 4),
                  const Spacer(),
                  ShimmerBox(width: 60, height: 22, borderRadius: 4),
                ],
              ),
              const SizedBox(height: 8),
              ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
              const SizedBox(height: 4),
              ShimmerBox(width: compact ? 100.0 : 150.0, height: 10, borderRadius: 4),
            ],
          ),
        ),
      )),
    );
  }
}
