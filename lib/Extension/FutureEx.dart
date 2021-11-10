import 'dart:developer';
import 'package:flutter_youtube_downloader/Model/FutureResult.dart';

extension FutureEx<T> on Future<T> {
  Future<FutureResult<T>> toResult({bool logError = false}) async {
    try {
      final result = await this;
      return FutureResult<T>(value: result, error: null, stackTrace: null);
    } catch (e, stacktrace) {
      if (logError) {
        log('Future toResult $T get error');
        log(e.toString());
        log(stacktrace.toString());
      }
      return FutureResult<T>(value: null, error: e, stackTrace: stacktrace);
    }
  }


}