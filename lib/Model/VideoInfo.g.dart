// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VideoInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoInfo _$VideoInfoFromJson(Map<String, dynamic> json) {
  return VideoInfo(
    link: json['webpage_url'] as String? ?? '',
    title: json['title'] as String? ?? '',
    thumbnail: json['thumbnail'] as String? ?? '',
    durationInSeconds: (json['duration'] as num?)?.toDouble() ?? 0,
    id: json['display_id'] as String? ?? '',
    formats: (json['formats'] as List<dynamic>?)
            ?.map((e) => VideoFormat.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

Map<String, dynamic> _$VideoInfoToJson(VideoInfo instance) => <String, dynamic>{
      'webpage_url': instance.link,
      'title': instance.title,
      'thumbnail': instance.thumbnail,
      'display_id': instance.id,
      'duration': instance.durationInSeconds,
      'formats': instance.formats.map((e) => e.toJson()).toList(),
    };
