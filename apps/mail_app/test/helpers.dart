import 'dart:io';

import 'package:aethryon_auth/aethryon_auth.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mail_app/services.dart';

class FakeFiles implements FilePlatform {
  final Directory dir = Directory.systemTemp.createTempSync('aeth_mail_');
  @override
  Future<PickedFile?> pickFile() async => null;
  @override
  Future<String> appDataDir() async => dir.path;
  @override
  Future<String> downloadsDir() async => dir.path;
}

class FakeOpener implements UrlOpener {
  @override
  Future<void> open(Uri url) async {}
}

MailServices testServices({MemorySecureStore? store, Future<MailDb> Function()? openDb}) => MailServices(
      secureStore: store ?? MemorySecureStore(),
      files: FakeFiles(),
      opener: FakeOpener(),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      openDb: openDb ?? () async => const MailDb(problem: 'disabled in tests'),
    );
