import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/router/GoRouterRefreshStream.dart';
import 'package:venturiautospurghi/views/screen_pages/bozze_event_list_view.dart';
import 'package:venturiautospurghi/views/screen_pages/customer_contacts_view.dart';
import 'package:venturiautospurghi/views/screen_pages/history_event_list_view.dart';
import 'package:venturiautospurghi/views/screen_pages/log_in_view.dart';
import 'package:venturiautospurghi/views/screen_pages/reset_auth_account_view.dart';
import 'package:venturiautospurghi/views/screens/filter_event_list_view.dart';
import 'package:venturiautospurghi/views/widgets/calendar_content_web.dart';
import 'package:venturiautospurghi/views/widgets/splash_screen.dart';

import '../../views/web_page.dart';

class RouterWebApp{

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();
  final AuthenticationBloc bloc;

  late final GoRouter routes;


  RouterWebApp(this.bloc){
    this.routes = GoRouter(
        navigatorKey: _rootNavigatorKey,
        routes: [
          ShellRoute(
              navigatorKey: _shellNavigatorKey,
              pageBuilder: (context, state, child) {
                return NoTransitionPage(
                  child: _buildPageWebLogged(context, child)
                );
              },
              routes: [
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  path: Constants.homeRoute,
                  name: 'home',
                  builder: (context, state) => CalendarContentWeb(),
                ),
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  path: Constants.historyEventListRoute,
                  name: 'historyEvent',
                  builder: (context, state) {
                    context.read<WebCubit>().initCubit(state.uri.path);
                    return HistoryEventList();
                  },
                ),
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  path: Constants.bozzeEventListRoute,
                  name: 'bozzeEvent',
                  builder: (context, state) {
                    context.read<WebCubit>().initCubit(state.uri.path);
                    return BozzeEventList();
                  }
                ),
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  path: Constants.filterEventListRoute,
                  name: 'filterEvent',
                  builder: (context, state) {
                    context.read<WebCubit>().initCubit(state.uri.path);
                    return FilterEventList();
                  },
                ),
                GoRoute(
                  parentNavigatorKey: _shellNavigatorKey,
                  path: Constants.customerContactsListRoute,
                  name: 'customerContacts',
                  builder: (context, state) {
                    context.read<WebCubit>().initCubit(state.uri.path);
                    return CustomerContacts();
                  },
                ),
              ]),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: Constants.logInRoute,
            name: 'login',
            builder: (context, state) => const LogIn(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: Constants.loadingRoute,
            name: 'loading',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
              parentNavigatorKey: _rootNavigatorKey,
              path: Constants.resetCodeRoute,
              name: 'reset',
              pageBuilder: (context, state) {
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: ResetAuthAccount(
                      state.uri.queryParameters['autofilledEmail'] as String,
                      state.uri.queryParameters['autofilledPhone'] as String),
                  transitionsBuilder: (context, animation, secondaryAnimation,
                      child) {
                    // Change the opacity of the screen using a Curve based on the the animation's
                    // value
                    return FadeTransition(
                      opacity:
                      CurveTween(curve: Curves.easeInOutCirc).animate(
                          animation),
                      child: child,
                    );
                  },);
              }
          ),
        ],
        redirect: (context, state) {
          print("Location:" + state.uri.toString());
          final isLoggedIn =
              context.read<AuthenticationBloc>().state is Authenticated;
          final isReset =
          context.read<AuthenticationBloc>().state is Reset;
          final isUnLogged =
          context.read<AuthenticationBloc>().state is Unauthenticated;

          if(isReset) return Constants.resetCodeRoute;

          if(isUnLogged) return Constants.logInRoute;

          if(isLoggedIn && (state.uri.toString() == Constants.logInRoute || state.uri.toString() == Constants.loadingRoute)) return Constants.homeRoute;

          if(isLoggedIn && state.uri.toString() != Constants.logInRoute) return state.uri.toString();

          return Constants.loadingRoute;
        },
        refreshListenable: GoRouterRefreshStream(bloc.stream)

    );
  }

  Widget _buildPageWebLogged(BuildContext context, Widget child) {
    CloudFirestoreService databaseRepository = context.read<AuthenticationBloc>().getDbRepository()!;
    FirebaseMessagingService messagingRepository = context.read<AuthenticationBloc>().getMsgRepository()!;
    return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CloudFirestoreService>.value( value: databaseRepository),
          RepositoryProvider<FirebaseMessagingService>.value( value: messagingRepository)
        ],
        child: WebPage(child));
  }


}