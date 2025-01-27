//custom import for mobile

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:venturiautospurghi/bloc/mobile_bloc/mobile_bloc.dart';
import 'package:venturiautospurghi/mobile.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/utils/file_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';

abstract class PlatformUtils {
  PlatformUtils._();

  static const String platform = Constants.mobile;
  static dynamic myApp = MyApp();
  static const bool isMobile = true;
  static bool isIOS = Platform.isIOS;
  static FileUtils fileUtils = new FileUtils.empty();
  static MobileBloc? mobileBloc = null;
  
  static Future<bool> download(url, filename) async {
    final status = await Permission.storage.request();
    if(status.isGranted) {
      var localpath = await getExternalStorageDirectory();
      if (localpath != null) {
        return FlutterDownloader.enqueue(
          url: url,
          savedDir: localpath.path,
          fileName: filename,
          showNotification: true,
          saveInPublicStorage: true,
          // show download progress in status bar (for Android)
          openFileFromNotification: true, // click on notification to open downloaded file (for Android)
        ).then((value) => true);
      }
    }
    return false;
  }

  static void inizializateFile(){
    fileUtils.inizializateFile();
  }
  static void disposeFile() {
    fileUtils.dispose();
  }

  static void initDownloader() => FlutterDownloader.initialize();
  
  static File file(path) => File(path);

  static dynamic navigator(BuildContext context, route, [arg]) async {
    if(mobileBloc == null) mobileBloc = context.read<MobileBloc>();
    mobileBloc!.add(NavigateEvent(route, arg));
  }

  static Future<bool> backNavigator(BuildContext context,  [ res ]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, res);
      FocusScope.of(context).unfocus();
    } else context.read<MobileBloc>().add(NavigateBackEvent());
    return Future<bool>(()=>false);
  }

  static String getRoute(BuildContext context) =>
    context.read<MobileBloc>().state.route;
  

  static dynamic notifyErrorMessage(msg) {
    return Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  static dynamic notifyInfoMessage(msg) {
    return Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  static dynamic eventButtonsVisible(BuildContext context, Event event, account){
    return event.isSeen() && context.read<MobileBloc>().savedState.route != Constants.waitingEventListRoute && (event.operator?.id == account.id);
  }

  static Future<int> getVersionApp() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    int numVersion = 0;
    info.version.split(".").forEach((num) {
      numVersion += int.parse(num);
    });
    return numVersion;
  }

  static Future<int> getNumBuildApp() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return int.parse(info.buildNumber);
  }

  static Future<FirebaseApp> firebaseInitializeApp(){
    return Firebase.initializeApp();
  }
}
