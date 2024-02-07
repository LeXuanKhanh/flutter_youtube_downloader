import 'package:json_annotation/json_annotation.dart';

import '../extension/list_ex.dart';

part 'github_release_data.g.dart';

@JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
    includeIfNull: true,
    ignoreUnannotated: true)
class GithubReleaseData {
  @JsonKey(defaultValue: '')
  String tagName;

  VersionNumber get versionNumber => VersionNumber.fromString(string: tagName);

  GithubReleaseData({required this.tagName});

  factory GithubReleaseData.fromJson(Map<String, dynamic> json) =>
      _$GithubReleaseDataFromJson(json);

  Map<String, dynamic> toJson() => _$GithubReleaseDataToJson(this);
}

class VersionNumber implements Comparable<VersionNumber> {
  String major;
  String minor;
  String patch;

  int get majorNumber => int.tryParse(major) ?? 0;

  int get minorNumber => int.tryParse(minor) ?? 0;

  int get patchNumber => int.tryParse(patch) ?? 0;

  String toString() => '$major.$minor.$patch';

  VersionNumber(
      {required this.major, required this.minor, required this.patch});

  factory VersionNumber.fromString({required String string}) =>
      _$VersionFromString(string: string);

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    if (!(other is VersionNumber)) {
      return false;
    }

    return (majorNumber == other.majorNumber) &&
        (minorNumber == other.minorNumber) &&
        (patchNumber == other.patchNumber);
  }

  @override
  // TODO: implement hashCode
  int get hashCode => (majorNumber * 10000) + (minorNumber * 100) + patchNumber;

  // > 0: current > other
  // = 0: current = other
  // < 0: current < other
  @override
  int compareTo(VersionNumber other) {
    // TODO: implement compareTo
    if (this == other) {
      return 0;
    }

    if (majorNumber != other.majorNumber) {
      return majorNumber - other.majorNumber;
    }

    if (minorNumber != other.minorNumber) {
      return minorNumber - other.minorNumber;
    }

    if (patchNumber != other.patchNumber) {
      return patchNumber - other.patchNumber;
    }

    return 0;
  }
}

VersionNumber _$VersionFromString({required String string}) {
  final arrString = string.split('.');
  final major = arrString.valueAt(index: 0) ?? '0';
  final minor = arrString.valueAt(index: 1) ?? '0';
  final patch = arrString.valueAt(index: 2) ?? '0';
  return VersionNumber(major: major, minor: minor, patch: patch);
}
