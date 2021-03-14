import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/mobile_bloc/mobile_bloc.dart';
import 'package:venturiautospurghi/plugins/dispatcher/mobile.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/views/backdrop.dart';
import 'package:venturiautospurghi/views/screen_pages/log_in_view.dart';
import 'package:venturiautospurghi/views/screen_pages/reset_auth_account_view.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';
import 'package:venturiautospurghi/views/widgets/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bloc/authentication_bloc/authentication_bloc.dart';
import 'cubit/messaging/messaging_cubit.dart';
import 'utils/theme.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(var context) {
    return MaterialApp(
      title: Constants.title,
      debugShowCheckedModeBanner: Constants.debug,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('it', 'IT'),
      ],
      theme: customLightTheme,
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          if (state is Reset) {
            return ResetAuthAccount(state.autofilledEmail, state.autofilledPhone);
          } else if (state is Unauthenticated) {
            return LogIn();
          } else if (state is Authenticated) {
            CloudFirestoreService databaseRepository = context.read<AuthenticationBloc>().getDbRepository()!;
            FirebaseMessagingService messagingRepository = context.read<AuthenticationBloc>().getMsgRepository()!;
            return RepositoryProvider<CloudFirestoreService>.value( // TODO multi
                    value: databaseRepository,
                    child: RepositoryProvider<FirebaseMessagingService>.value(
                      value: messagingRepository,
                        child: BlocProvider(
                        create: (_) =>
                          MobileBloc(
                            /*** subscription in [AuthenticationBloc]. When it updates the select make the whole tree rebuild so everything underneath can read the fields. ***/
                            account: context.select((AuthenticationBloc bloc)=> bloc.account!),
                            databaseRepository: databaseRepository)..add(InitAppEvent()),
                        child: Stack(children: [
                          BlocBuilder<MobileBloc, MobileState>(
                            buildWhen: (previous, current) => current is InBackdropState && !current.isRestoring,
                            builder: (context, state) => state is InBackdropState ?
                              Backdrop() : SplashScreen()
                          ),
                          BlocBuilder<MobileBloc, MobileState>(
                            buildWhen: (previous, current) => (current is NotificationWaitingState || previous is NotificationWaitingState),
                            builder: (context, state) => state is NotificationWaitingState ?
                              state.content : Container()
                          ),
                          BlocBuilder<MobileBloc, MobileState>(
                            buildWhen: (previous, current) => current is OutBackdropState ||  current is NotificationWaitingState,
                            builder: (context, state) => (state is OutBackdropState && !state.isLeaving) ?
                              state.content : Container()
                          ),
                          BlocProvider(
                            create: (_) => MessagingCubit(
                              databaseRepository,
                              messagingRepository,
                              context.select((AuthenticationBloc bloc)=> bloc.account!) // TODO evaluate a modification to the structure if it doesn't rebuild on unauthicated status
                            ),
                            child: BlocListener<MessagingCubit, MessagingState>(
                              listener: (BuildContext context, MessagingState state) {
                                if(context.read<AuthenticationBloc>().account == null)
                                  context.read<MessagingCubit>().removeAccountToken();
                                else if(state.isWaiting())
                                  PlatformUtils.navigator(context, Constants.waitingNotificationRoute, state.event==null?[state.event]:null);
                                
                              })
                          )
                        ])
                      )
                    )
                );
          }
          return LoadingScreen();
        }
      ),
    );
  }
}