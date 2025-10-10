import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

abstract class PlatformUtils {

  PlatformUtils._();

/* Example
  static void open(String url, {String name}) {
    throw 'Platform Not Supported';
  }
*/

  static const String platform = "";
  static const dynamic myApp = null;
  static const bool isMobile = true;
  static const bool isIOS = true;

  static dynamic download(url,filename) => null;
  static dynamic uploadFileStorage(Reference refence, dynamic file) => null;
  static void initDownloader() => null;
  static dynamic file(path) => null;
  static void inizializateFile() => null;
  static void disposeFile() => null;

  static dynamic navigator(context, route, [arg]) => null;
  static Future<bool> backNavigator(BuildContext context,  [ res ]) => Future<bool>(()=>false);
  static String getRoute( context) => Constants.homeRoute;

  static dynamic notifyErrorMessage(msg) => null;

  static dynamic notifyInfoMessage(message) => null;

  static dynamic eventButtonsVisible(BuildContext context, event, account) => null;

  static Future<int> getVersionApp() async  { return 999; }
  static Future<int> getNumBuildApp() async { return 999; }
  static dynamic firebaseInitializeApp() => null;
}