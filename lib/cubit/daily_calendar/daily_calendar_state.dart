part of 'daily_calendar_cubit.dart';

abstract class DailyCalendarState extends Equatable {
  Map<DateTime, List<Event>> eventsMap;
  Map<DateTime, List<OverlappingGroup>> overlapMap;
  List<DateTime> subscribedDays;
  DateTime selectedDay;
  double gridHourHeight = 0;
  int gridHourSpan = 0;
  bool allDayEvent = false;

  DailyCalendarState([DateTime? selectedDay, Map<DateTime, List<Event>>? eventsMap,
    Map<DateTime, List<OverlappingGroup>>? overlapMap,
    List<DateTime>? subscribedDays, ]) :
        this.eventsMap = eventsMap ?? {},
        this.overlapMap = overlapMap ?? {},
        this.selectedDay = selectedDay ?? TimeUtils.truncateDate(DateTime.now(), "day"),
        this.subscribedDays = subscribedDays ?? [];

  @override
  List<Object> get props => [eventsMap.entries, selectedDay, gridHourHeight, gridHourSpan];
}

// ignore: must_be_immutable
class DailyCalendarLoading extends DailyCalendarState{
  DailyCalendarLoading([DateTime? selectedDay]):super(selectedDay);
}

// ignore: must_be_immutable
class DailyCalendarReady extends DailyCalendarState {

  List<Event> selectedEvents() => eventsMap[selectedDay] ?? [];

  List<OverlappingGroup> selectedOverlapping() => overlapMap[selectedDay] ?? [];

  DailyCalendarReady(Map<DateTime, List<Event>> eventsMap, Map<DateTime, List<OverlappingGroup>> overlapMap, DateTime selectedDay, List<DateTime> subscribedDays) : super(selectedDay, eventsMap, overlapMap, subscribedDays) {
    //the verticalGridEvents need the events of the selectedDay ordered
    List<Event> listEvent = eventsMap[selectedDay] ?? [];
    listEvent.sort((a, b) => a.start.compareTo(b.start));
    _calculateGridDimensions();
  }

  void _calculateGridDimensions() {
    List<Event> selectedEvents =  eventsMap[selectedDay] ?? [];
    if (selectedEvents.length > 0) {
      if (selectedEvents.length == 1 &&
          selectedEvents[0].start.compareTo(selectedDay.add(Duration(hours: Constants.MIN_WORKTIME))) <= 0 &&
          selectedEvents[0].end.compareTo(selectedDay.add(Duration(hours: Constants.MAX_WORKTIME))) >= 0) {
        allDayEvent = true;
        this.gridHourHeight = 120;
        gridHourSpan = 0;
      } else {
        allDayEvent = false;
        //identify minimum duration's event
        double md = 4;
        selectedEvents.forEach((e) => md = max(0, min(md, (DateUtils.getLastDailyWorkedMinute(e.end, selectedDay) - DateUtils.getFirstDailyWorkedMinute(e.start, selectedDay)) / 60))
        );
        if(md>0 && md<0.5){
          gridHourHeight = 120;
          gridHourSpan = 0;
        } else if (md.floor() == 0) {
          gridHourHeight = Constants.MIN_CALENDAR_EVENT_HEIGHT * 2;
          gridHourSpan = 1;
        } else {
          int mid = md.floor();
          int i = 0;
          while (mid == (max(pow(2, i), mid))) i++;
          mid = (min(pow(2, i - 1).toInt(), mid));
          gridHourHeight = Constants.MIN_CALENDAR_EVENT_HEIGHT;
          gridHourSpan = mid;
        }
      }
    } else {
      gridHourHeight = Constants.MIN_CALENDAR_EVENT_HEIGHT;
      gridHourSpan = 1;
    }
  }

}
