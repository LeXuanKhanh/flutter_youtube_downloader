import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_youtube_downloader/main.dart';

void showSnackBar(String text) {
  final snackBar = SnackBar(
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
  ScaffoldMessenger.of(globalContext).showSnackBar(snackBar);
}