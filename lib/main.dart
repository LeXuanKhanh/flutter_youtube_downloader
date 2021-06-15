import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_youtube_downloader/Extension/FutureEx.dart';
import 'package:flutter_youtube_downloader/VideoInfo.dart';
import 'package:process_run/shell.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_youtube_downloader/Extension/ListEx.dart';

import 'FutureResult.dart';
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
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var controller = ShellLinesController();
  var _inputController = TextEditingController();
  List<VideoInfo> videoList = [];
  late Shell shell;
  var isLoading = false;
  String? currentDownloadVideoId;
  String version = '';
  String videoLocation = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Platform.isMacOS) {
      final env = Platform.environment;
      final dir = env['HOME']! + '/Documents';
      shell = Shell(stdout: controller.sink, verbose: false, workingDirectory: dir);
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
        String? percent;
        VideoInfo? item;
        try {
          percent = event
              .split(' ')
              .firstWhere((element) => element.contains('%'))
              .split('%')
              .first;
          item = videoList
              .firstWhere((element) => element.id == currentDownloadVideoId);
        } catch (e) {
          showSnackBar(e.toString());
        }

        // print(percent);
        if ((percent != null) && (item != null)) {
          setState(() {
            item!.downloadPercentage = double.parse(percent!);
            if (double.parse(percent) == 100) {
              item.isLoading = false;
            }
          });
        }
      }
    });

    test();
    Future.delayed(const Duration(milliseconds: 1000), () {
      checkYoutubeDL();
    });
    //checkYoutubeDL();
    getVideoLocation();
  }

  void test() async {
    final result = await shell.run('pwd');
    print(result.outText);
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
      showSnackBar(e.result?.stderr);
      log(e.result?.stderr);
    }
  }

  void downloadV2() async {
    for (var item in videoList) {
      final newController = ShellLinesController();
      final newShell = createShell(controller: newController);
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
          String? percent;
          try {
            percent = event
                .split(' ')
                .firstWhere((element) => element.contains('%'))
                .split('%')
                .first;
            item = videoList
                .firstWhere((element) => element.id == currentDownloadVideoId);
          } catch (e) {}

          // print(percent);
          if (percent != null) {
            final percentNotNull = percent;
            setState(() {
              item.downloadPercentage = double.parse(percentNotNull);
              if (double.parse(percentNotNull) == 100) {
                item.isLoading = false;
              }
            });
          }
        }
      });

      await newShell.run(
          '.\\youtube-dl --cookies ${item.type.cookieFile} -o $videoOutput \'${item.link}\''
              .crossPlatformCommand);
    }
  }

  Shell createShell({required ShellLinesController controller}) {
    //Platform.isMacOS
    final env = Platform.environment;
    final dir = env['HOME']! + '/Documents';
    var shell =
        Shell(stdout: controller.sink, verbose: false, workingDirectory: dir);

    if (Platform.isWindows) {
      shell = Shell(stdout: controller.sink, verbose: false);
    }

    return shell;
  }

  void showSnackBar(String text) {
    final snackBar = SnackBar(
        content: Wrap(
      direction: Axis.vertical,
      spacing: 8,
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
        error = (videoInfo.error as ShellException).toError.toString();
        log(error);
      } else {
        log(videoInfo.error.toString());
        log(videoInfo.stackTrace.toString());
      }

      showSnackBar("Error on getting video information: \n $error");
      return;
    }

    setState(() {
      videoList.add(videoInfo.value!);
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

    if (result.isError(onError: (error, stackTrace) {
      final title = "Can't check the version of youtube-dl";
      setState(() {
        version = title;
      });
      showSnackBar(title + '\n' + error);
    })) {
      return;
    }
    final value = result.value!;

    setState(() {
      version = value.outText.split('\n').first.toString();
    });
  }

  Future<VideoInfo> getVideoInfoFrom({required String link}) async {
    final type = VideoType.other.fromLinkString(link: link);
    final result = await shell.run(
        '.\\youtube-dl --cookies ${type.cookieFile} --get-title --get-id --get-thumbnail --get-duration  \'$link\''
            .crossPlatformCommand);

    if (result.errText.toString().isNotEmpty) {
      final error =
          ShellException('${result.errText.toString()}', result.first);
      throw error;
    }

    final List<String?> data = result.outText.toString().split("\n");
    print(result.outText);
    final title = data.valueAt(index: 0) ?? "";
    final id = data.valueAt(index: 1) ?? "";
    final thumbnail = data.valueAt(index:2) ?? "";
    // data?.firstWhere((element) => element.contains('http'), orElse: () => "");
    // pattern <number:number>
    final duration = data.valueAt(index: 3) ?? "";
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
    final result = await newShell.run('pwd'.crossPlatformCommand).toResult();

    if (result.isError(onError: (error, _) {
      showSnackBar(videoLocation + '\n' + error);
    })) {
      return;
    }
    final value = result.value!;

    // work around
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
        videoLocation = value.outText.split('----').last.trim() + '\\$VIDEO_FOLDER_NAME';
        return;
      });

      await newShell.run('mkdir -p $videoLocation'.crossPlatformCommand).toResult(logError: true);
      return;
    }

  }

  void openVideoLocation() async {
    final newShell = Shell(verbose: false);

    final String cmdOpenFolder; //MacOS
    if (Platform.isWindows) {
      cmdOpenFolder = 'start';
    } else {
      cmdOpenFolder = 'open';
    }

    final result = await newShell
        .run('$cmdOpenFolder $videoLocation'.crossPlatformCommand)
        .toResult();

    if (result.isError(onError: (error, _ ) {
      showSnackBar(videoLocation + '\n' + error);
    })) {
      return;
    }
  }

  void openLink(String link) async {
    final newShell = Shell(verbose: false);

    var cmdOpenFolder = 'open'; //MacOS
    if (Platform.isWindows) {
      cmdOpenFolder = 'explorer';
    }

    final result = await newShell.run('$cmdOpenFolder $link').toResult();

    if (result.isError(onError: (error, stackTrace) {
      showSnackBar(videoLocation + '\n' + error);
    })) {
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
                      child: Icon(Icons.folder), onPressed: openVideoLocation),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('V1.2.0 -'),
                TextButton(
                    style: ButtonStyle(
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                      foregroundColor: MaterialStateProperty.all(Colors.blue),
                    ),
                    child: Text('Github'),
                    onPressed: () => openLink(GITHUB_LINK))
              ],
            )
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

extension _FutureProcessResult on FutureResult<List<ProcessResult>> {
  bool isError({required Function(String, StackTrace?) onError }) {
    if (this.value == null) {
      if (this.error != null) {
        print('check youtube error');
        print((this.error as ShellException).message);
        final error = (this.error as ShellException).toError ??
            (this.error as ShellException).message;

        onError(error, stackTrace);
        //showSnackBar(title + '\n' + error);
        log((this.error as ShellException).toError.toString());
        log(this.stackTrace.toString());
        return true;
      }
    }

    final value = this.value!;
    if (value.errText.isNotEmpty) {
      final error = this.value!.errText;
      onError(error, stackTrace);

      //showSnackBar(title + '\n' + error);
      log(error);
      return true;
    }

    return false;
  }
}

extension ShellExceptionEx on ShellException {
  String? get toError => this.result?.stderr;
}

extension StringEx on String {
  String get crossPlatformCommand {
    if (Platform.isWindows) {
      return 'powershell -c "${this}"';
    }

    if (Platform.isMacOS) {
      if (this.contains('youtube-dl')) {
        return '/usr/local/bin/' + this.substring(2);
        //return this.substring(2); // work around
      }

      return this;
    }

    return this;
  }
}