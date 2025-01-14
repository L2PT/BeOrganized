part of 'web_cubit.dart';

class WebCubitState extends Equatable {

  List<Account> webops = [];
  bool expandedMode = true;
  CalendarPageState calendarPageState = new CalendarPageState();
  ContactsPageState contactsPageState = new ContactsPageState();
  HistoryPageState historyPageState = new HistoryPageState();
  EventListPageState eventListPageState = new EventListPageState();
  bool filterEvent = false;
  Map<String, FilterWrapper> filters = {};

  WebCubitState({ bool expandedMode = true, List<Account>? webops, Map<String,List<Event>>? eventsOpe,
    Map<String, FilterWrapper>? filters, List<Customer>? customerList, Map<int, int>? countCustomerTypology,
    bool filterEvent = false, CalendarPageState? calendarPageState, ContactsPageState? contactsPageState,
  HistoryPageState? historyPageState, EventListPageState? eventListPageState}):
              this.expandedMode = expandedMode,
              this.calendarPageState = calendarPageState??new CalendarPageState(),
              this.contactsPageState = contactsPageState??new ContactsPageState(),
              this.historyPageState = historyPageState??new HistoryPageState(),
              this.eventListPageState = eventListPageState?? new EventListPageState(),
              this.filterEvent = filterEvent,
              this.webops = webops??[],
              this.filters = filters??{};

  @override
  List<Object?> get props => [ expandedMode, calendarPageState, contactsPageState, historyPageState, eventListPageState,  webops,
    filters.keys.join(), filters.values.join()];

  ReadyWebCubitState assign({
    bool? expandedMode,
    bool? filterEvent,
    List<Account>? webops,
    Map<String, FilterWrapper>? filters,
    CalendarPageState? calendarPageState,
    ContactsPageState? contactsPageState,
    HistoryPageState? historyPageState,
    EventListPageState? eventListPageState
  }) => ReadyWebCubitState.update(
      expandedMode??this.expandedMode, filterEvent??this.filterEvent, webops??this.webops,
      filters??this.filters, calendarPageState??this.calendarPageState, contactsPageState??this.contactsPageState,
      historyPageState??this.historyPageState, eventListPageState??this.eventListPageState);

}

class LoadingWebCubitState extends WebCubitState{
  @override
  List<Object> get props => [];
}

class ReadyWebCubitState extends WebCubitState{


  ReadyWebCubitState([List<Account>? webops]): super(webops: webops);

  @override
  List<Object?> get props => [expandedMode, calendarPageState, contactsPageState, historyPageState, eventListPageState,  webops];

  ReadyWebCubitState.update(bool expandedMode, bool filterEvent,List<Account> webops,
                          Map<String, FilterWrapper> filters, CalendarPageState calendarPageState, ContactsPageState contactsPageState,
      HistoryPageState historyPageState, EventListPageState eventListPageState):
        super(expandedMode: expandedMode, webops: webops,filters: filters, calendarPageState:  calendarPageState, contactsPageState: contactsPageState, historyPageState: historyPageState, eventListPageState: eventListPageState);

}