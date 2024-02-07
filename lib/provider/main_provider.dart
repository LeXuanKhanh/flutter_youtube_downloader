import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_youtube_downloader/extension/future_ex.dart';
import 'package:flutter_youtube_downloader/extension/package_info_ex.dart';
import 'package:flutter_youtube_downloader/extension/process_run_ex.dart';
import 'package:flutter_youtube_downloader/global_variables.dart';
import 'package:flutter_youtube_downloader/main.dart';
import 'package:flutter_youtube_downloader/model/video_info.dart';
import 'package:flutter_youtube_downloader/network/network_manager.dart';
import 'package:flutter_youtube_downloader/utils/desktop_command.dart';
import 'package:flutter_youtube_downloader/utils/ffmpeg_command.dart';
import 'package:flutter_youtube_downloader/utils/youtubedl_command.dart';
import 'package:flutter_youtube_downloader/widget/common_snack_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

class MainProvider with ChangeNotifier {
  List<VideoInfo> videoList = [];
  var isLoading = false;
  String youtubeVersion = 'checking version';
  String videoLocation = '';
  String ffmpegVersion = 'checking version';
  String versionStatusTitle = '';
  String version = '';

  void _notify() {
    notifyListeners();
  }
}

extension Getter on MainProvider {
  bool get isCheckingComplete {
    return youtubeVersion.isNotEmpty &&
        ffmpegVersion.isNotEmpty &&
        youtubeVersion != 'checking version' &&
        ffmpegVersion != 'checking version';
  }

  bool get isCheckingValid {
    return isCheckingComplete &&
        !youtubeVersion.contains('can\'t check the version of') &&
        !ffmpegVersion.contains('can\'t check the version of');
  }

  String get videoOutput {
    if (Platform.isMacOS) {
      return '''\'$videoLocation/%(title)s_%(width)s_x_%(height)s.%(ext)s\'''';
    }

    if (Platform.isWindows) {
      return '\'$VIDEO_FOLDER_NAME/%(title)s_%(width)s_x_%(height)s.%(ext)s\'';
    }

    return '\'$VIDEO_FOLDER_NAME/%(title)s_%(width)s_x_%(height)s.%(ext)s\'';
  }
}

extension InitialCheck on MainProvider {
  void checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.versionNumber;

    version = currentVersion.toString();
    _notify();

    final result = await NetworkManager.shared.github
        .getReleaseDataList()
        .toResult(
            errorCallback: (err, _) => showSnackBar(
                "Error in checking new version: ${err.toString()}"));
    final githubVersion = result.value!.first.versionNumber;

    print(packageInfo.version);
    print(githubVersion);

    if (currentVersion.compareTo(githubVersion) < 0) {
      versionStatusTitle =
          "There is a new version available, you can download it on the github link above";
      _notify();
    }
  }

  void checkYoutubeDL() async {
    youtubeVersion = 'checking version';
    _notify();

    final result =
        await YoutubeDLCommand.getVersion().onError((error, stackTrace) {
      final shellError = error as ShellException;
      logger.e(shellError.toErrorString, stackTrace: stackTrace);
      final title = "can't check the version of youtube-dl";
      youtubeVersion = title;
      _notify();

      showSnackBar(title + '\n' + (shellError.toErrorString));
      return;
    });
    if (result == null) {
      return;
    }

    youtubeVersion = result;
    _notify();
  }

  void checkFFMPEG() async {
    ffmpegVersion = "checking version";
    _notify();

    final result =
        await FfmpegCommand.getVersion().onError((error, stackTrace) {
      final shellError = error as ShellException;
      logger.e(shellError.toErrorString, stackTrace: stackTrace);
      final title = "can't check the version of ffmpeg";
      ffmpegVersion = title;
      _notify();

      showSnackBar(title + '\n' + (shellError.toErrorString));
      return;
    });
    if (result == null) {
      return;
    }

    ffmpegVersion = result;
    _notify();
  }

  void getVideoLocation() async {
    videoLocation = 'getting location';
    _notify();

    final result =
        await DesktopCommand.getCurrentPath().onError((error, stackTrace) {
      final shellError = error as ShellException;
      logger.e(shellError.toErrorString, stackTrace: stackTrace);
      showSnackBar(videoLocation + '\n' + shellError.toErrorString);
      return;
    });
    if (result == null) {
      return;
    }

    // work around
    if ((Platform.isMacOS)) {
      final localPath = await documentsPath;
      if (localPath.isEmpty) {
        videoLocation = 'can\'t get video location on Mac OS';
        _notify();
        showSnackBar(videoLocation);
        return;
      }

      await DesktopCommand.createDirectory(videoLocation)
          .onError((error, stackTrace) {
        final shellError = error as ShellException;
        logger.e(shellError.toErrorString, stackTrace: stackTrace);
        videoLocation = 'create video directory failed';
        _notify();
        showSnackBar(
            'create video directory failed' + '\n' + shellError.toErrorString);
        return;
      });
      videoLocation = localPath + '/$VIDEO_FOLDER_NAME';
      _notify();

      return;
    }

    if (Platform.isWindows) {
      videoLocation = result + '\\$VIDEO_FOLDER_NAME';
      _notify();

      await DesktopCommand.createDirectory(videoLocation)
          .onError((error, stackTrace) {
        final shellError = error as ShellException;
        logger.e(shellError.toErrorString, stackTrace: stackTrace);
        videoLocation = 'create video directory failed';
        _notify();
        showSnackBar(
            'create video directory failed' + '\n' + shellError.toErrorString);
        return;
      });
      return;
    }
  }

  Future<String> get documentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}

extension VideoFeature on MainProvider {
  void downloadAllVideo() async {
    for (var item in videoList) {
      downloadSingleVideo(item);
    }
  }

  void downloadSingleVideo(VideoInfo item) async {
    downloadVideoInfoV2(item);
  }

  void downloadVideoInfoV2(VideoInfo item) async {
    await item.downloadV2(
        videoOutput: videoOutput,
        onEvent: (event) => _notify(),
        onError: (msg) => showSnackBar(msg));
  }

  void addToQueue(String text) async {
    if (!isCheckingComplete) {
      return;
    }

    if (text.isEmpty) {
      return;
    }
    isLoading = true;
    _notify();

    final link = text;
    try {
      final videoInfo = await VideoInfo.fromLink(link);
      isLoading = false;
      videoList.add(videoInfo);
      _notify();
    } on ShellException catch (e, trace) {
      isLoading = false;

      showSnackBar(
          'Error on getting video information: \n${e.toErrorString} ${trace.toString()}');
    } catch (e, trace) {
      isLoading = false;
      logger.e(e.toString(), stackTrace: trace);
      showSnackBar(
          'Error on getting video information: \n${e.toString()} ${trace.toString()}');
      _notify();
    }
  }

  void removeFromQueue(int index) {
    videoList.removeAt(index);
    _notify();
  }
}
