import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_auth_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';

import 'bloc/authentication_bloc/authentication_bloc.dart';
import 'bloc/simple_bloc_delegate.dart';

//run dependend by platform
//the actual main is in mobile.dart and/or web.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseAuthService authenticationRepository;
  Bloc.observer = SimpleBlocObserver();
  usePathUrlStrategy();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Rome'));
  PlatformUtils.firebaseInitializeApp().then((_) {
    authenticationRepository = FirebaseAuthService();
    CloudFirestoreService.create().then((db) {
      FirebaseMessagingService.create().then((messaging){
        PlatformUtils.initDownloader();
        runApp(
          RepositoryProvider.value(
            value: authenticationRepository,
            child: BlocProvider<AuthenticationBloc>(
                create: (_) => AuthenticationBloc(
                  authenticationRepository: authenticationRepository,
                  messagingService: messaging,
                  dbCloudFirestore: db,
                )..add(AppStarted()),
                child: PlatformUtils.myApp),
          ),
        );
      });
    });
  });
}
