import 'dart:io';

extension StringEx on String {
  String get crossPlatformCommand {
    if (Platform.isWindows) {
      // local executables
      if (this.startsWith('youtube-dl') || (this.startsWith('ffmpeg'))) {
        return 'powershell -c ".\\${this}"';
      }

      return 'powershell -c "${this}"';
    }

    if (Platform.isMacOS) {
      return 'zsh -c "${this}"';
    }

    return this;
  }

}