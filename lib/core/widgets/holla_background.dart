import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HollaBackground extends StatelessWidget {
  final Widget child;
  final double? opacity;

  const HollaBackground({
    super.key,
    required this.child,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveOpacity = opacity ?? (isDark ? 0.08 : 0.18);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: context.bgColor),
        Positioned.fill(
          child: Opacity(
            opacity: effectiveOpacity,
            child: Image.asset(
              'assets/images/background.png',
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
