import 'dart:convert';
import 'dart:io';

import 'package:aethryon_brand/aethryon_brand.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:drive_app/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory secure store that can start with the welcome dialog already completed.
class SeededStore implements SecureStore {
  final Map<String, String> m;
  SeededStore(this.m);
  factory SeededStore.drive({bool welcomeDone = true}) => SeededStore({
    if (welcomeDone)
      'aethryon.drive.settings': jsonEncode({'welcomeDone': true}),
  });
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

class FakeFiles implements FilePlatform {
  final Directory dir = Directory.systemTemp.createTempSync('aeth_app_');
  @override
  Future<PickedFile?> pickFile() async => null;
  @override
  Future<String> appDataDir() async => dir.path;
  @override
  Future<String> downloadsDir() async => dir.path;
}

class RecordingOpener implements UrlOpener {
  final opened = <Uri>[];
  @override
  Future<void> open(Uri url) async => opened.add(url);
}

class FakeInfo implements AppInfo {
  @override
  Future<AppVersion> load() async => const AppVersion('1.2.3', '45');
}

DriveServices testServices({
  SecureStore? store,
  Future<DriveDb> Function()? openDb,
  RecordingOpener? opener,
}) {
  final st = store ?? SeededStore.drive();
  final op = opener ?? RecordingOpener();
  final client = MockClient((_) async => http.Response('{}', 500));
  return DriveServices(
    secureStore: st,
    files: FakeFiles(),
    opener: op,
    httpClient: client,
    openDb: openDb ?? () async => const DriveDb(problem: 'disabled in tests'),
    brand: BrandServices.create(
      store: st,
      opener: op,
      httpClient: client,
      info: FakeInfo(),
      linksCacheKey: 'aethryon.drive.links',
      ausBaseUrl: '',
      appId: 'com.aethryon.drive_app',
    ),
  );
}
