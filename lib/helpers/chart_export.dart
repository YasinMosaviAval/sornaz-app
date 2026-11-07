import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shared PNG export for account reports and demonstration charts.
Future<void> saveChartPng(GlobalKey boundary, String fileName) async {
  await WidgetsBinding.instance.endOfFrame;
  final render = boundary.currentContext?.findRenderObject();
  if (render is! RenderRepaintBoundary) return;
  final image = await render.toImage(pixelRatio: 2);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final png = bytes.buffer.asUint8List();
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: png,
    );
    if (path != null &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await File(path).writeAsBytes(png);
    }
  } finally {
    image.dispose();
  }
}
