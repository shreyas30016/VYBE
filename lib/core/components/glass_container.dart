import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppSpacing.radiusCard,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: context.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: context.strokeSubtle,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
