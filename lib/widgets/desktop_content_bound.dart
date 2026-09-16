import 'dart:io';

import 'package:flutter/material.dart';

/// Caps content width and centers it on Windows so phone-tuned layouts
/// (built around `mq.width` percentages) don't stretch full-bleed across a
/// wide desktop window. No-op on Android/iOS — returns [child] unchanged.
class DesktopContentBound extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DesktopContentBound({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
