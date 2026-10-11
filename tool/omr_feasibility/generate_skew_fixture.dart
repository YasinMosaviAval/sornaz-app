import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final source = img.decodeImage(File('treble.png').readAsBytesSync());
  if (source == null) throw StateError('treble.png is not an image');
  source.backgroundColor = img.ColorRgb8(255, 255, 255);
  final rotated = img.copyRotate(source, angle: 3);
  File('treble_skew3.png').writeAsBytesSync(img.encodePng(rotated));
}
