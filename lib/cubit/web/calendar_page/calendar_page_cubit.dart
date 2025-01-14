import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/plugins/table_calendar/table_calendar.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'calendar_page_state.dart';

class CalendarPageCubit extends Cubit<CalendarPageState> {

  final CloudFirestoreService _databaseRepository;
  final Account _account;
  final int range = 3;
  DateTime newDate = DateTime.now();
  CalendarController calendarController = new CalendarController();

  CalendarPageCubit(this._databaseRepository, this._account,) : super(LoadingCalendarPageState());

  void initCubit(){
    loadMoreData(state.calendarDate, state.calendarDate);
    emit(ReadyCalendarPageState());
  }

  void loadMoreData([DateTime? start, DateTime? end]){
    DateTime from = TimeUtils.truncateDate(start??DateTime.now().subtract(new Duration(days: range)), "day");
    DateTime to = TimeUtils.truncateDate(end?.add(new Duration(days: 1))??(start??DateTime.now()).add(new Duration(days: range)), "day");
    _databaseRepository.subscribeEventsByOperator(_account.webops.map((operator) => operator.id).toList(), statusEqualOrAbove:  EventStatus.Refused,
        from: from, to: to).listen((eventsList) {
      evaluateEventsMap(eventsList);
    });
  }

  void evaluateEventsMap(List<Event> eventList){
    Map<String, List<Event>> eventsMap = {};
    _account.webops.forEach((operator) {
      List<Event> eventFiltered = eventList.where((event) =>
          [...event.suboperators.map((op) => op.id),event.operator?.id??""].contains(operator.id)).toList();
      eventsMap[operator.id] = eventFiltered;
    });
    emit(state.assign(calendarDate: newDate, eventsOpe: eventsMap));
  }

  void selectCalendarDate(DateTime day){
    newDate = day;
    loadMoreData(day, day);
  }


  void todayCalendarDate(){
    calendarController.setSelectedDay(DateTime.now());
    newDate = DateTime.now();
    loadMoreData(newDate, newDate);
  }

  void selectNextorPrevious(bool hasNext) {
    newDate = state.calendarDate;
    if(hasNext){
      newDate = newDate.add(Duration(days: 1));
    }else{
      newDate = newDate.subtract(Duration(days: 1));
    }
    calendarController.setSelectedDay(newDate);
    loadMoreData(newDate, newDate);
  }

}
