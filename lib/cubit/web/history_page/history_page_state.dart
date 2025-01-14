part of 'history_page_cubit.dart';

class HistoryPageState extends CommonPageState {

  final Map<int, List<Event>> eventsMap;
  final List<String> selectedCategory;
  Map<String, int> countEventsArchivesCateogry = {};
  int totalEvent;

  HistoryPageState( [int? selectedStatus, int? totalEvent, Map<int, List<Event>>? eventsMap, int? numPage, Map<String, FilterWrapper>? filters, Map<int, int>? countEventsArchives,
    Map<String, int>? countEventsArchivesCateogry, List<String>? selectedCategory, bool? refresh]):
        this.eventsMap = eventsMap ?? {},
        this.countEventsArchivesCateogry = countEventsArchivesCateogry ?? {},
        this.selectedCategory = selectedCategory ?? [],
        this.totalEvent = totalEvent??0,
        super(numPage: numPage??0, selectedStatusTab: selectedStatus ?? EventStatus.Ended, filters: filters, countEntity: countEventsArchives, refresh: refresh);

  @override
  List<Object> get props => [selectedStatusTab, numPage, totalEvent, refresh, eventsMap[selectedStatusTab]!=null?eventsMap[selectedStatusTab]!.map((e) => e).join():"",
    countEntity.keys.join(), countEntity.values.join(), countEventsArchivesCateogry.keys.join(), countEventsArchivesCateogry.values.join(),
    selectedCategory.join()];

  ReadyHistoryPageState assign({
    Map<String, FilterWrapper>? filters,
    Map<int, List<Event>>? eventsMap,
    int? selectedStatus,
    Map<int, int>? countEventsArchives,
    Map<String, int>? countEventsArchivesCateogry,
    List<String>? selectedCategory,
    int? numPage,
    bool? refresh,
    int? totalEvent,
  }) => ReadyHistoryPageState.update(selectedStatus ?? this.selectedStatusTab, eventsMap ?? this.eventsMap, filters ?? this.filters,
    countEventsArchives??this.countEntity, countEventsArchivesCateogry??this.countEventsArchivesCateogry,
    selectedCategory ?? this.selectedCategory, numPage??this.numPage, refresh??this.refresh, totalEvent??this.totalEvent);

}


class LoadingHistoryPageState extends HistoryPageState{
  LoadingHistoryPageState(int? selectedStatus):super(selectedStatus);
}

class ReadyHistoryPageState extends HistoryPageState{

  ReadyHistoryPageState(int? selectedStatus,): super(selectedStatus);

  List<Event> selectedEvents() => eventsMap[selectedStatusTab] ?? [];

  int countEvents() => totalEvent;

  List<Event> events(int status) => (eventsMap[status] ?? []).toList() ;

  ReadyHistoryPageState.update(int selectedStatus, Map<int, List<Event>> eventsMap, Map<String, FilterWrapper> filters,  Map<int, int>? countEventsArchives,
      Map<String, int> countEventsArchivesCateogry, List<String> selectedCategory, int numPage, bool refresh, int totalEvent,) :
        super(selectedStatus, totalEvent, eventsMap, numPage, filters, countEventsArchives, countEventsArchivesCateogry,selectedCategory, refresh);

}
