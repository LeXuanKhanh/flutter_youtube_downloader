import 'package:flutter_youtube_downloader/model/github_release_data.dart';
import 'package:package_info_plus/package_info_plus.dart';

extension PackageInfoEx on PackageInfo {
  VersionNumber get versionNumber => VersionNumber.fromString(string: version);
}
