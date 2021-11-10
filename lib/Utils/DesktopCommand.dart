import 'package:process_run/shell.dart';
import 'dart:io';

import 'package:flutter_youtube_downloader/Extension/ProcessRunEx.dart';
import 'package:flutter_youtube_downloader/Extension/StringEx.dart';

class DesktopCommand {
  Shell shell = customShell();

  Future openFolder(String folderPath) async {
    final String cmdOpenFolder;
    if (Platform.isWindows) {
      cmdOpenFolder = 'start';
    } else {
      cmdOpenFolder = 'open';
    }

    return shell.run('$cmdOpenFolder $folderPath'.crossPlatformCommand);
  }

  Future openLink(String link) async {
    final String cmdOpenFolder;
    if (Platform.isWindows) {
      cmdOpenFolder = 'explorer';
    } else {
      cmdOpenFolder = 'open';
    }
    
    return shell.run('$cmdOpenFolder $link');
  }

  Future createDirectory(String directoryName) async {
    return shell
        .customRun('mkdir -p $directoryName'.crossPlatformCommand);
  }

  Future<String?> getCurrentPath() async {
    return shell.customRun('pwd'.crossPlatformCommand).then((value) {
      if (Platform.isWindows) {
        return value?.outText.split('----').last.trim();
      }

      return value?.outText;
    });
  }

}