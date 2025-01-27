import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/route_navigation.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/views/screens/create_address_view.dart';
import 'package:venturiautospurghi/views/screens/create_customer_view.dart';
import 'package:venturiautospurghi/views/screens/create_event_view.dart';
import 'package:venturiautospurghi/views/screens/customer_selection_view.dart';
import 'package:venturiautospurghi/views/screens/details_event_view.dart';
import 'package:venturiautospurghi/views/screens/operator_selection_view.dart';
import 'package:venturiautospurghi/views/screens/register_view.dart';
import 'package:venturiautospurghi/views/screens/table_calendar_view.dart';

part 'web_event.dart';
part 'web_state.dart';

class WebBloc extends Bloc<WebEvent, WebState> {
  final Account _account;
  Map<String, TypeStatus> typeStatusList = {};
  Queue<RouteNavigation> historyRoute = new Queue();
  double _posLeftOverView;
  double _posTopOverView;

  WebBloc({
    required CloudFirestoreService databaseRepository,
    required Account account,
    required double posLeftOverView,
    required double posTopOverView
  }) :  _account = account,
        _posLeftOverView = posLeftOverView,
        _posTopOverView = posTopOverView,
       super(NotReady()){
    on<NavigateEvent>(_onNavigateEvent);
    on<InitAppEvent>(_onInitAppEvent);
    // if(Constants.debug)
    //   _databaseRepository.subscribeAccount(account.id).listen((userUpdate){ _account.update(userUpdate);});
  }

  Future<void> _onNavigateEvent(NavigateEvent event, Emitter<WebState> emit) async {
    Function? callback;
    String? routeTarget = Constants.noRoute;
    if(event.route == Constants.closeOverViewRoute){
      if(historyRoute.last.callback != null){
        callback = historyRoute.last.callback;
      }
      if(historyRoute.last.route == Constants.addWebOperatorRoute)
        routeTarget = Constants.addWebOperatorRoute;
      RouteNavigation route = historyRoute.removeLast();
      if(historyRoute.isNotEmpty) {
        routeTarget = historyRoute.last.route;
        if (route.currentStep != 0)
          historyRoute.last.currentStep = route.currentStep;
      }
    }else if (historyRoute.isEmpty || historyRoute.last.route != event.route){
      int currentStep = event.arg["currentStep"]??0;
      TypeStatus status = event.arg["typeStatus"]??TypeStatus.create;
      RouteNavigation route = RouteNavigation(event.route, currentStep, status);
      if(event.arg["callback"] != null){
        route.callback = event.arg["callback"];
      }
      historyRoute.addLast(route);
    }

    dynamic objectParameter;
    int currentStep = 0;
    TypeStatus status = TypeStatus.create;
    if(event.arg is Map){
      objectParameter = event.arg["objectParameter"];
      currentStep = event.arg["nextStep"]??event.arg["currentStep"]??0;
      status = event.arg["typeStatus"]??TypeStatus.create;
    }else{
      objectParameter = {};
    }
    switch(event.route){
      case Constants.closeOverViewRoute: emit( CloseOverView(<String, dynamic>{"objectParameter": objectParameter,"typeStatus": historyRoute.isEmpty?0:historyRoute.last.status, "currentStep": historyRoute.isEmpty?0:historyRoute.last.currentStep},routeTarget,(event.arg is Map)?event.arg["res"]:false, callback??() {})); break;
      case Constants.detailsEventViewRoute: emit( OverViewReady(event.route, DetailsEvent(objectParameter),_posLeftOverView, _posTopOverView, )); break;
      case Constants.createEventViewRoute: emit( OverViewReady(event.route, CreateEvent(event: objectParameter,currentStep: currentStep,dateSelect: (event.arg is Map)?event.arg["dateSelect"]:DateTime.now(), type: status), _posLeftOverView, _posTopOverView,)); break;
      case Constants.createCustomerViewRoute: emit( OverViewReady(event.route, CreateCustomer(event: objectParameter,currentStep: currentStep,type: status), _posLeftOverView, _posTopOverView,)); break;
      case Constants.createAddressViewRoute: emit( OverViewReady(event.route, CreateAddress(objectParameter, status), _posLeftOverView, _posTopOverView,)); break;
      case Constants.monthlyCalendarRoute: emit( OverViewReady(event.route, TableCalendarWithBuilders(), _posLeftOverView, _posTopOverView,)); break;
      case Constants.registerRoute: emit( OverViewReady(event.route, Register(), _posLeftOverView, _posTopOverView,)); break;
      case Constants.operatorListRoute: emit( OverViewReady(event.route, OperatorSelection(objectParameter, (event.arg is Map)?event.arg["requirePrimaryOperator"]:false),_posLeftOverView, _posTopOverView)); break;
      case Constants.customerListRoute: emit( OverViewReady(event.route, CustomerSelection(objectParameter),_posLeftOverView, _posTopOverView)); break;
      case Constants.addWebOperatorRoute: Event e = new Event.empty()..suboperators = _account.webops; e.start = e.end = DateTime(0); emit( OverViewReady(event.route, OperatorSelection(e), _posLeftOverView, _posTopOverView,)); break;
    }
  }

  /// First method to be called after the login
  /// it initialize the bloc and start the subscription for the notification events
  Future<void> _onInitAppEvent(InitAppEvent event, Emitter<WebState> emit) async {
    print("chiamata iniziale");
    add(NavigateEvent(Constants.homeRoute));
  }

  void updatePositionOverView(DraggableDetails details){
    this._posLeftOverView = details.offset.dx;
    this._posTopOverView = details.offset.dy;
    emit((state as OverViewReady).assign(posLeftOverView: details.offset.dx, posTopOverView: details.offset.dy));
  }

  void setReady(String route){
    emit(Ready(route));
  }
}
