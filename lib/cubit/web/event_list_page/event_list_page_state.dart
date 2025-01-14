part of 'event_list_page_cubit.dart';

class EventListPageState extends CommonPageState {

  List<Event> listEventFiltered;
  int totalEvent;
  bool isBozze;

  EventListPageState([int? numPage, int? totalEvent, Map<String, FilterWrapper>? filters, List<Event>? listEvent, bool? isBozze, Map<String, bool>? mapSelected, bool? refresh]):
        this.listEventFiltered = listEvent??[],
        this.isBozze = isBozze??false,
        this.totalEvent = totalEvent??0,
        super(numPage: numPage??0,filters: filters??FilterWrapper.initFilterEvent(), mapSelected: mapSelected, refresh: refresh);

  @override
  List<Object> get props => [numPage, refresh, this.listEventFiltered.map((e) => e.id).join(), filters, totalEvent,
      mapSelected.keys.join(), mapSelected.values.join(), isBozze];

  ReadyEventListPageState assign({
    bool? isBozze,
    Map<String, FilterWrapper>? filters,
    List<Event>? eventsList,
    Map<String, bool>? mapSelected,
    int? numPage,
    int? totalEvent,
    bool? refresh,
  }) => ReadyEventListPageState.update(
      filters ?? this.filters,
      eventsList ?? this.listEventFiltered,
      numPage?? this.numPage,
      totalEvent?? this.totalEvent,
      isBozze??this.isBozze,
      mapSelected ?? this.mapSelected,
      refresh ?? this.refresh);

}

class LoadingEventListPageState extends EventListPageState {}

class ReadyEventListPageState extends EventListPageState {

  List<Event> selectedEvents() => listEventFiltered;

  ReadyEventListPageState.update( Map<String, FilterWrapper> filters, List<Event> listEvent, int numPage, int totalEvent,bool isBozze, Map<String, bool> mapSelected, bool refresh) : super(numPage, totalEvent, filters, listEvent, isBozze, mapSelected, refresh);

}
