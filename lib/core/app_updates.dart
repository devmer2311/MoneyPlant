import 'package:pub_semver/pub_semver.dart';

const releasesUrl = 'https://github.com/devmer2311/MoneyPlant/releases';
const releasesApi =
    'https://api.github.com/repos/devmer2311/MoneyPlant/releases?per_page=30';
const updateWebsite = String.fromEnvironment(
  'MONEY_PLANT_WEBSITE_URL',
  defaultValue: 'https://moneyplantbydev.pages.dev',
);

Uri? websiteUri([String value = updateWebsite]) {
  final uri = Uri.tryParse(value);
  return uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}

Version? appVersion(String value) {
  try {
    // Build numbers identify packaging, not a new public release.
    return Version.parse(
      value.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first,
    );
  } catch (_) {
    return null;
  }
}

bool _releaseUrl(Uri? uri, String path) =>
    uri != null &&
    uri.scheme == 'https' &&
    uri.host == 'github.com' &&
    uri.userInfo.isEmpty &&
    !uri.hasPort &&
    uri.path.startsWith('/devmer2311/MoneyPlant/releases/$path');

class AppRelease {
  final String version;
  final Uri page;
  final Uri? apk;
  const AppRelease(this.version, this.page, this.apk);

  static AppRelease? parse(Map<String, dynamic> json) {
    if (json['draft'] == true || json['prerelease'] == true) return null;
    final tag = json['tag_name'];
    final parsed = tag is String ? appVersion(tag) : null;
    final page = Uri.tryParse(json['html_url']?.toString() ?? '');
    if (parsed == null || parsed.isPreRelease || !_releaseUrl(page, 'tag/')) {
      return null;
    }
    Uri? apk;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets.whereType<Map>()) {
        // Only the workflow's universal APK; never guess an ABI-specific asset.
        if (asset['name'] != 'money-plant.apk' &&
            asset['name'] != 'app-release.apk' &&
            !RegExp(
              '^money-plant-v${RegExp.escape(parsed.toString())}(?:\\+[0-9]+)?\\.apk\$',
            ).hasMatch(asset['name']?.toString() ?? '')) {
          continue;
        }
        final url = Uri.tryParse(
          asset['browser_download_url']?.toString() ?? '',
        );
        if (_releaseUrl(url, 'download/') && url!.path.endsWith('.apk')) {
          apk = url;
          if (asset['name'] == 'money-plant.apk') break;
        }
      }
    }
    return AppRelease(parsed.toString(), page!, apk);
  }

  Map<String, dynamic> toJson() => {
    'tag_name': version,
    'html_url': page.toString(),
    'assets': [
      if (apk != null)
        {'name': 'money-plant.apk', 'browser_download_url': apk.toString()},
    ],
  };
}

AppRelease? newerRelease(dynamic json, String installed) {
  final current = appVersion(installed);
  if (current == null || json is! List) return null;
  final releases =
      json
          .whereType<Map<String, dynamic>>()
          .map(AppRelease.parse)
          .whereType<AppRelease>()
          .where((r) => appVersion(r.version)! > current)
          .toList()
        ..sort(
          (a, b) => appVersion(b.version)!.compareTo(appVersion(a.version)!),
        );
  return releases.firstOrNull;
}
