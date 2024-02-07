import 'package:json_annotation/json_annotation.dart';

part 'video_format.g.dart';

/*
    // audio
    {
      "downloader_options": {
        "http_chunk_size": 10485760
      },
      "format_id": "249",
      "width": null,
      "http_headers": {
        "Accept-Encoding": "gzip, deflate",
        "Accept-Charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.83 Safari/537.36",
        "Accept-Language": "en-us,en;q=0.5"
      },
      "height": null,
      "format_note": "tiny",
      "asr": 48000,
      "url": "https://r3---sn-8qj-jmgl.googlevideo.com/videoplayback?expire=1624180465&ei=kbLOYPH6KLKA1d8Py8uF6As&ip=2001%3Aee0%3A4d44%3A55f0%3A69cb%3Ad0d5%3A6b2%3A993e&id=o-AFzEPCMV1CgZ7Oh0KEdDanmcTGKR4rthH-XiQ0dHBCqJ&itag=249&source=youtube&requiressl=yes&mh=RU&mm=31%2C29&mn=sn-8qj-jmgl%2Csn-i3b7kns6&ms=au%2Crdu&mv=m&mvi=3&pl=48&initcwndbps=1903750&vprv=1&mime=audio%2Fwebm&ns=zFXjQurbVxOHWfZbur4Hu9kF&gir=yes&clen=1408549&dur=220.021&lmt=1540083466111658&mt=1624158520&fvip=3&keepalive=yes&fexp=24001373%2C24007246&c=WEB&txp=5411222&n=qv-KNROtX26Ib9h-S&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cvprv%2Cmime%2Cns%2Cgir%2Cclen%2Cdur%2Clmt&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AG3C_xAwRgIhAOH214Wu56sIqnOz-9TvHaYBMTEnWgu-9snQKpkd-PNVAiEAlJugCETlPIQafJyeKFr9L0dXXYHV5SQzK-5H4HefAUA%3D&sig=AOq0QJ8wRQIgN-7KwqAKGXUG4c2XIeFRLS75PuaxMfc-2kQFaScCiJYCIQD3DYKVxbjSFcXwS9po_dcZgG1sdGYbPXGzQi6f1CX9SA==&ratebypass=yes",
      "acodec": "opus",
      "format": "249 - audio only (tiny)",
      "protocol": "https",
      "tbr": 56.778,
      "player_url": "/s/player/da9443d1/player_ias.vflset/en_US/base.js",
      "fps": null,
      "vcodec": "none",
      "filesize": 1408549,
      "abr": 50,
      "ext": "webm"
    },
    // video
        {
      "downloader_options": {
        "http_chunk_size": 10485760
      },
      "format_id": "134",
      "width": 640,
      "http_headers": {
        "Accept-Encoding": "gzip, deflate",
        "Accept-Charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.83 Safari/537.36",
        "Accept-Language": "en-us,en;q=0.5"
      },
      "height": 360,
      "format_note": "360p",
      "asr": null,
      "url": "https://r3---sn-8qj-jmgl.googlevideo.com/videoplayback?expire=1624180465&ei=kbLOYPH6KLKA1d8Py8uF6As&ip=2001%3Aee0%3A4d44%3A55f0%3A69cb%3Ad0d5%3A6b2%3A993e&id=o-AFzEPCMV1CgZ7Oh0KEdDanmcTGKR4rthH-XiQ0dHBCqJ&itag=134&aitags=133%2C134%2C135%2C136%2C137%2C160%2C242%2C243%2C244%2C247%2C248%2C278&source=youtube&requiressl=yes&mh=RU&mm=31%2C29&mn=sn-8qj-jmgl%2Csn-i3b7kns6&ms=au%2Crdu&mv=m&mvi=3&pl=48&initcwndbps=1903750&vprv=1&mime=video%2Fmp4&ns=zFXjQurbVxOHWfZbur4Hu9kF&gir=yes&clen=1929734&dur=220.000&lmt=1610285504093871&mt=1624158520&fvip=3&keepalive=yes&fexp=24001373%2C24007246&c=WEB&txp=5432432&n=qv-KNROtX26Ib9h-S&sparams=expire%2Cei%2Cip%2Cid%2Caitags%2Csource%2Crequiressl%2Cvprv%2Cmime%2Cns%2Cgir%2Cclen%2Cdur%2Clmt&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AG3C_xAwRQIhAOtJlx5jb569Fu9b2c4_WQ4hY287I04X7uGygZrJDJByAiAo2MOUBLVlG231tZfV62M1sPqNqPeEJjZoOhiWUvNcAA%3D%3D&sig=AOq0QJ8wRQIhAKZaQBLF-hx6cByRKR0TZiRGlqNp-E-ujNVxg8VXsQlZAiBqo3JtoDNUus8vdIcgfE1h1LRuOjtCVKa5R1X_Y6CcbQ==&ratebypass=yes",
      "acodec": "none",
      "format": "134 - 640x360 (360p)",
      "protocol": "https",
      "tbr": 89.878,
      "player_url": "/s/player/da9443d1/player_ias.vflset/en_US/base.js",
      "fps": 30,
      "vcodec": "avc1.4d401e",
      "filesize": 1929734,
      "ext": "mp4"
    },
*/

@JsonSerializable(fieldRename: FieldRename.snake)
class VideoFormat {
  @JsonKey(defaultValue: '')
  String formatId;
  @JsonKey(name: 'ext', defaultValue: '')
  String extension;
  @JsonKey(defaultValue: '')
  String formatNote;
  @JsonKey(name: 'format', defaultValue: '')
  String fullFormat;
  @JsonKey(defaultValue: 0)
  int height;

  VideoFormatType get type {
    return VideoFormatType.init.customInit(value: formatNote);
  }

  VideoFormat({
    required this.formatId,
    required this.extension,
    required this.formatNote,
    required this.fullFormat,
    required this.height,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) => _$VideoFormatFromJson(json);
  Map<String, dynamic> toJson() => _$VideoFormatToJson(this);

}

enum VideoFormatType {
  video,
  audio,
  init, // only use for init
}

extension ExVideoFormatDetailType on VideoFormatType {

  //if use init use FormatDetailType.init
  VideoFormatType customInit({required String value}) {
    if (value.contains(RegExp(r'[0-9]')) || (value.contains('video'))) {
      return VideoFormatType.video;
    }
    return VideoFormatType.audio;
  }

  String get description {
    switch (this) {
      case VideoFormatType.video:
        return 'video';
      case VideoFormatType.audio:
        return 'audio';
      default:
        return 'unknown';
    }
  }

}