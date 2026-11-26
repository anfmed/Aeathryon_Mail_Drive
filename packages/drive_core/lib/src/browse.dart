import 'models.dart';

enum SortKey { name, size, modified }

/// Folders first, then by key. Name comparison is case-insensitive.
List<RemoteNode> sortNodes(
  List<RemoteNode> nodes, {
  SortKey key = SortKey.name,
  bool descending = false,
}) {
  int cmp(RemoteNode a, RemoteNode b) {
    if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
    int r;
    switch (key) {
      case SortKey.size:
        r = (a.size ?? 0).compareTo(b.size ?? 0);
        break;
      case SortKey.modified:
        r =
            (a.modifiedUtc ??
                    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
                .compareTo(
                  b.modifiedUtc ??
                      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                );
        break;
      case SortKey.name:
        r = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        break;
    }
    if (r == 0) r = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return descending ? -r : r;
  }

  return [...nodes]..sort(cmp);
}

/// Navigation stack for one account.
class BrowseState {
  final String accountId;
  final List<String> stack; // folder ids, root first
  const BrowseState(this.accountId, this.stack);
  factory BrowseState.root(String accountId, {String rootId = '/'}) =>
      BrowseState(accountId, [rootId]);

  String get current => stack.last;
  bool get atRoot => stack.length == 1;
  BrowseState push(String folderId) =>
      BrowseState(accountId, [...stack, folderId]);
  BrowseState pop() => atRoot
      ? this
      : BrowseState(accountId, stack.sublist(0, stack.length - 1));
  BrowseState jumpTo(int index) =>
      BrowseState(accountId, stack.sublist(0, index + 1));
}

String formatBytes(int? b) {
  if (b == null) return '';
  const u = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < u.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '$b B' : '${v.toStringAsFixed(v >= 10 ? 0 : 1)} ${u[i]}';
}
