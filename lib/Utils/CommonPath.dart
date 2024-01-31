import 'dart:io';

String get youtubeDlPath {
  return CommonPath().youtubeDLPath;
}

String get ffmpegPath {
  return CommonPath().ffmpegPath;
}

class CommonPath {
  static final CommonPath _shared = CommonPath._internal();
  String appPath = '';
  String youtubeDLPath = '';
  String ffmpegPath = '';

  factory CommonPath() {
    return _shared;
  }

  CommonPath._internal() {
    String execPath = Platform.executable;
    final execPathArr = execPath.split('/');
    execPathArr.removeRange(execPathArr.length - 2 , execPathArr.length);
    appPath = execPathArr.join('/');
    youtubeDLPath = '$appPath/Resources/yt-dlp';
    ffmpegPath = '$appPath/Resources/ffmpeg';
  }
}