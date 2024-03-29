# flutter youtube downloader

A Flutter Desktop GUI App of Youtube-dl which download video from Youtube, Facebook (both public and private) and other video from many website

## Getting Started

Since my favorite video download page i usually use got shutdown, i wrote this :)

You can download the app 

- Windows: [here](https://github.com/LeXuanKhanh/flutter_youtube_downloader/releases/download/1.3/flutter_youtube_downloader_windows_1.3.zip)

- Mac OS: [here](https://github.com/LeXuanKhanh/flutter_youtube_downloader/releases/download/1.3/flutter_youtube_downloader_macos_1.3.zip)

## Setup
By default, the folder don't have additional `youtube-dl.exe`, in order for the app to work, you need to install `youtube-dl`.

- Windows: download the `exe` file from [here](https://yt-dl.org/latest/youtube-dl.exe) and place it at the same location of the App

- MacOS: you can install via brew with command `brew install youtube-dl`

Since release 1.3, the app require additional FFmpeg executable to work, like `youtube-dl`, the folder don't have it `ffmpeg.exe`, in order for the app to work, you need to install `ffmpeg`.

- Windows: download the `exe` file from https://www.gyan.dev/ffmpeg/builds/, recommander the stable release builds or you're too lazy just click [here](https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-full-shared.7z) to download and place the `ffmpeg.exe` at the same location of the App (the exe file is in the bin folder of the zip folder)

- MacOS: you can install via brew with command `brew install ffmpeg`

## Video Location
The video location can't change by default, I will improve that in the future

- Windows: <App Location>/flutter_youtube_download_video

- Mac OS: Documents/flutter_youtube_download_video

## Tested:

- [x] Windows
- [x] Mac OS
- [ ] Linux

## Environment:

- Flutter: channel stable, 2.2.1
- Visual Studio Community: 2019 16.8.4
- Xcode 13.1 (13A1030d)
- Android Studio Arctic Fox 2020.3.1 Patch 3

## About download private video:

To download private video, you need to get a youtube and facebook cookies files, you can read how can get that file in [here](https://github.com/ytdl-org/youtube-dl#how-do-i-pass-cookies-to-youtube-dl)

The cookies file which use for downloading facebook video must name `facebook.txt`

The cookies file which use for downloading youtube video must name `youtube.txt`

- Windows: place them at the same location of the App

- Mac OS: place them at Documents folder


