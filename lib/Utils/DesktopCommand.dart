import 'package:process_run/shell.dart';
import 'dart:io';

import 'package:flutter_youtube_downloader/Extension/ProcessRunEx.dart';
import 'package:flutter_youtube_downloader/Extension/StringEx.dart';

class DesktopCommand {
  static Future openFolder(String folderPath) async {
    Shell shell = customShell();
    final String cmdOpenFolder;
    if (Platform.isWindows) {
      cmdOpenFolder = 'start';
    } else {
      cmdOpenFolder = 'open';
    }

    return shell.run('$cmdOpenFolder $folderPath'.crossPlatformCommand);
  }

  static Future openLink(String link) async {
    Shell shell = customShell();
    final String cmdOpenFolder;
    if (Platform.isWindows) {
      cmdOpenFolder = 'explorer';
    } else {
      cmdOpenFolder = 'open';
    }
    
    return shell.run('$cmdOpenFolder $link');
  }

  static Future createDirectory(String directoryName) async {
    Shell shell = customShell();
    return shell
        .customRun('mkdir -p $directoryName'.crossPlatformCommand);
  }

  static Future<String?> getCurrentPath() async {
    Shell shell = customShell();
    return shell.customRun('pwd'.crossPlatformCommand).then((value) {
      if (Platform.isWindows) {
        return value?.outText.split('----').last.trim();
      }

      return value?.outText;
    });
  }

}