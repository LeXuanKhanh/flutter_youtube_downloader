// get only info which to display in order to reduce latency
import 'package:flutter/material.dart';

enum VideoType {
  facebook,
  youtube,
  other
}

extension VideoTypeEx on VideoType {
  String get cookieFile {
    switch (this) {
      case VideoType.facebook:
        return "facebook.txt";
      case VideoType.youtube:
        return "youtube.txt";
      case VideoType.other:
        return "other.txt";
      default:
        return "other.txt";
    }
  }

  // custom enum init cheat
  VideoType fromLinkString({@required String link}) {
    if (link.contains('facebook')) {
      return VideoType.facebook;
    }

    if (link.contains('youtube')) {
      return VideoType.facebook;
    }

    return VideoType.other;
  }

}

class VideoInfo {
  String link;
  String title;
  String thumbnail;
  String duration;
  String id;
  double downloadPercentage = 0;
  bool isLoading = false;

  VideoType get type {
    if (link.contains('facebook')) {
      return VideoType.facebook;
    }

    if (link.contains('youtube')) {
      return VideoType.facebook;
    }

    return VideoType.other;
  }

  VideoInfo({
    @required this.link,
    @required this.title,
    @required this.thumbnail,
    @required this.duration,
    @required this.id
  });

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'title': title,
      'thumbnail': thumbnail,
      'duration' : duration
    };
  }

}