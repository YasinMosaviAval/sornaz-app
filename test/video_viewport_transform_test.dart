import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Players/ui/components/video_viewport_transform.dart';

void main() {
  test(
    'zoomed video pans to all corners while keeping the viewport covered',
    () {
      const size = Size(360, 640);
      const aspect = 9 / 16;
      expect(
        clampVideoOffset(const Offset(1000, 1000), 2, size, aspect),
        const Offset(180, 320),
      );
      expect(
        clampVideoOffset(const Offset(-1000, -1000), 2, size, aspect),
        const Offset(-180, -320),
      );
      expect(
        clampVideoOffset(const Offset(150, 150), 1, size, aspect),
        Offset.zero,
      );
      expect(
        zoomOffsetAroundFocal(
          startOffset: Offset.zero,
          startFocal: const Offset(180, 320),
          focal: const Offset(180, 320),
          startScale: 1,
          scale: 2,
          viewport: size,
          aspect: aspect,
        ),
        Offset.zero,
      );
    },
  );
}
