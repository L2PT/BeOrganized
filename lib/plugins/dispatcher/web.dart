@JS()
library jquery;
//custom import
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:js/js.dart';
import 'package:venturiautospurghi/bloc/web_bloc/web_bloc.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

import '../../web.dart';


class PlatformUtils {
  PlatformUtils._();

  static const String platform = Constants.web;
  static dynamic myApp = MyApp();
  static const bool isMobile = false;
  static const bool isIOS = false;

  static void inizializateFile() => null;
  static void disposeFile() => null;
  static Future<bool> download(url,filename){ html.window.open(url, filename); return Future<bool>(()=>false); }
  static void initDownloader() => null;
  static Uint8List file(String path) => Base64Decoder().convert(path.split(",").last);
 
  static dynamic navigator(BuildContext context, route, [arg]) async {
    context.read<WebBloc>().add(NavigateEvent(route, arg, context));
  }

  static Future<bool> backNavigator(BuildContext context, [ res ]) {
    PlatformUtils.navigator(context, Constants.closeOverViewRoute, res);
    return Future<bool>(()=>false);
  }

  static Future<void> uploadFileStorage(Reference refence, dynamic file) async{
    await refence.putData(file);
  }

  static String getRoute(BuildContext context) =>
      context.read<WebBloc>().state.route;

  static dynamic notifyErrorMessage(msg) {
    showAlertJs(msg);
  }

  static dynamic notifyInfoMessage(msg) {
    showAlertJs(msg);
  }

  static dynamic eventButtonsVisible(BuildContext context, event, account){
    return false;
  }

  static Future<int> getVersionApp() async { return 999; }
  static Future<int> getNumBuildApp() async { return 999;  }

  static Future<FirebaseApp> firebaseInitializeApp(){
    return Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyD3A8jbx8IRtXvnmoGSwJy2VyRCvo0yjGk",
            authDomain: "com-l2pt-venturiautospurghi.firebaseapp.com",
            databaseURL: "https://com-l2pt-venturiautospurghi.firebaseio.com",
            projectId: "com-l2pt-venturiautospurghi",
            storageBucket: "com-l2pt-venturiautospurghi.appspot.com",
            messagingSenderId: "964614131015",
            appId: "1:964614131015:web:8a10af66f5b15bad589062"
        )
    );
  }
}
