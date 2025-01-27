@JS()
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:js/js.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/router/routing_app.dart';
import 'package:venturiautospurghi/utils/theme.dart';

import 'bloc/authentication_bloc/authentication_bloc.dart';


@JS()
external dynamic showAlertJs(dynamic value);
@JS()
external dynamic consoleLogJs(dynamic value);

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Constants.title,
      debugShowCheckedModeBanner: Constants.debug,
      theme: customLightTheme,
      routerConfig: RouterWebApp(context.read<AuthenticationBloc>()).routes,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('it', 'IT'),
      ],
    );
  }
}
