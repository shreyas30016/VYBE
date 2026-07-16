import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final bool hasGlow;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const BentoCard({
    super.key,
    required this.child,
    this.hasGlow = false,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: context.strokeSubtle,
          width: 1,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: context.primary.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
