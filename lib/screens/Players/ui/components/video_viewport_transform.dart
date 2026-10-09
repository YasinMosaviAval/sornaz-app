import 'dart:math';
import 'package:flutter/material.dart';

Offset clampVideoOffset(
  Offset offset,
  double scale,
  Size viewport,
  double aspect,
) {
  final fitted = applyBoxFit(
    BoxFit.contain,
    Size(aspect, 1),
    viewport,
  ).destination;
  final maxX = max(0.0, (fitted.width * scale - viewport.width) / 2);
  final maxY = max(0.0, (fitted.height * scale - viewport.height) / 2);
  return Offset(offset.dx.clamp(-maxX, maxX), offset.dy.clamp(-maxY, maxY));
}

Offset zoomOffsetAroundFocal({
  required Offset startOffset,
  required Offset startFocal,
  required Offset focal,
  required double startScale,
  required double scale,
  required Size viewport,
  required double aspect,
}) {
  final center = Offset(viewport.width / 2, viewport.height / 2);
  final next =
      focal -
      center -
      (startFocal - center - startOffset) * (scale / startScale);
  return clampVideoOffset(next, scale, viewport, aspect);
}
