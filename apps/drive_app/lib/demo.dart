import 'package:drive_core/drive_core.dart';

const demoAccount = 'demo';

/// Demo data only. Real providers arrive via adapters; the UI never changes.
MemoryStorageAdapter buildDemoAdapter() => MemoryStorageAdapter()
  ..seedFolder(demoAccount, '/Documents/Reports')
  ..seedFolder(demoAccount, '/Photos')
  ..seedFile(demoAccount, '/Documents/notes.txt', List.filled(2048, 65))
  ..seedFile(demoAccount, '/Documents/Reports/q3.pdf', List.filled(3 * 1024 * 1024, 1))
  ..seedFile(demoAccount, '/readme.md', List.filled(300, 66));
