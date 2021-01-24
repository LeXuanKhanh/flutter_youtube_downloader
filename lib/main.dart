import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_youtube_downloader/VideoInfo.dart';
import 'package:process_run/shell.dart';
import 'package:tuple/tuple.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Youtube-dl Downloader',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Flutter Youtube-dl Downloader'),
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    shell = Shell(stdout: controller.sink, verbose: false);
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
            '.\\youtube-dl --cookies ${item.type.cookieFile} -o \'video/%(title)s.%(ext)s\' \'${item.link}\''
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
    final snackBar = SnackBar(content: Text(text));
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

    final videoInfo = await getVideoInfoFrom(link: link).toTuple();

    setState(() {
      isLoading = false;
    });

    // have error
    if (videoInfo.item2 != null) {
      var error = videoInfo.item2.toString();
      if (videoInfo.item2 is ShellException) {
        error = (videoInfo.item2 as ShellException).toErrorString;
        log(error);
      } else {
        log(videoInfo.item2.toString());
        log(videoInfo.item3.toString());
      }

      showSnackBar("Error on getting video infomation: \n $error");
      return;
    }

    setState(() {
      videoList.add(videoInfo.item1);
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
        .toTuple();

    if (result.item2 != null) {
      final error2 = result.item2.toString();
      final title =
          "Can't check the version of youtube-dl, did you have the youtube-dl.exe placed in the App location ?";
      setState(() {
        version = title;
      });
      showSnackBar(title + '\n' + error2);
      final error = result.item2;
      log(error.toString());
      return;
    }

    if (result.item1.first.stdout.toString().isEmpty) {
      final error = result.item1.first.stderr.toString();
      final title =
          "Can't check the version of youtube-dl, did you have the youtube-dl.exe placed in the App location?";
      setState(() {
        version = title;
      });
      showSnackBar(title + '\n' + error);
      log(error);
      return;
    }

    setState(() {
      version = result.item1.first.stdout.split('\n').first.toString();
    });
  }

  Future<VideoInfo> getVideoInfoFrom({@required String link}) async {
    final type = VideoType.other.fromLinkString(link: link);
    final result = await shell.run(
        '.\\youtube-dl --cookies ${type.cookieFile} --get-title --get-id --get-thumbnail --get-duration  \'$link\''
            .crossPlatformCommand);

    if (result.first.stderr.toString().isNotEmpty) {
      final error =
          ShellException('${result.first.stderr.toString()}', result.first);
      throw error;
    }

    final data = result.first?.stdout?.toString()?.split("\n");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            ListTile(
              title: TextField(
                controller: _inputController,
                decoration: InputDecoration(hintText: 'Input a video link'),
                maxLines: null,
              ),
              trailing: isLoading
                  ? Center(
                      child: Container(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : IconButton(icon: Icon(Icons.search), onPressed: null),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(version),
                  )),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: RaisedButton(
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        child: Icon(Icons.refresh),
                        onPressed: checkYoutubeDL),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 30,
                child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    child: Text('Add to Queue'),
                    onPressed: addToQueue),
              ),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: videoList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = videoList[index];
                    return Column(
                      children: [
                        ListTile(
                          leading: item.thumbnail.isNotEmpty
                              ? Image.network(item.thumbnail,
                                  height: 100, width: 100)
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
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: LinearProgressIndicator(
                                    value: item.downloadPercentage / 100),
                              )
                            : SizedBox(),
                      ],
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 30,
                child: RaisedButton(
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  child: Text('Download'),
                  onPressed: download,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ProcessResultEx on ProcessResult {
  Map<String, Object> get toJson {
    final error = stderr.toString();
    final result = stdout.toString();
    log(stderr.toString());
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
      return 'start /B powershell -windowstyle hidden -c "${this}"';
    }

    return this;
  }
}

extension FutureEx<T> on Future<T> {
  Future<Tuple3<T, dynamic, StackTrace>> toTuple(
      {bool logError = false}) async {
    try {
      final result = await this;
      return Tuple3(result, null, null);
    } catch (e, stacktrace) {
      if (logError) {
        log('Future get error on ');
        log(e.toString());
      }
      return Tuple3(null, e, stacktrace);
    }
  }
}
