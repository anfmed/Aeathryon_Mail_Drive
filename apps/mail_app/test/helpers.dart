import 'dart:convert';
import 'dart:io';

import 'package:aethryon_brand/aethryon_brand.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mail_app/services.dart';

class SeededStore implements SecureStore {
  final Map<String, String> m;
  SeededStore(this.m);
  factory SeededStore.mail({bool welcomeDone = true}) => SeededStore({
    if (welcomeDone)
      'aethryon.mail.settings': jsonEncode({'welcomeDone': true}),
  });
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

class FakeFiles implements FilePlatform {
  final Directory dir = Directory.systemTemp.createTempSync('aeth_mail_');
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

MailServices testServices({
  SecureStore? store,
  Future<MailDb> Function()? openDb,
  RecordingOpener? opener,
}) {
  final st = store ?? SeededStore.mail();
  final op = opener ?? RecordingOpener();
  final client = MockClient((_) async => http.Response('{}', 500));
  return MailServices(
    secureStore: st,
    files: FakeFiles(),
    opener: op,
    httpClient: client,
    openDb: openDb ?? () async => const MailDb(problem: 'disabled in tests'),
    brand: BrandServices.create(
      store: st,
      opener: op,
      httpClient: client,
      info: FakeInfo(),
      linksCacheKey: 'aethryon.mail.links',
      ausBaseUrl: '',
      appId: 'com.aethryon.mail_app',
    ),
  );
}
