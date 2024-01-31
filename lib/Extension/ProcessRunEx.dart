import 'dart:developer';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_youtube_downloader/Extension/MapEx.dart';
import 'package:flutter_youtube_downloader/Utils/CommonPath.dart';
import 'package:process_run/shell.dart';

import 'package:flutter_youtube_downloader/Model/FutureResult.dart';

Shell customShell({ShellLinesController? controller}) {
  Shell shell = Shell();
  if (Platform.isMacOS) {
    final envJson = {
      'paths': ['/usr/local/bin', '/Users/macbook/Projects/']
    };
    final customEnv = ShellEnvironment.fromJson(envJson);
    final platformEnv = Platform.environment;
    final dir = platformEnv['HOME']! + '/Documents';

    if (controller == null) {
      shell =
          Shell(verbose: false, workingDirectory: dir, environment: customEnv);
    } else {
      shell = Shell(
          stdout: controller.sink,
          verbose: false,
          workingDirectory: dir,
          environment: customEnv);
    }
  }

  // Windows, Linux
  if (Platform.isWindows) {
    if (controller == null) {
      shell = Shell(verbose: false);
    } else {
      shell = Shell(stdout: controller.sink, verbose: false);
    }
  }

  return shell;
}

extension ProcessResultEx on ProcessResult {
  Map<String, Object> get toJson {
    final error = stderr.toString();
    final result = stdout.toString();
    return {
      'exitCode': exitCode,
      'stdout': result,
      'stderr': error,
      'pid': pid
    };
  }
}

extension FutureProcessResult on FutureResult<List<ProcessResult>> {
  bool isError({required Function(String, StackTrace?) onError}) {
    if (this.value == null) {
      if (this.error != null) {
        log((this.error as ShellException).message);
        final error = (this.error as ShellException).toError ??
            (this.error as ShellException).message;

        onError(error, stackTrace);
        log((this.error as ShellException).toError.toString());
        log(StackTrace.current.toString());
        return true;
      }
    }

    final value = this.value!;
    if (value.errText.isNotEmpty) {
      final error = this.value!.errText;
      onError(error, stackTrace);
      log(error);
      log(StackTrace.current.toString());
      return true;
    }

    return false;
  }
}

extension ShellExceptionEx on ShellException {
  String? get toError => this.result?.stderr;

  String get toErrorString => this.result?.stderr ?? this.message;
}

extension ShellEx on Shell {
  Future<List<ProcessResult>?> customRun(String script,
      {void Function(Process process)? onProcess}) async {
    final result = await this.run(script, onProcess: onProcess);

    if (result.errText.isNotEmpty) {
      final error = result.errText;
      log(error);
      log(StackTrace.current.toString());
      throw error;
    }

    return result;
  }
}
