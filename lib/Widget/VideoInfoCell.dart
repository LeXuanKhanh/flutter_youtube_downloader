import 'package:flutter/material.dart';
import '../Model/VideoInfo.dart';

class VideoInfoCell extends StatelessWidget {
  final VideoInfo item;
  final VoidCallback onRemoveButtonTap;
  final Function(VideoResolution) onSelectResolutionDropDown;
  final Function(bool?) onChangedIsConvertToMp4CheckBox;
  final Function(bool?) onChangedIsAudioOnlyCheckBox;
  final Function()? onDownloadButtonTap;

  VideoInfoCell(
      {required this.item,
      required this.onRemoveButtonTap,
      required this.onSelectResolutionDropDown,
      required this.onChangedIsConvertToMp4CheckBox,
      required this.onChangedIsAudioOnlyCheckBox,
      this.onDownloadButtonTap});

  List<DropdownMenuItem<VideoResolution>> get dropDownItems {
    return this
        .item
        .availableResolutions
        .map<DropdownMenuItem<VideoResolution>>((value) {
      return DropdownMenuItem<VideoResolution>(
          value: value, child: Text(value.formatNote));
    }).toList();
  }

  Widget indicator() {
    if (item.isLoading) {
      switch (item.processingState) {
        case VideoProcessingState.startConvertToDifferentFormat:
          return LinearProgressIndicator();
        case VideoProcessingState.mergingOutput:
          return LinearProgressIndicator();
        case VideoProcessingState.start:
          return LinearProgressIndicator();
        default:
          return LinearProgressIndicator(value: item.downloadPercentage / 100);
      }
    } else {
      switch (item.processingState) {
        case VideoProcessingState.start:
          return SizedBox();
        case VideoProcessingState.done:
          return LinearProgressIndicator(value: item.downloadPercentage / 100);
        default:
          return LinearProgressIndicator();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(item.processingState);
    return Column(
      children: [
        ListTile(
          tileColor: null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: item.thumbnail.isNotEmpty
              ? SizedBox(
                  height: 400,
                  child: Image.network(item.thumbnail),
                )
              : SizedBox(width: 100, height: 100),
          title:
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.title),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DropdownButton<VideoResolution>(
                          value: item.selectedResolutions,
                          items: dropDownItems,
                          onChanged: (value) => onSelectResolutionDropDown(value!),
                        ),
                        IconButton(
                            color: Colors.black54,
                            icon: item.isLoading
                                ? Icon(Icons.file_download_off)
                                : Icon(Icons.download),
                            onPressed: this.onDownloadButtonTap),
                      ],
                    ),

                  ]
              ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.duration),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Checkbox(value: item.isAudioOnly, onChanged: onChangedIsAudioOnlyCheckBox),
                      Text('audio only'),
                    ],
                  ),
                  SizedBox(),
                  Row(
                    children: [
                      Checkbox(value: item.isConvertToMp4, onChanged: onChangedIsConvertToMp4CheckBox),
                      Text('convert to mp4'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            height: double.infinity,
            child: IconButton(
                icon: Icon(Icons.close), onPressed: this.onRemoveButtonTap),
          ),
        ),
        item.processingState.description.isNotEmpty
            ? Row(
                children: [
                  Text(item.processingState.description),
                ],
              )
            : SizedBox(),
        SizedBox(height: 4),
        indicator()
      ],
    );
  }
}
