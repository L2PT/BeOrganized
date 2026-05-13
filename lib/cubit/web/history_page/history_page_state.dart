part of 'history_page_cubit.dart';

class HistoryPageState extends CommonPageState {

  final Map<int, List<Event>> eventsMap;
  final List<String> selectedCategory;
  Map<String, int> countEventsArchivesCateogry = {};
  int totalEvent;
  final int? selectedYear;
  final int? selectedMonth;
  final List<int> availableYears;
  final Map<int, int> yearCounts;
  final Map<int, int> monthCounts;

  HistoryPageState( [int? selectedStatus, int? totalEvent, Map<int, List<Event>>? eventsMap, int? numPage, Map<String, FilterWrapper>? filters, Map<int, int>? countEventsArchives,
    Map<String, int>? countEventsArchivesCateogry, List<String>? selectedCategory, bool? refresh, this.selectedYear, this.selectedMonth, List<int>? availableYears, Map<int, int>? yearCounts, Map<int, int>? monthCounts]):
        this.eventsMap = eventsMap ?? {},
        this.countEventsArchivesCateogry = countEventsArchivesCateogry ?? {},
        this.selectedCategory = selectedCategory ?? [],
        this.totalEvent = totalEvent??0,
        this.availableYears = availableYears ?? [],
        this.yearCounts = yearCounts ?? {},
        this.monthCounts = monthCounts ?? {},
        super(numPage: numPage??0, selectedStatusTab: selectedStatus ?? EventStatus.Ended, filters: filters, countEntity: countEventsArchives, refresh: refresh);

  @override
  List<Object> get props => [selectedStatusTab, numPage, totalEvent, refresh, eventsMap[selectedStatusTab]!=null?eventsMap[selectedStatusTab]!.map((e) => e).join():"",
    countEntity.keys.join(), countEntity.values.join(), countEventsArchivesCateogry.keys.join(), countEventsArchivesCateogry.values.join(),
    selectedCategory.join(), selectedYear ?? -1, selectedMonth ?? -1, availableYears.join(), yearCounts.values.join(), monthCounts.values.join()];

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
    int? selectedYear,
    int? selectedMonth,
    bool clearYear = false,
    bool clearMonth = false,
    List<int>? availableYears,
    Map<int, int>? yearCounts,
    Map<int, int>? monthCounts,
  }) => ReadyHistoryPageState.update(selectedStatus ?? this.selectedStatusTab, eventsMap ?? this.eventsMap, filters ?? this.filters,
    countEventsArchives??this.countEntity, countEventsArchivesCateogry??this.countEventsArchivesCateogry,
    selectedCategory ?? this.selectedCategory, numPage??this.numPage, refresh??this.refresh, totalEvent??this.totalEvent,
    clearYear ? null : (selectedYear ?? this.selectedYear), clearMonth ? null : (selectedMonth ?? this.selectedMonth),
    availableYears ?? this.availableYears, yearCounts ?? this.yearCounts, monthCounts ?? this.monthCounts);

}


class LoadingHistoryPageState extends HistoryPageState{
  LoadingHistoryPageState([int? selectedStatus]):super(selectedStatus);

  LoadingHistoryPageState.fromState(HistoryPageState state, [int? selectedStatus]) : super(
      selectedStatus ?? state.selectedStatusTab, state.totalEvent, state.eventsMap, state.numPage, state.filters, state.countEntity, state.countEventsArchivesCateogry, state.selectedCategory, state.refresh, state.selectedYear, state.selectedMonth, state.availableYears, state.yearCounts, state.monthCounts
  );
}

class ReadyHistoryPageState extends HistoryPageState{

  ReadyHistoryPageState(int? selectedStatus,): super(selectedStatus);

  List<Event> selectedEvents() => eventsMap[selectedStatusTab] ?? [];

  int countEvents() => totalEvent;

  List<Event> events(int status) => (eventsMap[status] ?? []).toList() ;

  ReadyHistoryPageState.update(int selectedStatus, Map<int, List<Event>> eventsMap, Map<String, FilterWrapper> filters,  Map<int, int>? countEventsArchives,
      Map<String, int> countEventsArchivesCateogry, List<String> selectedCategory, int numPage, bool refresh, int totalEvent, int? selectedYear, int? selectedMonth, List<int> availableYears, Map<int, int> yearCounts, Map<int, int> monthCounts) :
        super(selectedStatus, totalEvent, eventsMap, numPage, filters, countEventsArchives, countEventsArchivesCateogry,selectedCategory, refresh, selectedYear, selectedMonth, availableYears, yearCounts, monthCounts);

}
