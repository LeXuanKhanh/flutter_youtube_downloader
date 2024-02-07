import 'package:flutter_youtube_downloader/extension/process_run_ex.dart';
import 'package:flutter_youtube_downloader/extension/string_ex.dart';
import 'package:flutter_youtube_downloader/utils/common_path.dart';
import 'package:flutter_youtube_downloader/utils/desktop_command.dart';
import 'package:process_run/shell.dart';

class FfmpegCommand extends DesktopCommand {
  static Future<String?> getVersion() async {
    Shell shell = customShell();
    final cmd = '$ffmpegPath -version'.crossPlatformCommand;

    return shell.customRun(cmd).then((value) => value?.outLines.first
        .replaceFirst('ffmpeg version', '')
        .trim()
        .split(' ')
        .first);
  }
}
