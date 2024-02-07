import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_youtube_downloader/extension/process_run_ex.dart';
import 'package:flutter_youtube_downloader/extension/string_ex.dart';
import 'package:flutter_youtube_downloader/global_variables.dart';
import 'package:flutter_youtube_downloader/model/video_info.dart';
import 'package:flutter_youtube_downloader/utils//common_path.dart';
import 'package:flutter_youtube_downloader/utils/desktop_command.dart';
import 'package:process_run/shell.dart';

class YoutubeDLCommand extends DesktopCommand {
  static final defaultVideoExt = DEFAULT_VIDEO_EXTENSION;
  static final defaultAudioExt = DEFAULT_AUDIO_EXTENSION;

  static Future<String?> getVersion() {
    Shell shell = customShell();
    final cmd = '$youtubeDlPath --version'.crossPlatformCommand;

    return shell.customRun(cmd).then((value) {
      return value?.outText.split('\n').first.toString();
    });
  }

  static Future<VideoInfo> getVideoInfoFrom({required String link}) async {
    Shell shell = customShell();
    final type = VideoType.other.fromLinkString(link: link);
    final cmd = '$youtubeDlPath '
            '--no-warnings '
            '--cookies ${type.cookieFile} '
            '--dump-single-json \'$link\''
        .crossPlatformCommand;
    final result = await shell.customRun(cmd);
    if (result == null) {
      throw Exception('result return null value');
    }
    final json = jsonDecode(result.outText);
    if (!(json is Map<String, dynamic>)) {
      log('value.outText is not Map<String, dynamic> ${result.outText}');
      throw Exception(
          'value.outText is not Map<String, dynamic> ${result.outText}');
    }
    if (json.isEmpty) {
      log('value.outText json is empty ${result.outText}');
      throw Exception(
          'value.outText is not Map<String, dynamic> ${result.outText}');
    }
    VideoInfo videoInfo;
    if ((type == VideoType.facebook) &&
        (json['entries'] != null && json['entries'] is List<dynamic>)) {
      final entries = json['entries'] as List<dynamic>;
      videoInfo = VideoInfo.fromJson(entries.first as Map<String, dynamic>);
      //log((entries.first as Map<String, dynamic>).toPrettyString);
    } else {
      videoInfo = VideoInfo.fromJson(json);
      //log(json.toPrettyString);
    }
    //log(videoInfo.availableResolutions.toString());
    return videoInfo;
  }

  static Future<List<ProcessResult>> downloadVideo({
    required String link,
    required int resolution,
    required String outputPath,
    required String cookiePath,
    required ShellLinesController controller,
    bool isAudioOnly = false,
    isRecodeMp4 = false,
    Shell? downloadShell,
  }) {
    Shell shell;
    if (downloadShell != null) {
      shell = downloadShell;
    } else {
      shell = customShell(controller: controller);
    }

    final forceAVC = Platform.isMacOS ? '[vcodec^=avc]' : '';
    final video = '\'bestvideo'
        '[height=$resolution]'
        '$forceAVC'
        '[ext=$defaultVideoExt]'
        '+bestaudio'
        '[ext=$defaultAudioExt]'
        '/bestvideo'
        '[height<=$resolution]'
        '+bestaudio'
        '/best\' ';
    final format = isAudioOnly ? 'bestaudio[ext=$defaultAudioExt] ' : video;
    final recodeMp4 = isRecodeMp4 ? '--recode mp4 ' : '';

    final pidCmd = 'echo (\'DownloadPID \' + \$PID)';
    final downloadCmd = '$youtubeDlPath '
        '--no-warnings '
        '--cookies $cookiePath '
        '--ffmpeg-location \'$ffmpegPath\' '
        '-f '
        '$format'
        '$recodeMp4'
        '-o $outputPath \'$link\'';
    final String cmd;

    if (Platform.isWindows) {
      cmd = '$pidCmd;$downloadCmd';
    } else {
      cmd = '$downloadCmd';
    }

    log(cmd.crossPlatformCommand);
    return shell
        .run(cmd.crossPlatformCommand)
        .whenComplete(() => controller.close());
  }
}
