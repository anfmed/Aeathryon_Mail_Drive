import 'package:aethryon_capability/aethryon_capability.dart';
import 'package:drive_core/drive_core.dart';
import 'package:test/test.dart';

void main() {
  final r = buildDriveRegistry();
  test('pooling is unsupported (Google ToS)', () {
    expect(r.lookup('gdrive_pooling', 'pooling').enabledInUi, isFalse);
  });
  test('unverified WebDAV features are disabled in UI', () {
    expect(r.lookup('webdav', DriveFeature.browse).enabledInUi, isFalse);
  });
  test('every FULL has a source', () {
    for (final p in r.providers) {
      for (final f in ['resumableUpload', 'browse', 'upload', 'share']) {
        final c = r.lookup(p, f);
        if (c.status == CapabilityStatus.full) expect(c.sources, isNotEmpty);
      }
    }
  });
}
