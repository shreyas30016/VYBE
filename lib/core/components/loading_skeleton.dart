import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = AppSpacing.radiusCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.strokeSubtle, width: 1),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: const Duration(seconds: 2),
      // ignore: deprecated_member_use
      color: context.primary.withOpacity(0.1),
    );
  }
}
