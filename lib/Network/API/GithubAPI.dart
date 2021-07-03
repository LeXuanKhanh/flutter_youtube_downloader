
import 'package:dio/dio.dart';
import 'package:flutter_youtube_downloader/Model/GithubReleaseData.dart';
import 'package:retrofit/retrofit.dart';

part 'GithubAPI.g.dart';

@RestApi(baseUrl: "https://api.github.com/")
abstract class GithubAPI {
  factory GithubAPI(Dio dio, {String baseUrl}) = _GithubAPI;

  @GET("/repos/LeXuanKhanh/flutter_youtube_downloader/releases")
  Future<List<GithubReleaseData>> getReleaseDataList();
}