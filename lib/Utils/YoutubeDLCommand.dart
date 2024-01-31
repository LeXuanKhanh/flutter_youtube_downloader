import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_youtube_downloader/Extension/MapEx.dart';
import 'package:flutter_youtube_downloader/Utils/CommonPath.dart';
import 'package:process_run/shell.dart';

import 'package:flutter_youtube_downloader/Utils/DesktopCommand.dart';
import 'package:flutter_youtube_downloader/Extension/StringEx.dart';
import 'package:flutter_youtube_downloader/Model/VideoInfo.dart';
import 'package:flutter_youtube_downloader/Extension/ProcessRunEx.dart';

class YoutubeDLCommand extends DesktopCommand {
  var defaultVideoExt = 'mp4';
  var defaultAudioExt = 'm4a';

  Future<String?> getVersion() {
    final cmd = '$youtubeDlPath --version'.crossPlatformCommand;

    return shell
        .customRun(cmd)
        .then((value) {
          return value?.outText.split('\n').first.toString();
        });
  }

  Future<VideoInfo?> getVideoInfoFrom({required String link}) {
    final type = VideoType.other.fromLinkString(link: link);

    final cmd = '$youtubeDlPath '
        '--no-warnings '
        '--cookies ${type.cookieFile} '
        '--dump-single-json \'$link\''
        .crossPlatformCommand;

    return shell.customRun(cmd).then((value) {

      if (value == null) {
        return null;
      }

      final json = jsonDecode(value.outText);

      if (!(json is Map<String, dynamic>)) {
        log('value.outText is not Map<String, dynamic> ${value.outText}');
        return null;
      }

      if (json.isEmpty) {
        log('value.outText json is empty ${value.outText}');
        return null;
      }

      VideoInfo? videoInfo;
      if ((type == VideoType.facebook) &&
          (json['entries'] != null && json['entries'] is List<dynamic>)) {
        final entries = json['entries'] as List<dynamic>;
        videoInfo = VideoInfo.fromJson(entries.first as Map<String, dynamic>);
        log((entries.first as Map<String, dynamic>).toPrettyString);
      } else {
        videoInfo = VideoInfo.fromJson(json);
        log(json.toPrettyString);
      }

      log(videoInfo.availableResolutions.toString());
      return videoInfo;
    });
  }

  ShellLinesController downloadVideo(VideoInfo videInfo, String outputPath) {
    final shellLinesController = ShellLinesController();
    shell = customShell(controller: shellLinesController);

    final video = '\'bestvideo[height=${videInfo.selectedResolutions.height}]'
        '[ext=$defaultVideoExt]+'
        'bestaudio[ext=$defaultAudioExt]'
        '/bestvideo[height<=${videInfo.selectedResolutions.height}]+bestaudio'
        '/best\' ';
    final format = videInfo.isAudioOnly ? 'bestaudio[ext=$defaultAudioExt] ' : video;
    final recodeMp4 = (videInfo.isConvertToMp4 && !videInfo.isAudioOnly) ? '--recode mp4 ' : '';

    final pidCmd = 'echo (\'DownloadPID \' + \$PID)';
    final downloadCmd = '$youtubeDlPath '
        '--no-warnings '
        '--cookies ${videInfo.type.cookieFile} '
        '-f '
        '$format'
        '$recodeMp4'
        '-o $outputPath \'${videInfo.link}\'';
    final String cmd;

    if (Platform.isWindows) {
      cmd = '$pidCmd;$downloadCmd';
    } else {
      cmd = '$downloadCmd';
    }

    log(cmd.crossPlatformCommand);
    shell.run(cmd.crossPlatformCommand);

    return shellLinesController;
  }

}
