import 'package:dio/dio.dart';
import 'package:flutter_youtube_downloader/model/github_release_data.dart';
import 'package:retrofit/retrofit.dart';

part 'github_api.g.dart';

@RestApi(baseUrl: "https://api.github.com/")
abstract class GithubAPI {
  factory GithubAPI(Dio dio, {String baseUrl}) = _GithubAPI;

  @GET("/repos/LeXuanKhanh/flutter_youtube_downloader/releases")
  Future<List<GithubReleaseData>> getReleaseDataList();
}
