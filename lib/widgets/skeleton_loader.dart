import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final int itemCount;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const SkeletonLoader({
    super.key,
    this.itemCount = 6,
    this.height = 56,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: padding,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
