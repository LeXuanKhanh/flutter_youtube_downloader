// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_release_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GithubReleaseData _$GithubReleaseDataFromJson(Map<String, dynamic> json) {
  return GithubReleaseData(
    tagName: json['tag_name'] as String? ?? '',
  );
}

Map<String, dynamic> _$GithubReleaseDataToJson(GithubReleaseData instance) =>
    <String, dynamic>{
      'tag_name': instance.tagName,
    };
