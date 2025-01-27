import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/views/screen_pages/bozze_event_list_view.dart';
import 'package:venturiautospurghi/views/screen_pages/daily_calendar_view.dart';
import 'package:venturiautospurghi/views/screen_pages/history_event_list_view.dart';
import 'package:venturiautospurghi/views/screen_pages/monthly_calendar_view.dart';
import 'package:venturiautospurghi/views/screen_pages/operator_list_view.dart';
import 'package:venturiautospurghi/views/screen_pages/user_profile_view.dart';
import 'package:venturiautospurghi/views/screen_pages/waiting_event_list_view.dart';
import 'package:venturiautospurghi/views/screens/create_address_view.dart';
import 'package:venturiautospurghi/views/screens/create_customer_view.dart';
import 'package:venturiautospurghi/views/screens/create_event_view.dart';
import 'package:venturiautospurghi/views/screens/customer_selection_view.dart';
import 'package:venturiautospurghi/views/screens/details_event_view.dart';
import 'package:venturiautospurghi/views/screens/filter_event_list_view.dart';
import 'package:venturiautospurghi/views/screens/operator_selection_view.dart';
import 'package:venturiautospurghi/views/screens/persistent_notification_view.dart';
import 'package:venturiautospurghi/views/screens/register_view.dart';

part 'mobile_event.dart';
part 'mobile_state.dart';
///
/// The bloc that handle all the navigation and the global state for the mobile part of the application
///
/// START
/// starts in the state [NotReady] -> the view shows the splashscreen
/// the view trigger the [InitAppEvent] that trigger the [NavigateEvent] to home that change the state
///
class MobileBloc extends Bloc<MobileEvent, MobileState> {
  final CloudFirestoreService _databaseRepository;
  final Account _account;
  Timer? background;
  StreamSubscription<List<Event>>? _notificationSubscription;
  late MobileState savedState;
  Map<String, FilterWrapper> filters = {};
  late BuildContext? context;
  late CloudFirestoreService? repository = null;
  
  MobileBloc({
    required CloudFirestoreService databaseRepository,
    required Account account
  }) : _databaseRepository = databaseRepository,
        _account = account,
        super(NotReady()){
    on<RestoreEvent>((event, emit)  { (savedState as InBackdropState).restore(); });
    on<NavigateEvent>(_onNavigateEvent);
    on<NavigateBackEvent>((event, emit)  {
      if(state is OutBackdropState){
         emit((state as OutBackdropState).leave());
         emit((savedState as InBackdropState).restore());
      }
    });
    on<InitAppEvent>(_onInitAppEvent);
  }

  ///Map for the navigation event to update the view
  Future<void> _onNavigateEvent(NavigateEvent event, Emitter<MobileState> emit) async {
    if(state is InBackdropState) savedState = state;

    dynamic objectParameter;
    int currentStep = 0;
    TypeStatus status = TypeStatus.create;
    if(event.arg is Map){
      objectParameter = event.arg["objectParameter"];
      currentStep = event.arg["nextStep"]??event.arg["currentStep"]??0;
      status = event.arg["typeStatus"]??TypeStatus.create;
      context = event.arg["context"]??this.context;
      if(context != null && repository == null){
        repository = context?.read<CloudFirestoreService>();
      }
    }else{
      objectParameter = null;
    }
    switch(event.route) {
      case Constants.detailsEventViewRoute: emit(OutBackdropState(event.route, DetailsEvent(event.arg))); break;
      case Constants.createEventViewRoute: emit( OutBackdropState(event.route, CreateEvent(event: objectParameter, type: status, currentStep: currentStep, ))); break;
      case Constants.registerRoute: emit( OutBackdropState(event.route, Register())); break;
      case Constants.waitingNotificationRoute: emit( NotificationWaitingState(event.route, PersistentNotification(event.arg))); break;
      case Constants.homeRoute: emit( InBackdropState(event.route, _account.supervisor? OperatorList() : DailyCalendar(event.arg != null? event.arg['day']:null,event.arg != null?event.arg['operator']:null) )); break;
      case Constants.monthlyCalendarRoute: emit( InBackdropState(event.route, MonthlyCalendar(event.arg != null?event.arg['month']:null,event.arg != null?event.arg['operator']:null) )); break;
      case Constants.dailyCalendarRoute: emit( InBackdropState(event.route, DailyCalendar(event.arg['day'],event.arg['operator']) )); break;
      case Constants.profileRoute: emit( InBackdropState(event.route, Profile())); break;
      case Constants.operatorListRoute: Navigator.push(event.arg["context"], MaterialPageRoute(maintainState: true, builder: (context) => OperatorSelection(objectParameter, event.arg["requirePrimaryOperator"],event.arg["context"])))
          .then((value) { (event.arg["callback"]).call(); });break;
      case Constants.customerListRoute: Navigator.push(event.arg["context"],MaterialPageRoute(maintainState: true, settings: RouteSettings(name: Constants.customerListRoute), builder: (context) => CustomerSelection(objectParameter, repository))).then((value) { (event.arg["callback"]).call(); }); break;
      case Constants.createCustomerViewRoute: Navigator.push(event.arg["context"],MaterialPageRoute(maintainState: true,settings:   RouteSettings(name: Constants.createCustomerViewRoute),builder: (context) => CreateCustomer(event: objectParameter, type: status,currentStep: currentStep, repository: repository,))).then((value) { (event.arg["callback"]).call(); }); break;
      case Constants.createAddressViewRoute: Navigator.push(event.arg["context"],MaterialPageRoute(maintainState: true, settings:  RouteSettings(name: Constants.createAddressViewRoute),builder: (context) => CreateAddress(objectParameter, status, repository))).then((value) { (event.arg["callback"]).call(); }).then((value) { (event.arg["callback"]).call(); }); break;
      case Constants.createEventViewRoute: emit( InBackdropState(event.route, CreateEvent())); break;
      case Constants.waitingEventListRoute: emit( InBackdropState(event.route, WaitingEventList())); break;
      case Constants.historyEventListRoute: emit( InBackdropState(event.route, HistoryEventList())); break;
      case Constants.filterEventListRoute: emit( InBackdropState(event.route, FilterEventList())); break;
      case Constants.bozzeEventListRoute: emit( InBackdropState(event.route, BozzeEventList())); break;
      default: emit( InBackdropState(event.route, Profile())); break;
    }
  }

  /// First method to be called after the login
  /// it initialize the bloc and start the subscription for the notification events
  Future<void> _onInitAppEvent(InitAppEvent event, Emitter<MobileState> emit) async {
    add(NavigateEvent(Constants.homeRoute));
    int counter = 0;
    if (!_account.supervisor) {
      _notificationSubscription = _databaseRepository.subscribeEventsByOperatorWaiting(_account.id).listen((notifications)  {
        if (notifications.length > 0 && notifications.length>counter){
            //drop what are you doing
            add(NavigateBackEvent());
            //build over
            add(NavigateEvent(Constants.waitingNotificationRoute, notifications));
            if(background == null) {
              background = new Timer.periodic(Duration(seconds: 25), _notificationReminder);
            }
        } else if (notifications.length == 0) {
          background?.cancel();
          background = null;
          if(state is NotificationWaitingState)
            add(RestoreEvent());
        }
        counter = notifications.length;
      });
    }
  }

  void _notificationReminder(Timer t) {
      FirebaseMessagingService.sendNotifications(
          tokens: _account.tokens,
          type: Constants.feedNotification,
          title: "Hai degli eventi in sospeso");
  }

  @override
  Future<dynamic> close() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    return super.close();
  }

}