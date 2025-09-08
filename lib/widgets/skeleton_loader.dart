import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isListTile;

  const SkeletonLoader({
    super.key,
    this.itemCount = 6,
    this.height = 56,
    this.borderRadius = 16, // Material 3 standard
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.isListTile = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final highlightColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1);
    
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      padding: widget.padding,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: widget.isListTile ? _buildListTileSkeleton(baseColor, highlightColor) : _buildSimpleSkeleton(baseColor, highlightColor),
      ),
    );
  }

  Widget _buildSimpleSkeleton(Color baseColor, Color highlightColor) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: _buildShimmerOverlay(highlightColor),
          ),
        );
      },
    );
  }

  Widget _buildListTileSkeleton(Color baseColor, Color highlightColor) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                Row(
                  children: [
                    // Avatar skeleton
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text skeletons
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildShimmerOverlay(highlightColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerOverlay(Color highlightColor) {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(_shimmerAnimation.value * 200, 0),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                highlightColor.withValues(alpha: 0.5),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
    );
  }
}
