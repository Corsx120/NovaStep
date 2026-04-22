import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0, // Сила размытия
    this.opacity = 0.1, // Прозрачность заливки
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: defaultRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Легкая белая/фиолетовая заливка для эффекта стекла
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: defaultRadius,
            border: Border.all(
              // Блики на гранях стекла
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}