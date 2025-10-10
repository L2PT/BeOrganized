part of 'calendar_page_cubit.dart';

class CalendarPageState extends Equatable {

  DateTime calendarDate;
  Map<String,List<Event>> eventsOpe = {};
  Map<String,List<OverlappingGroup>> listOverlappingGroup = {};


  CalendarPageState({ DateTime? calendarDate, Map<String,List<Event>>? eventsOpe, Map<String,List<OverlappingGroup>>? listOverlappingGroup}):
        this.calendarDate = calendarDate??_.DateUtils.now(),
        this.eventsOpe = eventsOpe??{},
        this.listOverlappingGroup = listOverlappingGroup??{};

  @override
  List<Object?> get props => [eventsOpe.entries, calendarDate, listOverlappingGroup.entries];

  ReadyCalendarPageState assign({
    DateTime? calendarDate, Map<String,List<Event>>? eventsOpe,
    Map<String,List<OverlappingGroup>>? listOverlappingGroup
  }) => ReadyCalendarPageState.update(
      calendarDate??this.calendarDate,eventsOpe??this.eventsOpe, listOverlappingGroup??this.listOverlappingGroup);


}

class LoadingCalendarPageState extends CalendarPageState{
  @override
  List<Object> get props => [];
}

class ReadyCalendarPageState extends CalendarPageState{


  ReadyCalendarPageState(): super();

  @override
  List<Object?> get props => [calendarDate, eventsOpe.entries, listOverlappingGroup.entries ];

  ReadyCalendarPageState.update(DateTime? calendarDate, Map<String,List<Event>> eventsOpe, Map<String,List<OverlappingGroup>>? listOverlappingGroup):
        super(calendarDate: calendarDate, eventsOpe: eventsOpe, listOverlappingGroup: listOverlappingGroup);

  List<Event> selectedEventsOperator(String idOperator) {
    return eventsOpe[idOperator]??[];
  }

  List<OverlappingGroup> selectedEventsGroupOperator(String idOperator) {
    return listOverlappingGroup[idOperator]??[];
  }

}