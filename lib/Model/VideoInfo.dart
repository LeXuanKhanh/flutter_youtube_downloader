// get only info which to display in order to reduce latency
import 'dart:developer';

import 'package:flutter_youtube_downloader/Model/VideoFormat.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:process_run/shell.dart';
import 'dart:io';

import '../GlobalVariables.dart';
import 'package:flutter_youtube_downloader/Extension/StringEx.dart';

part 'VideoInfo.g.dart';

// run this command after modify
// flutter pub run build_runner build
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

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true, includeIfNull: true, ignoreUnannotated: true)
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
  double durationInSeconds;
  @JsonKey(defaultValue: [])
  List<VideoFormat> formats;

  VideoProcessingState processingState = VideoProcessingState.start;
  double downloadPercentage = 0;
  bool isLoading = false;

  late VideoResolution selectedResolutions;
  var shellLinesController = ShellLinesController();
  late Shell shell = createShell(controller: shellLinesController);
  var isConvertToMp4 = false;
  var isAudioOnly = false;

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
    final now = Duration(seconds: durationInSeconds.toInt());
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

    final List<VideoResolution> videoFormatDescriptions;

    switch (type) {
      case VideoType.youtube:
        videoFormatDescriptions = videoFormats
            .map((e) => VideoResolution(formatNote: e.formatNote, height: e.height))
            .toSet().toList();
        break;
      case VideoType.facebook:
        videoFormatDescriptions = videoFormats
            .map((e) => VideoResolution(formatNote: '${e.height}p', height: e.height))
            .toSet().toList();
        break;
      default:
        videoFormatDescriptions = videoFormats
            .map((e) => VideoResolution(formatNote: e.formatNote, height: e.height))
            .toSet().toList();
        break;
    }

    return videoFormatDescriptions;
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

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String digitHours = duration.inHours == 0 ? '' : '${duration.inHours}:';
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$digitHours$twoDigitMinutes:$twoDigitSeconds";
  }

  Shell createShell({required ShellLinesController controller}) {
    //Platform.isMacOS
    late Shell newShell;
    if (Platform.isMacOS) {
      final env = Platform.environment;
      final dir = env['HOME']! + '/Documents';
      newShell =
          Shell(stdout: controller.sink, verbose: false, workingDirectory: dir);
    }

    if (Platform.isWindows) {
      newShell = Shell(stdout: controller.sink, verbose: false);
    }

    newShell = Shell(stdout: controller.sink, verbose: false);

    return newShell;
  }

  void initShell() {
    shellLinesController = ShellLinesController();
    shell = createShell(controller: shellLinesController);
  }

  void setStartState() {
    processingState = VideoProcessingState.start;
    downloadPercentage = 0;
    isLoading = false;
  }

  // manual set download finishing state
  void setFinishDownloadState() {
    processingState = VideoProcessingState.done;
    downloadPercentage = 100;
    isLoading = false;
  }

  void stopDownload() {
    shell.kill(ProcessSignal.sigkill);
    initShell();
  }

  Future<List<ProcessResult>> download({required String videoOutput}) {
    final video = '\'bestvideo[height=${selectedResolutions.height}]'
        '[ext=$DEFAULT_VIDEO_EXTENSION]+'
        'bestaudio[ext=$DEFAULT_AUDIO_EXTENSION]'
        '/bestvideo[height<=${selectedResolutions.height}]+bestaudio'
        '/best\' ';
    final format = isAudioOnly ? 'bestaudio[ext=$DEFAULT_AUDIO_EXTENSION] ' : video;
    final recodeMp4 = (isConvertToMp4 && !isAudioOnly) ? '--recode mp4 ' : '';

    final cmd = '.\\youtube-dl '
        '--no-warnings '
        '--cookies ${type.cookieFile} '
        '-f '
        '$format'
        '$recodeMp4'
        '-o $videoOutput \'$link\'';
    log(cmd);
    return shell.run(cmd.crossPlatformCommand);
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

enum VideoProcessingState {
  start,
  downloadingVideo,
  downloadAudio,
  mergingOutput,
  startConvertToDifferentFormat,
  finishConvertToDifferentFormat,
  done,
  unknown,
  init
}

extension VideoProcessingStateEx on VideoProcessingState {

  // can init depend on old state
  VideoProcessingState init({required String value}){
    if (value.contains('Destination:') && (!value.contains('Converting video'))) {
      // if state is downloading video then the next state is download audio
      if (this == VideoProcessingState.downloadingVideo) {
        return VideoProcessingState.downloadAudio;
      } else {
        return VideoProcessingState.downloadingVideo;
      }
    }
    
    if (value.contains('Merging formats into')) {
      return VideoProcessingState.mergingOutput;
    }

//    if (value.contains('Deleting original file')) {
//      if (this == VideoProcessingState.finishConvertToDifferentFormat) {
//        return VideoProcessingState.done;
//      } else {
//        return VideoProcessingState.finishConvertToDifferentFormat;
//      }
//    }

    if (value.contains('Converting video')) {
      return VideoProcessingState.startConvertToDifferentFormat;
    }

    return VideoProcessingState.unknown;

  }
  
  String get description {
    switch (this) {
      case VideoProcessingState.start:
        return '';
      case VideoProcessingState.downloadingVideo:
        return 'downloading video';
      case VideoProcessingState.downloadAudio:
        return 'download audio';
      case VideoProcessingState.mergingOutput:
        return 'merging video and audio';
      case VideoProcessingState.startConvertToDifferentFormat:
        return 'converting to supported format';
      case VideoProcessingState.finishConvertToDifferentFormat:
        return '';
      case VideoProcessingState.done:
        return '';
      default:
        return '';
    }
  }
}