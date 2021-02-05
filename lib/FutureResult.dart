import 'package:flutter/material.dart';

class FutureResult<T> {
  T value;
  dynamic error;
  StackTrace stackTrace;

  FutureResult({
    @required this.value,
    @required this.error,
    @required this.stackTrace
  });

}