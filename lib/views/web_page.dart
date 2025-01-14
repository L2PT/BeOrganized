import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/bloc/web_bloc/web_bloc.dart';
import 'package:venturiautospurghi/cubit/messaging/messaging_cubit.dart';
import 'package:venturiautospurghi/cubit/web/calendar_page/calendar_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/contacts_page/contacts_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/event_list_page/event_list_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/history_page/history_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/page_parameter.dart';
import 'package:venturiautospurghi/plugins/dispatcher/web.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/views/widgets/web/header_menu_widget.dart';
import 'package:venturiautospurghi/views/widgets/web/side_menu_widget.dart';
import 'package:venturiautospurghi/web.dart';

final Map<String, PageParameter> parameterPage = {
  Constants.homeRoute: PageParameter(Icons.add_box, Constants.createEventViewRoute, 'Nuovo incarico', FunctionalWidgetType.calendar,
      true, true, true),
  Constants.historyEventListRoute: PageParameter(Icons.add_box, Constants.createEventViewRoute, 'Nuovo incarico', FunctionalWidgetType.filterEvent,
      false, false, true),
  Constants.bozzeEventListRoute: PageParameter(Icons.add_box, Constants.createEventViewRoute, 'Nuova bozza', FunctionalWidgetType.filterEvent,
      false, true, true),
  Constants.manageUtenzeRoute: PageParameter(Icons.person_add, Constants.registerRoute, 'Nuovo dipendente', FunctionalWidgetType.calendar,
      false, true, false),
  Constants.filterEventListRoute: PageParameter(Icons.person_add, Constants.registerRoute, 'Nuovo dipendente', FunctionalWidgetType.filterEvent,
      false, false, true),
  Constants.customerContactsListRoute: PageParameter(Icons.person_add, Constants.createCustomerViewRoute, 'Nuovo cliente', FunctionalWidgetType.FilterCustomer,
      false, true, true),
};

class WebPage extends StatefulWidget {

  final Widget content;

  const WebPage(this.content, {Key? key}) : super(key: key);

  @override
  _WebPageState createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    init(Constants.debug, context.read<AuthenticationBloc>().account!.id);
  }

  @override
  Widget build(BuildContext context) {
    final CloudFirestoreService databaseRepository = context.read<CloudFirestoreService>();
    final FirebaseMessagingService messagingRepository = context.read<FirebaseMessagingService>();
    final Account account = context.select((AuthenticationBloc bloc)=>bloc.account!);
    PageParameter? pageParameter = parameterPage[GoRouterState.of(context).uri.toString()];
    MessagingCubit cubit = MessagingCubit(
        databaseRepository,
        messagingRepository,
        context.watch<AuthenticationBloc>().account!
    );
    js.context['updateAccontTokens_dart'] = cubit.updateAccountTokens;
    js.context['openEventDetails_dart'] = cubit.launchTheEvent;

    return  MultiBlocProvider(providers: [
        BlocProvider(create: (_) =>WebBloc(
            account: context.read<AuthenticationBloc>().account!, databaseRepository: databaseRepository,
            posLeftOverView: (MediaQuery.of(context).size.width/2) - (Constants.WIDTH_OVERVIEW/2),posTopOverView:  (MediaQuery.of(context).size.height/2) - (Constants.HEIGHT_OVERVIEW/2)
    )),
        BlocProvider(create: (_) => CalendarPageCubit(databaseRepository, account)),
        BlocProvider(create: (_) => ContactsPageCubit(databaseRepository)),
        BlocProvider(create: (_) => HistoryPageCubit(databaseRepository)),
        BlocProvider(create: (_) => EventListPageCubit(databaseRepository)),
        BlocProvider(
            create: (tex) => WebCubit(GoRouterState.of(context).uri.toString(),tex.read<CalendarPageCubit>(),tex.read<ContactsPageCubit>(),
                tex.read<HistoryPageCubit>(), tex.read<EventListPageCubit>(), databaseRepository, account)),
    ], child:Scaffold(
          backgroundColor: Color(0x00000000),
          body: Stack(
          children: [
            Row(
              children: [
                SideMenuLayerWeb(pageParameter!.showButton, pageParameter.textButton, pageParameter.iconLink,
                    pageParameter.actionButtonRoute, pageParameter.functionalWidgetType, pageParameter.showFunctionWidget),
                Expanded(child: Column(
                  children: [
                    new BlocBuilder<WebCubit, WebCubitState>(
                      buildWhen: (previous, current) => previous.calendarPageState!.calendarDate != current.calendarPageState!.calendarDate,
                      builder: (context, state) {
                        return HeaderMenuLayerWeb(
                            pageParameter.showBoxCalendar,
                            state.calendarPageState!.calendarDate,
                            account,
                            () => context.read<AuthenticationBloc>().add(LoggedOut()),
                            () => context.read<WebCubit>().calendarPageCubit.todayCalendarDate(),
                            context.read<WebCubit>().calendarPageCubit.selectNextorPrevious,
                        );}),
                    new BlocBuilder<WebCubit, WebCubitState>(
                      buildWhen: (previous, current) => (previous.runtimeType) != (current.runtimeType),
                      builder: (context, state) {
                        return !(state is ReadyWebCubitState) ? Center(child: CircularProgressIndicator()):Expanded(child:  widget.content);
                      })
                  ]))
              ],
            ),
            BlocBuilder<WebBloc, WebState>(
                buildWhen: (previous, current) => previous != current,
                builder: (context, state) {
                  if (state is OverViewReady) {
                    Widget child = RepositoryProvider<CloudFirestoreService>.value(
                        value: RepositoryProvider.of<CloudFirestoreService>(context),
                        child: BlocProvider.value(
                            value: context.read<WebBloc>(),
                            child: Container(
                                height:Constants.HEIGHT_OVERVIEW, width:Constants.WIDTH_OVERVIEW,
                                child: context.read<WebBloc>().state.content
                            )));
                        return Positioned(
                            left: state.posLeftOverView,
                            top: state.posTopOverView,
                            child:Draggable(
                                maxSimultaneousDrags: 1,
                                feedback:  Opacity(
                                  opacity: .3,
                                  child: child,
                                ),
                                onDragEnd: context.read<WebBloc>().updatePositionOverView,
                                child: child ));
                  }
                  if (state is CloseOverView) {
                    if(state.callback != null)
                      state.callback!.call();
                      state.callback = null;
                    switch(context.read<WebBloc>().state.route) {
                      case Constants.addWebOperatorRoute :{
                        if(state.result){
                          Account account = context.read<AuthenticationBloc>().account!;
                          account.webops = (context.read<WebBloc>().state as CloseOverView).arg["objectParameter"].suboperators;
                          //update firestore and calendarJs
                          context.read<WebCubit>().updateAccount(account.webops);
                        }
                      }break;
                      default: {
                        if(state.route != Constants.noRoute)
                          PlatformUtils.navigator(context, context.read<WebBloc>().state.route, <String,dynamic>{'objectParameter' : state.arg['objectParameter'],'typeStatus': state.arg['typeStatus'], 'currentStep' : state.arg['currentStep']});
                        else if(state.result)
                          switch(GoRouterState.of(context).uri.toString()){
                            case Constants.bozzeEventListRoute :{
                              context.read<WebCubit>().onFiltersChangedEvent(context.read<WebCubit>().state.eventListPageState.filters, Constants.bozzeEventListRoute);
                              context.read<WebCubit>().eventListPageCubit.forceRefresh();
                              state.result = false;
                            }break;
                            case Constants.filterEventListRoute :{
                              context.read<WebCubit>().onFiltersChangedEvent(context.read<WebCubit>().state.eventListPageState.filters, Constants.filterEventListRoute);
                              context.read<WebCubit>().eventListPageCubit.forceRefresh();
                              state.result = false;
                            }break;
                            case Constants.historyEventListRoute :{
                              context.read<WebCubit>().onFiltersChangedEvent(context.read<WebCubit>().state.historyPageState.filters, Constants.historyEventListRoute);
                              context.read<WebCubit>().historyPageCubit.forceRefresh();
                              state.result = false;
                            }break;
                            case Constants.customerContactsListRoute :{
                              context.read<WebCubit>().contactsPageCubit.onFiltersChangedCustomer(context.read<WebCubit>().state.filters);
                              context.read<WebCubit>().contactsPageCubit.forceRefresh();
                              state.result = false;
                            }break;
                          }
                      }break;
                      }
                  }
                  return Container();
                }
            ),
            BlocProvider<MessagingCubit>.value(
                value: cubit,
                child: BlocListener<MessagingCubit, MessagingState>(
                  listenWhen: (previous, current) => true,
                  listener: (BuildContext context, MessagingState state){
                    if(state.isWaiting()) {
                      final GoRouterState stateRoute = GoRouterState.of(context);
                      if (stateRoute.uri.toString() == Constants.detailsEventViewRoute)
                        PlatformUtils.backNavigator(context);
                      PlatformUtils.navigator(
                          context, Constants.detailsEventViewRoute, <String,dynamic>{"objectParameter" : state.event});
                    }
                  }, child: Container(),)
            )
          ])
      )
    );
  }
}