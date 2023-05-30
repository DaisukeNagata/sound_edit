import 'dart:io' show Directory, File;
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sound_edit/sound_edit_asset_list.dart';

class SoundEditChanel {
  final MethodChannel _channel =
      const MethodChannel('co.jp.everydaysoft.sound_edit/music');
  final MethodChannel _channelTrim =
      const MethodChannel('co.jp.everydaysoft.sound_edit/trim');
  final MethodChannel _channelDrag =
      const MethodChannel('co.jp.everydaysoft.sound_edit/drag');
  final MethodChannel _channelRecord =
      const MethodChannel('co.jp.everydaysoft.sound_edit/record');

  List<File> fileList = [];
  List<String> dragdrop = [];
  bool animationFlg = false;

  getApplicationAssets(
    String soundPath,
    String createPath,
  ) async {
    final byteData = await rootBundle.load('assets/$createPath');
    Uint8List byteList = Uint8List.fromList(_byteUint8List(byteData));
    final file =
        File('${(await getApplicationDocumentsDirectory()).path}/$soundPath');
    await file.writeAsBytes(byteList.buffer
        .asUint8List(byteList.offsetInBytes, byteList.lengthInBytes));
    return createPath;
  }

  getApplicationAssetsList(
    List<String> listPath,
  ) async {
    for (final list in listPath) {
      if (!list.contains('.DS_Store')) {
        final byteData = await rootBundle.load('assets/$list');
        Uint8List byteList = Uint8List.fromList(_byteUint8List(byteData));
        final file =
            File('${(await getApplicationDocumentsDirectory()).path}/$list');
        await file.writeAsBytes(byteList.buffer
            .asUint8List(byteList.offsetInBytes, byteList.lengthInBytes));
      }
    }
  }

  _byteUint8List(byteData) {
    ByteBuffer buffer = byteData.buffer;
    Uint8List unit8List =
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return unit8List;
  }

  record(String path) async {
    try {
      await _channelRecord.invokeMethod(path);
    } on PlatformException catch (e) {
      debugPrint(e.code);
    }
  }

  recordStop() async {
    try {
      await _channelRecord.invokeMethod('recordStop');
    } on PlatformException catch (e) {
      debugPrint(e.code);
    }
  }

  getAppDocumentDirectoryContent() async {
    List<File> tempFiles = [];
    List<String> modifiedAssetList = soundEditAssetList.map((assetPath) {
      return assetPath.split('assets//').last;
    }).toList();
    Set<String> combinedSet;
    List<String> combinedList = [];
    final excludedExtensions = [
      '.png',
      '.jpeg',
      '.jpg',
      '.DC_Store',
      'webp',
      'res_timestamp'
    ];
    var list = await listFilesInApplicationDocumentsDirectory();
    await getApplicationAssetsList(modifiedAssetList);
    if (list.isEmpty) {
      combinedList = modifiedAssetList;
    } else {
      combinedSet = <String>{}
        ..addAll(list)
        ..addAll(modifiedAssetList);
      combinedList = combinedSet.toList();
    }
    for (final path in combinedList) {
      final fileName = basename(path);
      bool excluded = false;

      for (final extension in excludedExtensions) {
        if (fileName.contains(extension)) {
          excluded = true;
          break;
        }
      }
      if (!excluded) {
        tempFiles.add(File(path));
      }
    }
    fileList = tempFiles;
  }

  deleteFileInAppDirectory(String path) async {
    final file =
        File('${(await getApplicationDocumentsDirectory()).path}/$path');
    if (file.existsSync()) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Failed to delete file: $e');
      }
    } else {
      final file = File(path);
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Failed to delete file: $e');
      }
    }
  }

  Future<T> playSoundChoice<T>(String path, String methodChanel) async {
    var result = '';
    var value = 0.0;
    switch (methodChanel) {
      case 'drag':
        try {
          value = await _channelDrag
              .invokeMethod<double>(path)
              .then<double>((double? value) => value ?? 0.0);
        } on PlatformException catch (e) {
          debugPrint(e.code);
        }
        return value as T;
      case 'trim':
        try {
          value = await _channelTrim
              .invokeMethod<double>(path)
              .then<double>((double? value) => value ?? 0.0);
        } on PlatformException catch (e) {
          debugPrint(e.code);
        }
        return value as T;
      case 'music':
        try {
          await _channel.invokeMethod(path);
        } on PlatformException catch (e) {
          debugPrint(e.code);
        }
        return result as T;
      case 'record':
        try {
          await _channelRecord.invokeMethod(path);
        } on PlatformException catch (e) {
          debugPrint(e.code);
        }
        return result as T;
    }
    return result as T;
  }

  Future<List<File>> getAudioFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioFiles = <File>[];
    final supportedExtensions = ['.mp3', '.wav', '.aac', '.m4a'];

    bool hasSupportedExtension(File file) {
      for (final extension in supportedExtensions) {
        if (file.path.toLowerCase().endsWith(extension)) {
          return true;
        }
      }
      return false;
    }

    try {
      final files = directory.listSync(recursive: false, followLinks: false);

      for (final file in files) {
        if (file is File && hasSupportedExtension(file)) {
          audioFiles.add(file);
        }
      }
    } catch (e) {
      debugPrint('Error while fetching audio files: $e');
    }

    return audioFiles;
  }

  Future<List<String>> listFilesInApplicationDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePaths = await listFilesInDirectory(directory.path);
    return filePaths;
  }

  Future<List<String>> listFilesInDirectory(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      List<String> fileNames = [];

      await for (var file
          in directory.list(recursive: false, followLinks: false)) {
        if (file is File) {
          fileNames.add(path.basename(file.path));
        }
      }

      return fileNames;
    } catch (e) {
      debugPrint('Error listing files in directory: $e');
      return [];
    }
  }
}
