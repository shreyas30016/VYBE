import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) {
          widget.onPressed();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: const SpringCurve(stiffness: 400, damping: 25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: context.background,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTypography.buttonLabel,
                ),
        ),
      ),
    );
  }
}

class SpringCurve extends Curve {
  final double stiffness;
  final double damping;

  const SpringCurve({this.stiffness = 400, this.damping = 25});

  @override
  double transformInternal(double t) {
    return Curves.easeOutBack.transform(t); // Simplified for standard flutter animation without manual physics sim for now
  }
}
