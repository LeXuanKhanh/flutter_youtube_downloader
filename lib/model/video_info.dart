// get only info which to display in order to reduce latency
import 'dart:developer';

import 'package:flutter_youtube_downloader/extension/process_run_ex.dart';
import 'package:flutter_youtube_downloader/main.dart';
import 'package:flutter_youtube_downloader/model/video_format.dart';
import 'package:flutter_youtube_downloader/utils/youtubedl_command.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:process_run/shell.dart';
import 'dart:io';

import '../extension//string_ex.dart';
import '../extension/future_ex.dart';
import '../extension/list_ex.dart';

part 'video_info.g.dart';

// run this command after modify
// flutter pub run build_runner build
enum VideoType { facebook, youtube, other }

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

@JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
    includeIfNull: true,
    ignoreUnannotated: true)
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
  late Shell downloadShell = customShell();
  var isConvertToMp4 = false;
  var isAudioOnly = false;
  var currentDownloadPID = '';

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
    final videoFormats = formats
        .where((element) => element.type == VideoFormatType.video)
        .toList();
    // descending, best resolution on top
    videoFormats.sort((first, second) => second.height.compareTo(first.height));
    return videoFormats;
  }

  List<VideoFormat> get audioFormats {
    final audioFormats = formats
        .where((element) => element.type == VideoFormatType.audio)
        .toList();
    return audioFormats;
  }

  List<VideoResolution> get availableResolutions {
    final List<VideoResolution> videoFormatDescriptions;

    switch (type) {
      case VideoType.youtube:
        videoFormatDescriptions = videoFormats
            .map((e) =>
                VideoResolution(formatNote: e.formatNote, height: e.height))
            .toSet()
            .toList();
        break;
      case VideoType.facebook:
        videoFormatDescriptions = videoFormats
            .map((e) =>
                VideoResolution(formatNote: '${e.height}p', height: e.height))
            .toSet()
            .toList();
        break;
      default:
        videoFormatDescriptions = videoFormats
            .map((e) =>
                VideoResolution(formatNote: e.formatNote, height: e.height))
            .toSet()
            .toList();
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

  static Future<VideoInfo> fromLink(String link) async {
    return YoutubeDLCommand.getVideoInfoFrom(link: link);
  }

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoInfoToJson(this);

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String digitHours = duration.inHours == 0 ? '' : '${duration.inHours}:';
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$digitHours$twoDigitMinutes:$twoDigitSeconds";
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

  void stopDownload() async {
    if (Platform.isWindows) {
      await killYouTubeDLOnWindows();
    }
    downloadShell.kill(ProcessSignal.sigkill);
    // restartDownloadShell();
    downloadShell = customShell();
  }

  Future killYouTubeDLOnWindows() async {
    // find youtube-dl child process
    final killShell = Shell();
    final cmd =
        'wmic process where (\'ParentProcessId=$currentDownloadPID\') get Caption,ProcessId'
            .crossPlatformCommand;
    logger.d(cmd);
    final result = await killShell.run(cmd).toResult(logError: true);
    final outlines = result.value!.outLines
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
    logger.d(outlines);
    // if not found return empty
    final youtubeDLPidInfo = outlines.firstWhere(
        (element) => element.contains('youtube-dl.exe'),
        orElse: () => '');

    if (youtubeDLPidInfo.isEmpty) {
      return;
    }

    final youtubeDlPID = youtubeDLPidInfo
        .split(' ')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList()
        .valueAt(index: 1);
    logger.d('youtube-dl pid $youtubeDlPID');
    final killCmd = 'taskkill /f /pid $youtubeDlPID'.crossPlatformCommand;
    logger.d(killCmd);
    await killShell.run(killCmd).toResult(logError: true);
  }

  Future downloadV2(
      {required String videoOutput,
      required void onEvent(VideoInfo event),
      required onError(String msg)}) async {
    setStartState();
    isLoading = true;
    onEvent(this);
    try {
      final controller = ShellLinesController();
      downloadShell = customShell(controller: controller);
      handleShellControllerStream(stream: controller.stream, onEvent: onEvent);
      await YoutubeDLCommand.downloadVideo(
          link: link,
          resolution: selectedResolutions.height,
          outputPath: videoOutput,
          cookiePath: type.cookieFile,
          isAudioOnly: isAudioOnly,
          isRecodeMp4: isConvertToMp4 && !isAudioOnly,
          controller: controller,
          downloadShell: downloadShell);
      setFinishDownloadState();
      onEvent(this);
    } on ShellException catch (e, trace) {
      logger.e(e.toErrorString, stackTrace: trace);
      setStartState();
      onEvent(this);
      onError('Error on downloading video:\n'
          '${e.toErrorString}');
    } catch (e, trace) {
      logger.e(e.toString(), stackTrace: trace);
      setStartState();
      onEvent(this);
      onError('Error on downloading video:\n'
          '${e.toString()}');
    }
  }

  void handleShellControllerStream(
      {required Stream<String> stream,
      required void onEvent(VideoInfo event)}) async {
    await for (final event in stream) {
      logger.d(event);
      if (event.contains('DownloadPID')) {
        currentDownloadPID = event.split(' ').valueAt(index: 1) ?? '';
        logger.d('got the pid: $currentDownloadPID ');
      }

      if (processingState.init(value: event) != VideoProcessingState.unknown) {
        processingState = processingState.init(value: event);
        onEvent(this);
      }

      // [download] <percent>% of <size>MiB at <currentTime>
      // [download] <percent>% of <size>MiB in <currentTime>
      // [download] <percent>% of <size>MiB
      if (event.contains('[download]') &&
          event.contains('of') &&
          event.contains('%')) {
        String percent;
        try {
          percent = event
              .split(' ')
              .firstWhere((element) => element.contains('%'))
              .split('%')
              .first;
        } catch (e, trace) {
          logger.e('Cannot extract download percent from event:\n$event', stackTrace: trace);
          throw Exception(
              'Cannot extract download percent from event:\n$event');
        }

        // logger.e(percent);
        downloadPercentage = double.parse(percent);
        if (double.parse(percent) == 100) {}
        onEvent(this);
      }
    }
  }
}

class VideoResolution {
  String formatNote;
  int height;

  VideoResolution({required this.formatNote, required this.height});

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
  VideoProcessingState init({required String value}) {
    if (value.contains('Destination:') &&
        (!value.contains('Converting video'))) {
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
