# flutter_youtube_downloader

A Flutter Desktop App which download video from youtube and facebook, both public and private

## Getting Started

Since my favorite video download page i usually use got shutdown, i wrote this :)

This is Flutter UI layer warped around [youtube-dl](https://github.com/ytdl-org/youtube-dl), communicate through shell by using [process_run](https://github.com/tekartik/process_run.dart)

You can download the app [here](https://github.com/LeXuanKhanh/flutter_youtube_downloader/releases/download/1.0/flutter_youtube_downloader_1.0.zip)

## How to use:
By default, the folder don't have additional `youtube-dl.exe`, in order for the app to work, you need to install youtube-dl.

In Windows, just download the `exe` file from [here](https://yt-dl.org/latest/youtube-dl.exe) and place it at the same location of the App

## Tested:

- [x] Windows
- [ ] Mac OS
- [ ] Linux

## Environment:

- Flutter: Channel dev, 1.26.0-8.0.pre
- Visual Studio Community: 2019 16.8.4


## About download private video:

To download private video, you need to get a youtube and facebook cookies files and place them at the same location of the App, you can read how can get that file in [here](https://github.com/ytdl-org/youtube-dl#how-do-i-pass-cookies-to-youtube-dl)

The cookies file which use for downloading facebook video must name `facebook.txt`

The cookies file which use for downloading youtube video must name `youtube.txt`
