import 'dart:convert';
import 'dart:developer';
import 'package:process_run/shell.dart';

import 'package:flutter_youtube_downloader/Utils/DesktopCommand.dart';
import 'package:flutter_youtube_downloader/Extension/StringEx.dart';
import 'package:flutter_youtube_downloader/Model/VideoInfo.dart';
import 'package:flutter_youtube_downloader/Extension/ProcessRunEx.dart';

class YoutubeDLCommand extends DesktopCommand {
  Future<String?> getVersion() {
    final cmd = 'youtube-dl --version'.crossPlatformCommand;

    return shell
        .customRun(cmd)
        .then((value) {
          return value?.outText.split('\n').first.toString();
        });
  }

  Future<VideoInfo?> getVideoInfoFrom({required String link}) {
    final type = VideoType.other.fromLinkString(link: link);

    final cmd = 'youtube-dl '
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
      } else {
        videoInfo = VideoInfo.fromJson(json);
      }

      log(videoInfo.availableResolutions.toString());
      return videoInfo;
    });
  }
}
