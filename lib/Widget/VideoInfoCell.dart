import 'package:flutter/material.dart';
import '../Model/VideoInfo.dart';

class VideoInfoCell extends StatelessWidget {
  final VideoInfo item;
  final VoidCallback onRemoveButtonTap;
  final Function(int) onSelectResolutionDropDown;

  VideoInfoCell(
      {required this.item,
      required this.onRemoveButtonTap,
      required this.onSelectResolutionDropDown});

  List<DropdownMenuItem<int>> get dropDownItems {
    return this.item.availableResolutions.map<DropdownMenuItem<int>>((value) {
      return DropdownMenuItem<int>(value: value, child: Text('${value}p'));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: item.thumbnail.isNotEmpty
              ? SizedBox(
                  height: 400,
                  child: Image.network(item.thumbnail),
                )
              : SizedBox(width: 100, height: 100),
          title:
              Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.title),
                    DropdownButton<int>(
                      value: item.selectedResolutions,
                      items: dropDownItems,
                      onChanged: (value) => onSelectResolutionDropDown(value!),
                    )]
              ),
          subtitle: Text(item.duration),
          trailing: item.isLoading
              ? CircularProgressIndicator()
              : IconButton(
                  icon: Icon(Icons.close), onPressed: this.onRemoveButtonTap),
        ),
        item.downloadPercentage != 0
            ? LinearProgressIndicator(value: item.downloadPercentage / 100)
            : SizedBox(),
      ],
    );
  }
}
