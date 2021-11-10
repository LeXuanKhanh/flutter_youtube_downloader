import 'package:process_run/shell.dart';

import 'package:flutter_youtube_downloader/Utils/DesktopCommand.dart';
import 'package:flutter_youtube_downloader/Extension/StringEx.dart';
import 'package:flutter_youtube_downloader/Extension/ProcessRunEx.dart';

class FFmpegCommand extends DesktopCommand {
  Future<String?> getVersion() async {

    final cmd = 'ffmpeg -version'.crossPlatformCommandTest;

    return shell.customRun(cmd).then((value) =>
        value?.outLines.first
            .replaceFirst('ffmpeg version', '')
            .trim()
            .split(' ')
            .first);
  }
}
