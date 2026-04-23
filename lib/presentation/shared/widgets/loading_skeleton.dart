import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A shimmer-style placeholder shown while content is loading.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        );
  }
}

class LoadingSkeletonCard extends StatelessWidget {
  const LoadingSkeletonCard({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoadingSkeleton(width: 80, height: 12),
            const SizedBox(height: 12),
            LoadingSkeleton(height: 32, width: double.infinity),
            const SizedBox(height: 8),
            const LoadingSkeleton(width: 120, height: 12),
          ],
        ),
      ),
    );
  }
}
