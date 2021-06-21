// get only info which to display in order to reduce latency
import 'package:flutter_youtube_downloader/Model/VideoFormat.dart';
import 'package:json_annotation/json_annotation.dart';

part 'VideoInfo.g.dart';

enum VideoType {
  facebook,
  youtube,
  other
}

extension VideoTypeEx on VideoType {
  String get cookieFile {
    switch (this) {
      case VideoType.facebook:
        return "facebook.txt";
      case VideoType.youtube:
        return "youtube.txt";
      case VideoType.other:
        return "other.txt";
      default:
        return "other.txt";
    }
  }

  // custom enum init cheat
  VideoType fromLinkString({required String link}) {
    if (link.contains('facebook')) {
      return VideoType.facebook;
    }

    if (link.contains('youtube')) {
      return VideoType.youtube;
    }

    return VideoType.other;
  }

}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VideoInfo {
  @JsonKey(name: 'webpage_url', defaultValue: '')
  String link;
  @JsonKey(defaultValue: '')
  String title;
  @JsonKey(defaultValue: '')
  String thumbnail;
  @JsonKey(name: 'display_id', defaultValue: '')
  String id;
  @JsonKey(name: 'duration', defaultValue: 0)
  int durationInSeconds;
  @JsonKey(defaultValue: [])
  List<VideoFormat> formats;

  @JsonKey(ignore: true)
  double downloadPercentage = 0;
  @JsonKey(ignore: true)
  bool isLoading = false;
  @JsonKey(ignore: true)
  late VideoResolution selectedResolutions;

  VideoType get type {
    if (link.contains('facebook')) {
      return VideoType.facebook;
    }

    if (link.contains('youtube')) {
      return VideoType.youtube;
    }

    return VideoType.other;
  }
  //HH:mm:sss
  String get duration {
    final now = Duration(seconds: durationInSeconds);
    return _printDuration(now);
  }
  List<VideoFormat> get videoFormats {
    final videoFormats = formats.where((element) => element.type == VideoFormatType.video).toList();
    // descending, best resolution on top
    videoFormats.sort((first, second) => second.height.compareTo(first.height));
    return videoFormats;
  }
  List<VideoFormat> get audioFormats {
    final audioFormats = formats.where((element) => element.type == VideoFormatType.audio).toList();
    return audioFormats;
  }
  List<VideoResolution> get availableResolutions {
    final videoFormatDescriptions = videoFormats
        .map((e) => VideoResolution(formatNote: e.formatNote, height: e.height))
        .toSet().toList();
    return videoFormatDescriptions;
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String digitHours = duration.inHours == 0 ? '' : '${duration.inHours}:';
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$digitHours$twoDigitMinutes:$twoDigitSeconds";
  }

  VideoInfo({
    required this.link,
    required this.title,
    required this.thumbnail,
    required this.durationInSeconds,
    required this.id,
    this.formats = const [],
  }) {
    selectedResolutions = availableResolutions.first;
  }

  factory VideoInfo.fromJson(Map<String, dynamic> json) => _$VideoInfoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoInfoToJson(this);

}

class VideoResolution {
  String formatNote;
  int height;

  VideoResolution({
    required this.formatNote,
    required this.height
  });

  @override
  String toString() {
    // TODO: implement toString
    return '$formatNote-$height';
  }

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    if (!(other is VideoResolution)) {
      return super == other;
    }

    return (height == other.height);

  }

  @override
  // TODO: implement hashCode
  int get hashCode => height;

}