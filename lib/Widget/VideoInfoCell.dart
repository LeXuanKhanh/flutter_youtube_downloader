import 'package:flutter/material.dart';
import 'package:flutter_youtube_downloader/VideoInfo.dart';

class VideoInfoCell extends StatelessWidget {

  final VideoInfo item;

  VideoInfoCell({required this.item});

  @override
  Widget build(BuildContext context) {
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

              }),
        ),
        item.downloadPercentage != 0
            ? LinearProgressIndicator(
            value: item.downloadPercentage / 100)
            : SizedBox(),
      ],
    );
  }
}

