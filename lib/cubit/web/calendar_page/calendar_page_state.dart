part of 'calendar_page_cubit.dart';

class CalendarPageState extends Equatable {

  DateTime calendarDate;
  Map<String,List<Event>> eventsOpe = {};


  CalendarPageState({ DateTime? calendarDate, Map<String,List<Event>>? eventsOpe,}):
        this.calendarDate = calendarDate??DateTime.now(),
        this.eventsOpe = eventsOpe??{};

  @override
  List<Object?> get props => [eventsOpe.entries, calendarDate];

  ReadyCalendarPageState assign({
    DateTime? calendarDate, Map<String,List<Event>>? eventsOpe
  }) => ReadyCalendarPageState.update(
      calendarDate??this.calendarDate,eventsOpe??this.eventsOpe);


}

class LoadingCalendarPageState extends CalendarPageState{
  @override
  List<Object> get props => [];
}

class ReadyCalendarPageState extends CalendarPageState{


  ReadyCalendarPageState(): super();

  @override
  List<Object?> get props => [calendarDate, eventsOpe.entries ];

  ReadyCalendarPageState.update(DateTime? calendarDate, Map<String,List<Event>> eventsOpe):
        super(calendarDate: calendarDate, eventsOpe: eventsOpe,);

  List<Event> selectedEventsOperator(String idOperator) {
    return eventsOpe[idOperator]??[];
  }

}