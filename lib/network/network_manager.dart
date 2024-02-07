import 'package:dio/dio.dart';
import 'package:flutter_youtube_downloader/network/API/github_api.dart';

class NetworkManager {
  static NetworkManager? _instance;
  late final Dio _dio = _initDio();
  late final GithubAPI github;

  NetworkManager._internal() {
    github = GithubAPI(_dio);
  }

  Dio _initDio() {
    final dio = Dio();
    // dio.interceptors.add(PrettyDioLogger(
    //   requestHeader: true,
    //   requestBody: true,
    //   responseBody: true,
    // ));
    return dio;
  }

  static NetworkManager get shared => _instance ??= NetworkManager._internal();
}
