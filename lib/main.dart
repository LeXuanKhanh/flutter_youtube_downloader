import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_youtube_downloader/Extension/FutureEx.dart';
import 'package:flutter_youtube_downloader/VideoInfo.dart';
import 'package:process_run/shell.dart';
import 'package:path_provider/path_provider.dart';

import 'GlobalVariables.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Youtube Downloader',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Flutter Youtube Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var controller = ShellLinesController();
  var _inputController = TextEditingController();
  List<VideoInfo> videoList = [];
  Shell shell;
  var isLoading = false;
  String currentDownloadVideoId;
  String version = '';
  String videoLocation = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Platform.isMacOS) {
      final env = Platform.environment;
      final dir = env['HOME'] + '/Documents';
      shell =
          Shell(stdout: controller.sink, verbose: false, workingDirectory: dir);
    }

    if (Platform.isWindows) {
      shell = Shell(stdout: controller.sink, verbose: false);
    }

    controller.stream.listen((event) {
      //print(event);
      if (currentDownloadVideoId == null) {
        return;
      }

      // [download] <percent>% of <size>MiB at <currentTime>
      // [download] <percent>% of <size>MiB in <currentTime>
      // [download] <percent>% of <size>MiB
      if (event.contains('[download]') &&
          event.contains('of') &&
          event.contains('%')) {
        final percent = event
            .split(' ')
            .firstWhere((element) => element.contains('%'))
            .split('%')
            .first;
        final item = videoList
            .firstWhere((element) => element.id == currentDownloadVideoId);
        // print(percent);
        if ((percent != null) && (item != null)) {
          setState(() {
            item.downloadPercentage = double.parse(percent);
            if (double.parse(percent) == 100) {
              item.isLoading = false;
            }
          });
        }
      }
    });

    checkYoutubeDL();
    getVideoLocation();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    shell.kill();
  }

//  void changeDirectory() async {
//    try {
//      shell = shell.pushd('test');
//      final result = await shell.run("powershell -c pwd");
//      for (var item in result) {
//        print(item.stdout.toString().split("\n"));
//      }
//    } on ShellException catch (e) {
//      // We might get a shell exception
//      log('error');
//      log(e.result.stderr);
//    }
//  }

  void download() async {
    try {
      print("begin to download");
      for (var item in videoList) {
        currentDownloadVideoId = item.id;
        item.downloadPercentage = 0;
        setState(() {
          item.isLoading = true;
        });
        await shell.run(
            '.\\youtube-dl --cookies ${item.type.cookieFile} -o $videoOutput \'${item.link}\''
                .crossPlatformCommand);
      }
    } on ShellException catch (e) {
      // We might get a shell exception
      log('error');
      showSnackBar(e.result.stderr);
      log(e.result.stderr);
    }
  }

  void showSnackBar(String text) {
    final snackBar = SnackBar(
        content: Wrap(
          direction: Axis.vertical,
          children: [
            Text(text),
            OutlinedButton(
                child: Text('Copy Error'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                })
          ],
        ));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void addToQueue() async {
    if (_inputController.text.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final link = _inputController.text;

    final videoInfo = await getVideoInfoFrom(link: link).toResult();

    setState(() {
      isLoading = false;
    });

    // have error
    if (videoInfo.error != null) {
      var error = videoInfo.error.toString();
      if (videoInfo.error is ShellException) {
        error = (videoInfo.error as ShellException).toErrorString;
        log(error);
      } else {
        log(videoInfo.error.toString());
        log(videoInfo.stackTrace.toString());
      }

      showSnackBar("Error on getting video information: \n $error");
      return;
    }

    setState(() {
      videoList.add(videoInfo.value);
    });
  }

  void removeFromQueue(int index) {
    setState(() {
      videoList.removeAt(index);
    });
  }

  void checkYoutubeDL() async {
    setState(() {
      version = 'Checking version';
    });
    final result = await shell
        .run('.\\youtube-dl --version'.crossPlatformCommand)
        .toResult();

    if (result.error != null) {
      final error2 = (result.error as ShellException).toErrorString;
      final title = "Can't check the version of youtube-dl";
      setState(() {
        version = title;
      });
      showSnackBar(title + '\n' + error2);
      log((result.error as ShellException).toErrorString);
      log(result.stackTrace.toString());
      return;
    }

    if (result.value.errText.isNotEmpty) {
      final error = result.value.errText;
      final title = "Can't check the version of youtube-dl";
      setState(() {
        version = title;
      });
      showSnackBar(title + '\n' + error);
      log(error);
      return;
    }

    setState(() {
      version = result.value.outText.split('\n').first.toString();
    });
  }

  Future<VideoInfo> getVideoInfoFrom({@required String link}) async {
    final type = VideoType.other.fromLinkString(link: link);
    final result = await shell.run(
        '.\\youtube-dl --cookies ${type.cookieFile} --get-title --get-id --get-thumbnail --get-duration  \'$link\''
            .crossPlatformCommand);

    if (result.errText.toString().isNotEmpty) {
      final error =
          ShellException('${result.errText.toString()}', result.first);
      throw error;
    }

    final data = result.outText.toString()?.split("\n");
    final title = data[0] ?? "";
    final id = data[1] ?? "";
    final thumbnail = data[2] ?? "";
    // data?.firstWhere((element) => element.contains('http'), orElse: () => "");
    // pattern <number:number>
    final duration = data[3] ?? "";
    //data?.firstWhere((element) => element.contains('[0-9]+\:+[0-9]'), orElse: () => "");

    return VideoInfo(
        link: link,
        title: title,
        thumbnail: thumbnail,
        duration: duration,
        id: id);
  }

  void getVideoLocation() async {
    setState(() {
      videoLocation = 'getting location';
    });

    final newShell = Shell(verbose: false);
    var result = await newShell.run('pwd'.crossPlatformCommand).toResult();

    if (result.error != null) {
      setState(() {
        videoLocation = '''can't get video location''';
      });
      showSnackBar(videoLocation + '\n' + (result.error as ShellException).toErrorString);
      return;
    }

    if (result.value.errText.isNotEmpty) {
      setState(() {
        videoLocation = '''can't get video location''';
      });
      showSnackBar(videoLocation + '\n' + result.value.errText);
      return;
    }

    // work around
    // if ((Platform.isMacOS) && videoLocation == '/') {
    if ((Platform.isMacOS)) {
      final localPath = await documentsPath;
      if (localPath.isEmpty) {
        setState(() {
          videoLocation = '''can't get video location''';
        });
        showSnackBar(
            videoLocation + '\n' + 'can\'t find local desktop path on Mac OS');
        return;
      }

      setState(() {
        videoLocation = localPath + '/$VIDEO_FOLDER_NAME';
      });

      await newShell.run('mkdir -p $videoLocation'.crossPlatformCommand).toResult(logError: true);
      return;
    }

    if (Platform.isWindows) {
      setState(() {
        videoLocation = result.value.outText.split('----').last.trim() + '\\$VIDEO_FOLDER_NAME';
        return;
      });

      await newShell.run('mkdir -p $videoLocation'.crossPlatformCommand).toResult(logError: true);
      return;
    }

  }

  void openVideoLocation() async {
    final newShell = Shell(verbose: false);

    var cmdOpenFolder = 'open'; //MacOS
    if (Platform.isWindows) {
      cmdOpenFolder = 'start';
    }

    var result = await newShell
        .run('$cmdOpenFolder $videoLocation'.crossPlatformCommand)
        .toResult();

    if (result.error != null) {
      showSnackBar(videoLocation + '\n' + (result.error as ShellException).toErrorString);
      return;
    }

    if (result.value.errText.isNotEmpty) {
      showSnackBar(videoLocation + '\n' + result.value.errText);
      return;
    }
  }

  void openLink(String link) async {
    final newShell = Shell(verbose: false);

    var cmdOpenFolder = 'open'; //MacOS
    if (Platform.isWindows) {
      cmdOpenFolder = 'explorer';
    }

    var result = await newShell
        .run('$cmdOpenFolder $link')
        .toResult();

    if (result.error != null) {
      showSnackBar(videoLocation + '\n' + (result.error as ShellException).toErrorString);
      return;
    }

    if (result.value.errText.isNotEmpty) {
      showSnackBar(videoLocation + '\n' + result.value.errText);
      return;
    }
  }

  Future<String> get documentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  String get videoOutput {
    if (Platform.isMacOS) {
      return '''\'$videoLocation/%(title)s.%(ext)s\'''';
    }

    if (Platform.isWindows) {
      return '\'$VIDEO_FOLDER_NAME/%(title)s.%(ext)s\'';
    }

    return '\'$VIDEO_FOLDER_NAME/%(title)s.%(ext)s\'';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: <Widget>[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              title: TextField(
                controller: _inputController,
                decoration: InputDecoration(hintText: 'Input a video link'),
                maxLines: null,
              ),
              trailing: isLoading
                  ? CircularProgressIndicator()
                  : IconButton(icon: Icon(Icons.search), onPressed: null),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Youtube-dl version: '),
                Expanded(child: Text(version)),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                      child: Icon(Icons.refresh), onPressed: checkYoutubeDL),
                )
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('Video Location: '),
                Expanded(child: SelectableText(videoLocation)),
                SizedBox(
                        width: 44,
                        height: 44,
                        child: ElevatedButton(
                            child: Icon(Icons.folder),
                            onPressed: openVideoLocation),
                      ),
                SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                      child: Icon(Icons.refresh), onPressed: getVideoLocation),
                ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                  child: Text('Add to Queue'), onPressed: addToQueue),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: videoList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = videoList[index];
                    return Column(
                      children: [
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 0),
                          leading: item.thumbnail.isNotEmpty
                              ? SizedBox(
                                  height: 400,
                                  child: Image.network(item.thumbnail),
                                )
                              : SizedBox(width: 100, height: 100),
                          title: Text(item.title),
                          subtitle: Text(item.duration),
                          trailing: item.isLoading
                              ? CircularProgressIndicator()
                              : IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    removeFromQueue(index);
                                  }),
                        ),
                        item.downloadPercentage != 0
                            ? LinearProgressIndicator(
                                value: item.downloadPercentage / 100)
                            : SizedBox(),
                      ],
                    );
                  }),
            ),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                child: Text('Download'),
                onPressed: download,
              ),
            ),
            SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyText1,
                children: <TextSpan>[
                  TextSpan(text: 'V1.1.0 - '),
                  TextSpan(
                      text: 'Github',
                      style: TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => openLink(GITHUB_LINK)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ProcessResultEx on ProcessResult {
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

extension ShellExceptionEx on ShellException {
  String get toErrorString => this.result.stderr.toString();
}

extension StringEx on String {
  String get crossPlatformCommand {
    if (Platform.isWindows) {
      return 'powershell -c "${this}"';
    }

    if (Platform.isMacOS) {
      if (this.contains('youtube-dl')) {
        //return '/usr/local/bin/' + this.substring(2);
        return this.substring(2); // work around
      }

      return this;
    }

    return this;
  }
}
