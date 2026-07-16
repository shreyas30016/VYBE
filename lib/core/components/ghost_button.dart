import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';
import '../../core/theme/app_theme.dart'; // To reuse SpringCurve

class GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
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
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: context.strokeSubtle,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: context.textPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTypography.buttonLabel.copyWith(
                    color: context.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
