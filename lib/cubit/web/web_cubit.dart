import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:venturiautospurghi/cubit/web/calendar_page/calendar_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/contacts_page/contacts_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/event_list_page/event_list_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/history_page/history_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/messageManage_page/message_manage_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/usersManage_page/users_manage_page_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/date_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

part 'web_state.dart';

class WebCubit extends Cubit<WebCubitState> {
  final CloudFirestoreService _databaseRepository;
  final Account _account;
  String route;
  CalendarPageCubit calendarPageCubit;
  ContactsPageCubit contactsPageCubit;
  HistoryPageCubit historyPageCubit;
  EventListPageCubit eventListPageCubit;
  UsersManagePageCubit usersManagePageCubit;
  MessageManagePageCubit messageManagePageCubit;
  final ScrollController verticalCalendar = ScrollController();
  double scrollPixel = 0;
  Timer? _scrollTimer;

  WebCubit(this.route, this.calendarPageCubit, this.contactsPageCubit, this.historyPageCubit, this.eventListPageCubit, this.usersManagePageCubit, this.messageManagePageCubit, CloudFirestoreService databaseRepository, Account account,) :
        _databaseRepository = databaseRepository, _account = account,
        super(LoadingWebCubitState()){
    verticalCalendar.addListener(() {
      _scrollTimer?.cancel(); // Cancella eventuali timer precedenti
      _scrollTimer = Timer(Duration(milliseconds: 200), () {
        scrollPixel = verticalCalendar.position.pixels;
      });
    });
    if(route == Constants.homeRoute) {
      this.calendarPageCubit.initCubit();
      this.calendarPageCubit.stream.listen((status) {
        emit(state.assign(calendarPageState: status));
      });
    }else
      emit(ReadyWebCubitState());
  }


  void initCubit(String route){
    switch(route) {
      case Constants.homeRoute:
        this.calendarPageCubit.initCubit();
        this.calendarPageCubit.stream.listen((status) {
          emit(state.assign(calendarPageState: status));
        });
        break;
      case Constants.customerContactsListRoute:
        this.contactsPageCubit.initCubit();
        this.contactsPageCubit.stream.listen((status) {
          emit(state.assign(contactsPageState: status));
        });
        break;
      case Constants.historyEventListRoute:
        this.historyPageCubit.initCubit();
        this.historyPageCubit.stream.listen((status) {
          emit(state.assign(historyPageState: status));
        });
        break;
      case Constants.bozzeEventListRoute:
        this.eventListPageCubit.initCubit(true);
        this.eventListPageCubit.stream.listen((status) {
          emit(state.assign(eventListPageState: status));
        });
        break;
      case Constants.filterEventListRoute:
        this.eventListPageCubit.initCubit();
        this.eventListPageCubit.stream.listen((status) {
          emit(state.assign(eventListPageState: status));
        });
        break;
      case Constants.manageUtenzeRoute:
        this.usersManagePageCubit.initCubit();
        this.usersManagePageCubit.stream.listen((status) {
          emit(state.assign(usersManagePageState: status));
        });
        break;
      case Constants.manageMessageRoute:
        this.messageManagePageCubit.initCubit();
        this.messageManagePageCubit.stream.listen((status) {
          emit(state.assign(messageManagePageState: status));
        });
        break;
    }
  }

  void updateAccount(List<Account> webOps) async {
    await _databaseRepository.updateAccountField(_account.id, "OperatoriWeb", webOps.map((webOp) => webOp.toWebDocument()));
    emit(state.assign(webops: webOps));
  }

  void removeAccount(String id) async {
    // Crea una NUOVA lista senza l'elemento rimosso (non mutare la lista originale)
    // Se si muta la stessa lista, Equatable la vede come identica e BlocBuilder non ricostruisce
    List<Account> webOps = _account.webops.where((element) => element.id != id).toList();
    _account.webops = webOps;
    await _databaseRepository.updateAccountField(_account.id, "OperatoriWeb", webOps.map((webOp) => webOp.toWebDocument()));
    emit(state.assign(webops: List<Account>.from(webOps)));
  }
  void showExpandedBox() {
    emit(state.assign(expandedMode:!state.expandedMode));
  }

  void onFiltersChangedEvent(Map<String, FilterWrapper> filters, String route){
    switch(route) {
      case Constants.historyEventListRoute:
        this.historyPageCubit.onFiltersChanged(filters);
        break;
      case Constants.filterEventListRoute:
        this.eventListPageCubit.onFiltersChanged(filters);
        break;
      case Constants.bozzeEventListRoute:
        this.eventListPageCubit.onFiltersChanged(filters);
        break;
    }
  }

  DateTime moveEventToDate(DraggableDetails details, DateTime selectDay, double gridHourHeight,) {
    return DateUtils.calcTimeFromPixelPosition(selectDay,1, gridHourHeight, (details.offset.dy-265+this.scrollPixel));
  }
}
