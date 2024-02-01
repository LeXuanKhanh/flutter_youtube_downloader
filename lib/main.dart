import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:process_run/shell.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_youtube_downloader/Network/NetworkManager.dart';
import 'package:flutter_youtube_downloader/Utils/DesktopCommand.dart';
import 'package:flutter_youtube_downloader/Utils/FFmpegCommand.dart';
import 'package:flutter_youtube_downloader/Utils/YoutubeDLCommand.dart';
import 'package:flutter_youtube_downloader/Widget/VideoInfoCell.dart';
import 'package:flutter_youtube_downloader/GlobalVariables.dart';
import 'package:flutter_youtube_downloader/Extension/FutureEx.dart';
import 'package:flutter_youtube_downloader/Extension/ListEx.dart';
import 'package:flutter_youtube_downloader/Extension/ProcessRunEx.dart';
import 'package:flutter_youtube_downloader/Extension/PackageInfoEx.dart';

import 'package:flutter_youtube_downloader/Model/VideoInfo.dart';

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
  var _inputController = TextEditingController();
  List<VideoInfo> videoList = [];
  var isLoading = false;
  String? currentDownloadVideoId;
  String youtubeVersion = 'checking version';
  String videoLocation = '';
  String ffmpegVersion = 'checking version';
  String versionStatusTitle = '';
  String version = '';

  bool get isCheckingComplete {
    return youtubeVersion.isNotEmpty &&
        ffmpegVersion.isNotEmpty &&
        youtubeVersion != 'checking version' &&
        ffmpegVersion != 'checking version';
  }

  bool get isCheckingValid {
    return isCheckingComplete &&
        !youtubeVersion.contains('can\'t check the version of') &&
        !ffmpegVersion.contains('can\'t check the version of');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //_inputController.text = 'https://www.facebook.com/watch?v=889175572515263';
    //_inputController.text = 'https://www.youtube.com/watch?v=Xd5ESRqpz3E';
    // long video
    _inputController.text = 'https://www.youtube.com/watch?v=Z4XDMR4NWUg';

    Future.delayed(const Duration(milliseconds: 1000), () {
      checkYoutubeDL();
      checkFFMPEG();
    });
    getVideoLocation();
    checkVersion();
  }

  void checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.versionNumber;

    setState(() {
      version = currentVersion.toString();
    });

    final result = await NetworkManager.shared.github
        .getReleaseDataList()
        .toResult(logError: true);
    if (result.error != null) {
      showSnackBar("Error in checking new version: ${result.error.toString()}");
      return;
    }

    final githubVersion = result.value!.first.versionNumber;

    print(packageInfo.version);
    print(githubVersion);

    if (currentVersion.compareTo(githubVersion) < 0) {
      setState(() {
        versionStatusTitle =
            "There is a new version available, you can download it on the github link above";
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void downloadAllVideo() async {
    for (var item in videoList) {
      downloadSingleVideo(item);
    }
  }

  void downloadSingleVideo(VideoInfo item) async {
    downloadVideoInfoV2(item);
  }

  void downloadVideoInfoV2(VideoInfo item) async {
    await item.downloadV2(
        videoOutput: videoOutput,
        onEvent: (event) => this.setState(() {}),
        onError: (msg) => showSnackBar(msg));
  }

  void showSnackBar(String text) {
    final snackBar = SnackBar(
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
            child: Text('Copy Error'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
            }),
      )
    ]));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void addToQueue() async {
    if (!isCheckingComplete) {
      return;
    }

    if (_inputController.text.isEmpty) {
      return;
    }
    setState(() {
      isLoading = true;
    });

    final link = _inputController.text;
    try {
      final videoInfo = await VideoInfo.fromLink(link);
      setState(() {
        isLoading = false;
      });
      setState(() {
        videoList.add(videoInfo);
      });
    } on ShellException catch (e, trace) {
      setState(() {
        isLoading = false;
      });
      log(e.toErrorString);
      log(trace.toString());
      showSnackBar(
          'Error on getting video information: \n${e.toErrorString} ${trace.toString()}');
    } catch (e, trace) {
      setState(() {
        isLoading = false;
      });
      log(e.toString());
      log(trace.toString());
      showSnackBar(
          'Error on getting video information: \n${e.toString()} ${trace.toString()}');
    }
  }

  void removeFromQueue(int index) {
    setState(() {
      videoList.removeAt(index);
    });
  }

  void checkYoutubeDL() async {
    setState(() {
      youtubeVersion = 'checking version';
    });

    final result =
        await YoutubeDLCommand.getVersion().onError((error, stackTrace) {
      final shellError = error as ShellException;
      log(shellError.toErrorString);
      log(StackTrace.current.toString());

      final title = "can't check the version of youtube-dl";
      setState(() {
        youtubeVersion = title;
      });

      showSnackBar(title + '\n' + (shellError.toErrorString));
    });

    if (result == null) {
      return;
    }

    setState(() {
      youtubeVersion = result;
    });
  }

  void checkFFMPEG() async {
    setState(() {
      ffmpegVersion = "can't check the version of ffmpeg";
    });

    final result =
        await FFmpegCommand.getVersion().onError((error, stackTrace) {
      final shellError = error as ShellException;
      log(shellError.toErrorString);
      log(StackTrace.current.toString());

      final title = "can't check the version of ffmpeg";
      setState(() {
        ffmpegVersion = title;
      });

      showSnackBar(title + '\n' + (shellError.toErrorString));
    });

    if (result == null) {
      return;
    }

    setState(() {
      ffmpegVersion = result;
    });
  }

  void getVideoLocation() async {
    setState(() {
      videoLocation = 'getting location';
    });

    final result = await DesktopCommand.getCurrentPath()
        .onError((error, stackTrace) => null)
        .catchError((error) {
      showSnackBar(videoLocation + '\n' + error);
    });

    if (result == null) {
      return;
    }

    final value = result;

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

      await DesktopCommand.createDirectory(videoLocation)
          .toResult(logError: true);
      return;
    }

    if (Platform.isWindows) {
      setState(() {
        videoLocation = value + '\\$VIDEO_FOLDER_NAME';
        return;
      });

      await DesktopCommand.createDirectory(videoLocation)
          .toResult(logError: true);
      return;
    }
  }

  void openVideoLocation() async {
    DesktopCommand.openFolder(videoLocation)
        .catchError((error) => showSnackBar(videoLocation + '\n' + error));
  }

  void openLink(String link) {
    DesktopCommand.openLink(link);
  }

  Future<String> get documentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  String get videoOutput {
    if (Platform.isMacOS) {
      return '''\'$videoLocation/%(title)s_%(width)s_x_%(height)s.%(ext)s\'''';
    }

    if (Platform.isWindows) {
      return '\'$VIDEO_FOLDER_NAME/%(title)s_%(width)s_x_%(height)s.%(ext)s\'';
    }

    return '\'$VIDEO_FOLDER_NAME/%(title)s_%(width)s_x_%(height)s.%(ext)s\'';
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
                Expanded(child: Text(youtubeVersion)),
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
                Text('FFmpeg version: '),
                Expanded(child: Text(ffmpegVersion)),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                      child: Icon(Icons.refresh), onPressed: checkFFMPEG),
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
            isCheckingComplete && !isCheckingValid
                ? Text(
                    'The app must have both youtube-dl and ffmpeg installed to work, please run check again')
                : SizedBox(),
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
                    return VideoInfoCell(
                      item: item,
                      onRemoveButtonTap: () => removeFromQueue(index),
                      onSelectResolutionDropDown: (resolution) => setState(() {
                        item.selectedResolutions = resolution;
                      }),
                      onChangedIsAudioOnlyCheckBox: (bool) {
                        if (item.isAudioOnly != bool) {
                          setState(() {
                            item.isAudioOnly = bool!;
                          });
                        }
                      },
                      onChangedIsConvertToMp4CheckBox: (bool) {
                        if (item.isConvertToMp4 != bool) {
                          setState(() {
                            item.isConvertToMp4 = bool!;
                          });
                        }
                      },
                      onDownloadButtonTap: () => setState(() {
                        if (!item.isLoading) {
                          downloadSingleVideo(item);
                        } else {
                          item.stopDownload();
                        }
                      }),
                    );
                  }),
            ),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                child: Text('Download All Videos'),
                onPressed: downloadAllVideo,
              ),
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('V$version -'),
                TextButton(
                    style: ButtonStyle(
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                      foregroundColor: MaterialStateProperty.all(Colors.blue),
                    ),
                    child: Text('Github'),
                    onPressed: () => openLink(GITHUB_LINK))
              ],
            ),
            versionStatusTitle.isNotEmpty
                ? Text(versionStatusTitle)
                : SizedBox()
          ],
        ),
      ),
    );
  }
}
