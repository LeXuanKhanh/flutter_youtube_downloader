import 'dart:developer';

import 'package:flutter_youtube_downloader/model/future_result.dart';

extension FutureEx<T> on Future<T> {
  Future<FutureResult<T>> toResult(
      {bool logError = true,
      void errorCallback(dynamic error, StackTrace trace)?}) async {
    try {
      final result = await this;
      return FutureResult<T>(value: result, error: null, stackTrace: null);
    } catch (e, stacktrace) {
      if (logError) {
        log('Future toResult $T get error');
        log(e.toString());
        log(stacktrace.toString());
      }

      if (errorCallback != null) {
        errorCallback(e, stacktrace);
      }

      return FutureResult<T>(value: null, error: e, stackTrace: stacktrace);
    }
  }
}
