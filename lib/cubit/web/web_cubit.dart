import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/cubit/web/calendar_page/calendar_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/contacts_page/contacts_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/event_list_page/event_list_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/history_page/history_page_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
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

  WebCubit(this.route, this.calendarPageCubit, this.contactsPageCubit, this.historyPageCubit, this.eventListPageCubit, CloudFirestoreService databaseRepository, Account account,) :
        _databaseRepository = databaseRepository, _account = account,
        super(LoadingWebCubitState()){
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
    }
  }

  void updateAccount(List<Account> webOps) async {
    await _databaseRepository.updateAccountField(_account.id, "OperatoriWeb", webOps.map((webOp) => webOp.toWebDocument()));
    emit(state.assign(webops: _account.webops));
  }

  void removeAccount(String id) async {
    _account.webops.removeWhere((element) => element.id == id);
    List<Account> webOps = _account.webops;
    await _databaseRepository.updateAccountField(_account.id, "OperatoriWeb", webOps.map((webOp) => webOp.toWebDocument()));
    emit(state.assign(webops: _account.webops));
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
    }
  }
}
