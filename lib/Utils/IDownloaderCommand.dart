import 'package:flutter_youtube_downloader/Model/VideoInfo.dart';

abstract class IDownloaderCommand {
  Future<String?> getVersion();
  Future<VideoInfo?> getVideoInfoFrom({required String link});
}