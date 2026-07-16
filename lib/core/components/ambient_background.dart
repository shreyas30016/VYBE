import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AmbientBackground extends StatefulWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Moving Ambient Glow
        AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.2 + (150 * math.sin(_bgAnimController.value * 2 * math.pi)),
              left: (MediaQuery.of(context).size.width / 2) - 200 + (100 * math.cos(_bgAnimController.value * 2 * math.pi)),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.primary.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            );
          }
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),
        widget.child,
      ],
    );
  }
}
