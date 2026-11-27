import 'dart:io';
import 'package:aethryon_brand_core/aethryon_brand_core.dart';
import 'package:aethryon_platform/aethryon_platform.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _Picked implements PickedFile {
  final XFile _f;
  _Picked(this._f);
  @override
  String get name => _f.name;
  @override
  Future<int> length() => _f.length();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => _f.openRead(start, end);
}

class FlutterFilePlatform implements FilePlatform {
  @override
  Future<PickedFile?> pickFile() async {
    final x = await openFile();
    return x == null ? null : _Picked(x);
  }

  @override
  Future<String> appDataDir() async => (await getApplicationSupportDirectory()).path;

  @override
  Future<String> downloadsDir() async {
    Directory? d;
    try {
      d = await getDownloadsDirectory(); // null on Android/iOS
    } catch (_) {}
    d ??= await getApplicationDocumentsDirectory();
    final sub = Directory('${d.path}${Platform.pathSeparator}Aethryon');
    await sub.create(recursive: true);
    return sub.path;
  }
}

class FlutterUrlOpener implements UrlOpener {
  @override
  Future<void> open(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) throw StateError('could not open the system browser');
  }
}

class FlutterAppInfo implements AppInfo {
  @override
  Future<AppVersion> load() async {
    final i = await PackageInfo.fromPlatform();
    return AppVersion(i.version, i.buildNumber);
  }
}
