import 'package:flutter/material.dart';
import 'package:flutter_youtube_downloader/provider/main_provider.dart';
import 'package:flutter_youtube_downloader/screen/main_screen.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

BuildContext get globalContext => navigatorKey.currentContext!;
final logger = Logger();

void main() {
  runApp(MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MainProvider())],
      child: MyApp()));
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
      navigatorKey: navigatorKey,
      home: MainScreen(title: 'Flutter Youtube Downloader'),
    );
  }
}
