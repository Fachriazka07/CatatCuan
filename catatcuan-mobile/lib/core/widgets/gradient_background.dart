import 'package:flutter/material.dart';

/// Shared green gradient background used across multiple pages.
/// Usage: GradientBackground(child: YourContent())
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A9B6B), // 100% top-left
            Color(0xFF13B158), // 0% bottom-right
          ],
        ),
      ),
      child: child,
    );
  }
}
