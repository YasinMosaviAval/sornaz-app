import 'dart:convert';
import 'dart:io';

/// Prepare vendored FFmpeg frameworks explicitly: CocoaPods does not execute a
/// podspec prepare_command for Flutter's local-path development pods.
Future<void> main() async {
  if (!Platform.isMacOS) {
    stderr.writeln(
      'iOS preparation requires macOS and Xcode. No files changed.',
    );
    exitCode = 1;
    return;
  }
  final root = File.fromUri(Platform.script).parent.parent;
  final configFile = File('${root.path}/.dart_tool/package_config.json');
  if (!await configFile.exists()) {
    throw StateError('Run flutter pub get before iOS preparation.');
  }
  final config = jsonDecode(await configFile.readAsString()) as Map;
  final package = (config['packages'] as List).cast<Map>().singleWhere(
    (entry) => entry['name'] == 'ffmpeg_kit_flutter_new_audio',
  );
  final rootUri = package['rootUri'] as String;
  final packageRoot = configFile.uri.resolve(
    rootUri.endsWith('/') ? rootUri : '$rootUri/',
  );
  final pluginIos = Directory.fromUri(packageRoot.resolve('ios/'));
  const frameworks = [
    'ffmpegkit',
    'libavcodec',
    'libavdevice',
    'libavfilter',
    'libavformat',
    'libavutil',
    'libswresample',
    'libswscale',
  ];
  bool complete() => frameworks.every(
    (name) => File(
      '${pluginIos.path}/Frameworks/$name.xcframework/Info.plist',
    ).existsSync(),
  );
  if (!complete()) {
    final marker = Directory(
      '${pluginIos.path}/Frameworks/ffmpegkit.xcframework',
    );
    if (await marker.exists()) {
      throw StateError(
        'Incomplete FFmpeg frameworks. Repair the package cache before continuing.',
      );
    }
    final setup = File.fromUri(packageRoot.resolve('scripts/setup_ios.sh'));
    if (!await setup.exists())
      throw StateError('FFmpeg iOS setup script missing.');
    final process = await Process.start(
      '/bin/bash',
      [setup.path],
      workingDirectory: pluginIos.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await process.exitCode;
    if (code != 0)
      throw ProcessException(
        '/bin/bash',
        [setup.path],
        'FFmpeg setup failed',
        code,
      );
  }
  if (!complete()) throw StateError('FFmpeg iOS framework validation failed.');
  stdout.writeln('All eight FFmpeg iOS XCFramework manifests are present.');
}
