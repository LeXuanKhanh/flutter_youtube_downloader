// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoFormat _$VideoFormatFromJson(Map<String, dynamic> json) {
  return VideoFormat(
    formatId: json['format_id'] as String? ?? '',
    extension: json['ext'] as String? ?? '',
    formatNote: json['format_note'] as String? ?? '',
    fullFormat: json['format'] as String? ?? '',
    height: json['height'] as int? ?? 0,
  );
}

Map<String, dynamic> _$VideoFormatToJson(VideoFormat instance) =>
    <String, dynamic>{
      'format_id': instance.formatId,
      'ext': instance.extension,
      'format_note': instance.formatNote,
      'format': instance.fullFormat,
      'height': instance.height,
    };
