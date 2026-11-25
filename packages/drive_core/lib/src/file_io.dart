import 'dart:async';
import 'dart:io';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'resumable.dart';

/// Remote names are untrusted input: never let them escape the download folder.
String sanitizeFileName(String name) {
  var s = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
  s = s.replaceAll(RegExp(r'^\.+'), '_').replaceAll(RegExp(r'[. ]+$'), '');
  if (s.isEmpty) s = 'file';
  final stem = s.split('.').first.toUpperCase();
  const reserved = {'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'LPT1', 'LPT2', 'LPT3'};
  if (reserved.contains(stem)) s = '_$s';
  if (s.length > 120) {
    final dot = s.lastIndexOf('.');
    final ext = (dot > 0 && s.length - dot <= 10) ? s.substring(dot) : '';
    s = s.substring(0, 120 - ext.length) + ext;
  }
  return s;
}

/// `name`, then `name (1).ext`, `name (2).ext` ... - existing files are never overwritten.
File uniqueFile(String dirPath, String name) {
  final safe = sanitizeFileName(name);
  final dot = safe.lastIndexOf('.');
  final base = dot > 0 ? safe.substring(0, dot) : safe;
  final ext = dot > 0 ? safe.substring(dot) : '';
  var f = File('$dirPath${Platform.pathSeparator}$safe');
  for (var i = 1; f.existsSync(); i++) {
    f = File('$dirPath${Platform.pathSeparator}$base ($i)$ext');
  }
  return f;
}

class FileSink implements LocalSink {
  final File file;
  IOSink? _sink;
  FileSink(this.file);

  @override
  Future<int> length() async {
    await _sink?.flush();
    return await file.exists() ? await file.length() : 0;
  }

  @override
  Future<void> truncate() async {
    await _sink?.close();
    _sink = null;
    await file.writeAsBytes(const <int>[], flush: true);
  }

  @override
  Future<void> append(List<int> bytes) async {
    _sink ??= file.openWrite(mode: FileMode.append);
    _sink!.add(bytes);
  }

  Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}

class FileSource implements LocalSource {
  final File file;
  FileSource(this.file);
  @override
  Future<int> length() => file.length();
  @override
  Future<List<int>> read(int start, int endInclusive) async {
    final raf = await file.open();
    try {
      await raf.setPosition(start);
      return await raf.read(endInclusive - start + 1);
    } finally {
      await raf.close();
    }
  }
}

/// Adapts a user-picked file (desktop path or Android content stream) for resumable uploads.
class PickedFileSource implements LocalSource {
  final PickedFile file;
  PickedFileSource(this.file);
  @override
  Future<int> length() => file.length();
  @override
  Future<List<int>> read(int start, int endInclusive) async {
    final out = <int>[];
    await for (final c in file.openRead(start, endInclusive + 1)) {
      out.addAll(c);
    }
    return out;
  }
}
