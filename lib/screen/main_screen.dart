import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_youtube_downloader/Widget/video_info_cell.dart';
import 'package:flutter_youtube_downloader/global_variables.dart';
import 'package:flutter_youtube_downloader/provider/main_provider.dart';
import 'package:flutter_youtube_downloader/utils/desktop_command.dart';
import 'package:flutter_youtube_downloader/widget/common_snack_bar.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _inputController = TextEditingController();

  MainProvider get read {
    return context.read<MainProvider>();
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
      read.checkYoutubeDL();
      read.checkFFMPEG();
      read.getVideoLocation();
      read.checkVersion();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void openVideoLocation() async {
    DesktopCommand.openFolder(read.videoLocation)
        .catchError((error) => showSnackBar(read.videoLocation + '\n' + error));
  }

  void openLink(String link) {
    DesktopCommand.openLink(link);
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<MainProvider>();
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
              trailing: watch.isLoading
                  ? CircularProgressIndicator()
                  : IconButton(icon: Icon(Icons.search), onPressed: null),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Youtube-dl version: '),
                Expanded(child: Text(watch.youtubeVersion)),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                      child: Icon(Icons.refresh),
                      onPressed: read.checkYoutubeDL),
                )
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('FFmpeg version: '),
                Expanded(child: Text(watch.ffmpegVersion)),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                      child: Icon(Icons.refresh), onPressed: read.checkFFMPEG),
                )
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('Video Location: '),
                Expanded(child: SelectableText(watch.videoLocation)),
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
                      child: Icon(Icons.refresh),
                      onPressed: read.getVideoLocation),
                ),
              ],
            ),
            SizedBox(height: 8),
            watch.isCheckingComplete && !watch.isCheckingValid
                ? Text(
                    'The app must have both youtube-dl and ffmpeg installed to work, please run check again')
                : SizedBox(),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                  child: Text('Add to Queue'),
                  onPressed: () => read.addToQueue(_inputController.text)),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: watch.videoList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = watch.videoList[index];
                    return VideoInfoCell(
                      item: item,
                      onRemoveButtonTap: () => read.removeFromQueue(index),
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
                          read.downloadSingleVideo(item);
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
                onPressed: read.downloadAllVideo,
              ),
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('V${watch.version} -'),
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
            watch.versionStatusTitle.isNotEmpty
                ? Text(watch.versionStatusTitle)
                : SizedBox()
          ],
        ),
      ),
    );
  }
}
