import 'dart:isolate';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';


class FileUtils {

  ReceivePort _port = new ReceivePort();

  FileUtils(this._port);
  FileUtils.empty();

  void inizializateFile(){
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    FlutterDownloader.registerCallback(downloadCallback);
  }

  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(String id, int status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  static Future<Map<String, dynamic>> openFileExplorer(Map<String, dynamic> documents) async {
    try {
      var a = (await FilePicker.platform.pickFiles(allowMultiple: true, withData: !PlatformUtils.isMobile))?.files??[];
      Map<String, dynamic> files = Map.fromIterable(a, key: (file)=>(file as PlatformFile).name, value: (file)=>PlatformUtils.isMobile?PlatformUtils.file((file as PlatformFile).path!):(file as PlatformFile).bytes);
      Map<String, dynamic> newDocs = Map.from(documents);
      files.forEach((key, value) {
        newDocs[key] = value;
      });
      return newDocs;
    } on Exception catch (e) {
      print("Unsupported operation:" + e.toString());
      return new Map();
    }
  }

}

