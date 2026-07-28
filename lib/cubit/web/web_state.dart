part of 'web_cubit.dart';

class WebCubitState extends Equatable {

  List<Account> webops = [];
  bool expandedMode = true;
  CalendarPageState calendarPageState = new CalendarPageState();
  ContactsPageState contactsPageState = new ContactsPageState();
  HistoryPageState historyPageState = new HistoryPageState();
  EventListPageState eventListPageState = new EventListPageState();
  UsersManagePageState usersManagePageState = new UsersManagePageState();
  MessageManagePageState messageManagePageState = new LoadingMessagesManage();
  bool filterEvent = false;
  Map<String, FilterWrapper> filters = {};
  int draftsCount = 0;

  WebCubitState({ bool expandedMode = true, List<Account>? webops, Map<String,List<Event>>? eventsOpe,
    Map<String, FilterWrapper>? filters, List<Customer>? customerList, Map<int, int>? countCustomerTypology,
    bool filterEvent = false, CalendarPageState? calendarPageState, ContactsPageState? contactsPageState,
  HistoryPageState? historyPageState, EventListPageState? eventListPageState, UsersManagePageState? usersManagePageState, MessageManagePageState? messageManagePageState,
    int draftsCount = 0,
  }):
              this.expandedMode = expandedMode,
              this.calendarPageState = calendarPageState??new CalendarPageState(),
              this.contactsPageState = contactsPageState??new ContactsPageState(),
              this.historyPageState = historyPageState??new HistoryPageState(),
              this.eventListPageState = eventListPageState?? new EventListPageState(),
              this.usersManagePageState = usersManagePageState?? new UsersManagePageState(),
              this.messageManagePageState = messageManagePageState?? new LoadingMessagesManage(),
              this.filterEvent = filterEvent,
              this.webops = webops??[],
              this.draftsCount = draftsCount,
              this.filters = filters??{};

  @override
  List<Object?> get props => [ expandedMode, calendarPageState, contactsPageState, historyPageState, eventListPageState, usersManagePageState, messageManagePageState, webops,
    filters.keys.join(), filters.values.join(), draftsCount];

  ReadyWebCubitState assign({
    bool? expandedMode,
    bool? filterEvent,
    List<Account>? webops,
    Map<String, FilterWrapper>? filters,
    CalendarPageState? calendarPageState,
    ContactsPageState? contactsPageState,
    HistoryPageState? historyPageState,
    EventListPageState? eventListPageState,
    UsersManagePageState? usersManagePageState,
    MessageManagePageState? messageManagePageState,
    int? draftsCount,
  }) => ReadyWebCubitState.update(
      expandedMode??this.expandedMode, filterEvent??this.filterEvent, webops??this.webops,
      filters??this.filters, calendarPageState??this.calendarPageState, contactsPageState??this.contactsPageState,
      historyPageState??this.historyPageState, eventListPageState??this.eventListPageState, usersManagePageState??this.usersManagePageState, messageManagePageState??this.messageManagePageState,
      draftsCount??this.draftsCount);

}

class LoadingWebCubitState extends WebCubitState{
  @override
  List<Object> get props => [];
}

class ReadyWebCubitState extends WebCubitState{


  ReadyWebCubitState([List<Account>? webops]): super(webops: webops);

  @override
  List<Object?> get props => [expandedMode, calendarPageState, contactsPageState, historyPageState, eventListPageState, usersManagePageState, messageManagePageState, webops, draftsCount];

  ReadyWebCubitState.update(bool expandedMode, bool filterEvent,List<Account> webops,
                          Map<String, FilterWrapper> filters, CalendarPageState calendarPageState, ContactsPageState contactsPageState,
      HistoryPageState historyPageState, EventListPageState eventListPageState, UsersManagePageState usersManagePageState, MessageManagePageState messageManagePageState, int draftsCount):
        super(expandedMode: expandedMode, webops: webops,filters: filters, calendarPageState:  calendarPageState, contactsPageState: contactsPageState, historyPageState: historyPageState, eventListPageState: eventListPageState, usersManagePageState: usersManagePageState, messageManagePageState: messageManagePageState, draftsCount: draftsCount);

}