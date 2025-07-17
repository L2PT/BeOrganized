import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/layout/group_overlapping.dart';
import 'package:venturiautospurghi/plugins/table_calendar/table_calendar.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
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
    _databaseRepository.subscribeEventsByOperatorReapet(_account.webops.map((operator) => operator.id).toList(), statusEqualOrAbove:  EventStatus.Refused,
        from: from, to: to).listen((eventsList) {
      evaluateEventsMap(eventsList);
    });
  }

  void evaluateEventsMap(List<Event> eventList){
    Map<String, List<Event>> eventsMap = {};
    Map<String,List<OverlappingGroup>> listOverlappingGroup = {};
    _account.webops.forEach((operator) {
      List<Event> eventFiltered = eventList.where((event) =>
          [...event.suboperators.map((op) => op.id),event.operator.id].contains(operator.id) &&
          TimeUtils.truncateDate(event.start, "day").isAtSameMomentAs(TimeUtils.truncateDate(newDate, "day")) &&
          event.start.hour >= Constants.MIN_WORKTIME && event.end.hour <= (Constants.MAX_WORKTIME - 1)
      ).toList();
      eventFiltered.sort((a, b) => a.start.compareTo(b.start));
      eventsMap[operator.id] = eventFiltered;
      listOverlappingGroup[operator.id] = _findOverlappingGroups(eventFiltered);
    });
    emit(state.assign(calendarDate: newDate, eventsOpe: eventsMap, listOverlappingGroup: listOverlappingGroup));
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

  // ===================== GESTIONE EVENTI SOVRAPPOSTI =====================
  /// Trova e raggruppa gli eventi sovrapposti
  List<OverlappingGroup> _findOverlappingGroups(List<Event> events) {
    List<OverlappingGroup> groups = [];

    for (Event event in events) {
      OverlappingGroup? targetGroup;

      // Cerca un gruppo esistente che si sovrappone con questo evento
      for (OverlappingGroup group in groups) {
        if (group.overlaps(event)) {
          targetGroup = group;
          break;
        }
      }

      // Se non trova un gruppo, ne crea uno nuovo
      if (targetGroup == null) {
        targetGroup = OverlappingGroup();
        groups.add(targetGroup);
      }

      targetGroup.addEvent(event);
    }

    return groups;
  }

}
