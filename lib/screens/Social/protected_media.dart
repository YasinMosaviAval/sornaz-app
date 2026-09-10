import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class ProtectedMedia {
  ProtectedMedia(this.account);
  final String account;
  static final cipher = AesGcm.with256bits();
  static const storage = FlutterSecureStorage();
  static final Map<String, Future<SecretKey>> _keys = {};
  Future<SecretKey> key() => _keys.putIfAbsent(account, () async {
    final name = 'course-media-key-v1:$account';
    final saved = await storage.read(key: name);
    if (saved != null) return SecretKey(base64Decode(saved));
    final key = await cipher.newSecretKey();
    await storage.write(
      key: name,
      value: base64Encode(await key.extractBytes()),
    );
    return key;
  });
  List<int> aad(File file, int index) =>
      utf8.encode('$account:${file.uri.pathSegments.last}:$index');
  Future<void> save(File target, Stream<List<int>> source) async {
    final secret = await key(), part = File('${target.path}.part');
    final sink = part.openWrite();
    var index = 0;
    Future<void> write(List<int> bytes) async {
      final box = await cipher.encrypt(
        bytes,
        secretKey: secret,
        aad: aad(target, index++),
      );
      final data = box.concatenation();
      sink.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
      sink.add(data);
    }

    try {
      sink.add(utf8.encode('SORNAZ01'));
      await for (final chunk in source) {
        for (var offset = 0; offset < chunk.length; offset += 65536) {
          await write(
            chunk.sublist(offset, (offset + 65536).clamp(0, chunk.length)),
          );
        }
      }
      await write([]); // Authenticated end marker detects truncation.
      await sink.flush();
      await sink.close();
      await part.rename(target.path);
    } catch (_) {
      await sink.close();
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  Future<File> open(File encrypted) async {
    final secret = await key();
    final temp = await (await getTemporaryDirectory()).createTemp(
      'sornaz-playback-',
    );
    final file = File('${temp.path}/media');
    final input = await encrypted.open(),
        output = await file.open(mode: FileMode.write);
    bool success = false;
    try {
      if (utf8.decode(await input.read(8)) != 'SORNAZ01')
        throw const FormatException('Invalid protected media');
      var index = 0;
      while (true) {
        final length = await input.read(4);
        if (length.length != 4)
          throw const FormatException('Incomplete protected media');
        final count = ByteData.sublistView(length).getUint32(0);
        if (count < 28 || count > 65564)
          throw const FormatException('Invalid protected media');
        final raw = await input.read(count);
        if (raw.length != count)
          throw const FormatException('Incomplete protected media');
        final data = await cipher.decrypt(
          SecretBox.fromConcatenation(raw, nonceLength: 12, macLength: 16),
          secretKey: secret,
          aad: aad(encrypted, index++),
        );
        if (data.isEmpty) {
          if (await input.position() != await input.length())
            throw const FormatException('Invalid protected media');
          break;
        }
        await output.writeFrom(data);
      }
      success = true;
      return file;
    } finally {
      await input.close();
      await output.close();
      if (!success) await temp.delete(recursive: true);
    }
  }

  static Future<void> close(File file) async {
    if (file.parent.uri.pathSegments
            .where((s) => s.startsWith('sornaz-playback-'))
            .isNotEmpty &&
        await file.parent.exists())
      await file.parent.delete(recursive: true);
  }
}
