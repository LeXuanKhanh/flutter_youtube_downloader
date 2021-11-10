import 'dart:io';

extension StringEx on String {
  String get crossPlatformCommand {
    if (Platform.isWindows) {
      return 'powershell -c "${this}"';
    }

    if (Platform.isMacOS) {
      if (this.contains('youtube-dl') || (this.contains('ffmpeg'))) {
        return '/usr/local/bin/' + this.substring(2);
        //return 'zsh -c "${this.substring(2)}"';
      }

      return 'zsh -c "${this}"';
    }

    return this;
  }

  String get crossPlatformCommandTest {
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