import 'package:aethryon_capability/aethryon_capability.dart';

import 'adapter.dart';

/// Static manifest from Phase 0 research. Source ids -> docs/API_AND_LICENSING_RESEARCH.md
/// (Phase 0 package). Anything not verified stays UNVERIFIED (=> disabled in UI)
/// until a runtime probe or a Phase 2+ practical test upgrades it.
CapabilityRegistry buildDriveRegistry() {
  final r = CapabilityRegistry();

  const u = Capability.unverified();
  r.register(
    'webdav',
    {
      DriveFeature.browse: u, // RFC 4918 not yet verified in this project
      DriveFeature.download: u,
      DriveFeature.rangeDownload: u, // server-dependent; probe at runtime
      DriveFeature.upload: u,
      DriveFeature.resumableUpload: const Capability.unsupported(
        note: 'plain WebDAV has no resumable upload (server-specific extensions only; UNVERIFIED)',
      ),
      DriveFeature.mkdir: u,
      DriveFeature.move: u,
      DriveFeature.trash: const Capability.unsupported(
        note: 'no standard trash in WebDAV (UNVERIFIED per server)',
      ),
      DriveFeature.share: const Capability.unsupported(note: 'not in protocol'),
      DriveFeature.serverSearch: u,
      DriveFeature.changeFeed: u,
      DriveFeature.quota: u,
    },
    overall: const Capability.unverified(
      note: 'WebDAV RFC verification pending; Phase 2 practical test required',
    ),
  );

  r.register(
    'nextcloud',
    {
      DriveFeature.browse: u,
      DriveFeature.download: u,
      DriveFeature.upload: u,
      DriveFeature.resumableUpload: const Capability.partial(
        evidence: Evidence.primary,
        sources: ['S16'],
        note: 'chunked upload exists per official manual; details UNVERIFIED',
      ),
      DriveFeature.trash: const Capability.partial(
        evidence: Evidence.primary,
        sources: ['S16'],
        note: 'trashbin API listed',
      ),
      DriveFeature.share: const Capability.partial(
        evidence: Evidence.primary,
        sources: ['S16'],
        note: 'OCS share API listed',
      ),
      DriveFeature.serverSearch: const Capability.partial(
        evidence: Evidence.primary,
        sources: ['S16'],
        note: 'search API listed',
      ),
    },
    overall: const Capability.partial(
      evidence: Evidence.primary,
      sources: ['S16'],
      note: 'existence only',
    ),
  );

  r.register('onedrive', {
    DriveFeature.resumableUpload: Capability.full(
      sources: ['S11'],
      note: '320 KiB multiples (Graph createUploadSession)',
    ),
  }, overall: const Capability.partial(note: 'only upload session verified'));

  r.register('dropbox', {
    DriveFeature.resumableUpload: const Capability.partial(
      sources: ['S13'],
      note: 'SDK-doc derived (secondary+)',
    ),
  }, overall: const Capability.partial(note: 'verification incomplete'));

  r.register(
    'google_drive',
    {},
    overall: const Capability.requiresPermission(
      sources: ['S01', 'S02', 'S03'],
      note:
          'restricted scope; BYO OAuth client path chosen (DECISIONS ADR-009)',
    ),
  );

  r.register('gdrive_pooling', {
    'pooling': const Capability.unsupported(
      sources: ['S03'],
      note: 'ToS forbids storage sharding/limit circumvention',
    ),
  }, overall: const Capability.unsupported(sources: ['S03']));
  return r;
}
