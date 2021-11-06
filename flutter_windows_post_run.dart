import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:tuple/tuple.dart';

const windowRunnerRCPath = 'windows/runner/Runner.rc';
const windowMainCppPath = 'windows/runner/main.cpp';
const yamlPath = 'pubspec.yaml';

// run script every time before run or build the project
// or add add run this script in "before launch" in any run/ build configurations in Android Studio

void main() async {
  print('reading pubspec.yaml');
  final pubspec = await PubspecInfo.fromFile(filePath: yamlPath);

  if (pubspec == null) {
    print('can\'t read or found pubspec.yaml');
    return;
  }

  print(pubspec.toString());

  print('update info in $windowRunnerRCPath');
  await setPubspecInfoToWindowsRunnerRC(pubspec);

  print('update info in $windowMainCppPath');
  await setPubspecInfoToWindowsMainCPP(pubspec);

  print('flutter windows post process completed');
}

Future setPubspecInfoToWindowsMainCPP(PubspecInfo info) async {
  final file = File(windowMainCppPath);
  if (!await file.exists()) {
    return;
  }
  // Read file
  final contents = await file.readAsString();
  final contentsAsLines = contents.split('\n');

  // change name when create a windows
  // if (!window.CreateAndShow(L"Flutter Youtube Downloader", origin, size)) (change this line)
  final createAndShowWindowStringAndIndex = getLastLineStringAndIndex(contentsAsLines, 'if (!window.CreateAndShow(');
  final nameValue = createAndShowWindowStringAndIndex.item1.split('L').last.split(',').first;
  final newCreateAndShowWindowLine = createAndShowWindowStringAndIndex.item1.replaceAll(nameValue, '\"${info.windowsName}\"');
  contentsAsLines[createAndShowWindowStringAndIndex.item2] = newCreateAndShowWindowLine;

  final newContent = contentsAsLines.join('\n');
  await File(windowMainCppPath).writeAsString(newContent);
}

Future setPubspecInfoToWindowsRunnerRC(PubspecInfo info) async {
  final file = File(windowRunnerRCPath);
  if (!await file.exists()) {
    return;
  }
  // Read file
  final contents = await file.readAsString();
  final contentsAsLines = contents.split('\n');

  // change version in windows/runner/Runner.rc

  // #ifdef FLUTTER_BUILD_NUMBER
  // #define VERSION_AS_NUMBER FLUTTER_BUILD_NUMBER
  // #else
  //   #define VERSION_AS_NUMBER 1,4,0 (change this line)
  // #endif

  // #ifdef FLUTTER_BUILD_NAME
  // #define VERSION_AS_STRING #FLUTTER_BUILD_NAME
  // #else
  //   #define VERSION_AS_STRING "1.4.0" (change this line)
  // #endif

  List<Tuple2<String, String>> versionLineAndNewValueToReplaceArr = [
    Tuple2<String, String>('#define VERSION_AS_NUMBER', info.windowsVersionAsNumber),
    Tuple2<String, String>('#define VERSION_AS_STRING', info.windowsVersionAsString)
  ];

  for (final item in versionLineAndNewValueToReplaceArr) {
    final containString = item.item1;
    final newValue = item.item2;
    final lineStringAndIndex = getLastLineStringAndIndex(contentsAsLines, containString);
    final newLineString = newVersionStringFrom(lineStringAndIndex.item1, newValue);
    contentsAsLines[lineStringAndIndex.item2] = newLineString;
  }

  // change value at BLOCK "StringFileInfo" in windows/runner/Runner.rc
  List<Tuple2<String, String>> lineInfoValueAndNewValueToReplaceArr = [
    Tuple2<String, String>('FileDescription', info.description),
    Tuple2<String, String>('OriginalFilename', info.windowsOriginalFilename),
    Tuple2<String, String>('InternalName', info.windowsName),
    Tuple2<String, String>('ProductName', info.windowsName)
  ];

  for (final item in lineInfoValueAndNewValueToReplaceArr) {
    final containString = item.item1;
    final newValue = item.item2;
    final lineStringAndIndex = getLastLineStringAndIndex(contentsAsLines, containString);
    final newLineString = newInfoStringFrom(lineStringAndIndex.item1, newValue);
    contentsAsLines[lineStringAndIndex.item2] = newLineString;
    // print(newLineString);
  }

  final newContent = contentsAsLines.join('\n');
  // Write file
  await File(windowRunnerRCPath).writeAsString(newContent);


}

Tuple2<String, int> getLastLineStringAndIndex(List<String> strings, matchString) {
  final lineString = strings
      .where((element) => element.contains(matchString))
      .last;
  final lineIndex = strings.lastIndexWhere(
          (element) => element.contains(matchString));
  return Tuple2<String, int>(lineString, lineIndex);
}

String newInfoStringFrom(String line, String newString) {
  // VALUE "FileDescription", "Flutter Youtube Downloader" "\0"
  final valuePart = line.split(',').last;
  // [' '|Flutter Youtube Downloader|\0|''|]
  final value = valuePart.split("\"")[1];
  final newInfoString = line.replaceAll(value, newString);
  return newInfoString;
}

String newVersionStringFrom(String line, String version) {
  final words = line.split(' ');
  words[words.length - 1] = version;
  final newString = words.join(' ');
  return newString;
}

class PubspecInfo {
  final String name;
  final String description;
  final List<String> version;
  final String windowsName;
  final String macOSName;

  String get windowsOriginalFilename => '$name.exe';
  String get windowsVersionAsNumber => version.join(',');
  String get windowsVersionAsString => '\"${version.join('.')}\"';

  PubspecInfo({
    required this.name,
    required this.description,
    required this.version,
    required this.windowsName,
    required this.macOSName
  });

  static Future<PubspecInfo?> fromFile({required String filePath}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final contents = await file.readAsString();
    final doc = loadYaml(contents);
    return PubspecInfo(
        name: doc['name'],
        description: doc['description'],
        version: (doc['version'] as String).split('.'),
        windowsName: doc['windows_name'],
        macOSName: doc['macos_name']
    );
  }

  @override
  String toString() {
    // TODO: implement toString
    return """
    {
      name: $name,
      description: $description,
      version: $version,
      windowsName: $windowsName,
      macOSName: $macOSName,
    }
    """;
  }

}