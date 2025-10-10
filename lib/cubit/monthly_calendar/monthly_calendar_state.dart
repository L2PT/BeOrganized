part of 'monthly_calendar_cubit.dart';

abstract class MonthlyCalendarState extends Equatable {
  Map<DateTime, List<Event>> eventsMap;
  DateTime selectedMonth;

  MonthlyCalendarState([DateTime? selectedMonth, Map<DateTime, List<Event>>? eventsMap]):
        this.eventsMap = eventsMap ?? {},
        this.selectedMonth = selectedMonth ?? _.DateUtils.now();

  @override
  List<Object> get props => [eventsMap.entries, selectedMonth];
}

class MonthlyCalendarLoading extends MonthlyCalendarState{
  MonthlyCalendarLoading([DateTime? selectedMonth]):super(selectedMonth);
}

class MonthlyCalendarReady extends MonthlyCalendarState {

  List<Event> selectedEvents() => eventsMap[selectedMonth] ?? [];

  MonthlyCalendarReady(Map<DateTime, List<Event>> eventsMap, DateTime selectMonth)
      : super(selectMonth, eventsMap);
}
