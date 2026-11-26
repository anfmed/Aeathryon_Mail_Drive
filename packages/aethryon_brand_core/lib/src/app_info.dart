class AppVersion {
  final String version;
  final String build;
  const AppVersion(this.version, [this.build = '']);
  String get display => build.isEmpty ? version : '$version ($build)';
}

/// Real version/build metadata comes from the platform (never hard-coded).
abstract class AppInfo {
  Future<AppVersion> load();
}
