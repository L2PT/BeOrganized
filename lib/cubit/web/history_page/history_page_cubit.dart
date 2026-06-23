import 'package:bloc/bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:venturiautospurghi/cubit/web/common/common_page_state.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/headers_constants.dart';

part 'history_page_state.dart';

class HistoryPageCubit extends Cubit<HistoryPageState> {

  final CloudFirestoreService _databaseRepository;
  List<Event> listEvent = [];
  final int startingElements = 25;
  final int loadingElements = 10;
  Map<int, bool> canLoadMore = {};
  Map<int, bool> loaded = {};
  late Map<String,dynamic> categories;

  HistoryPageCubit(this._databaseRepository, [int? _selectedStatusTab])
      : super(LoadingHistoryPageState(_selectedStatusTab));

  void selectYear(int? year) async {
    if (year == null) {
      emit(state.assign(clearYear: true, clearMonth: true));
    } else {
      emit(LoadingHistoryPageState.fromState(state, state.selectedStatusTab));
      Map<int, int> newMonthCounts = {};
      final List<Future<void>> futures = [];
      for(int m = 1; m <= 12; m++) {
        futures.add(_databaseRepository.getHistoryCountByDateRange(state.selectedStatusTab, DateTime(year, m, 1), DateTime(year, m + 1, 1), filters: state.filters).then((count) => newMonthCounts[m] = count));
      }
      await Future.wait(futures);
      int totalEvent = await _databaseRepository.getEventsHistoryFilteredCount(state.selectedStatusTab, state.filters);
      emit(state.assign(selectedYear: year, clearMonth: true, monthCounts: newMonthCounts, totalEvent: totalEvent));
    }
  }

  void selectMonth(int? month) async {
    if (month == null) {
      emit(state.assign(clearMonth: true));
    } else {
      emit(LoadingHistoryPageState.fromState(state, state.selectedStatusTab));

      // Update filters to grab this specific month and year
      Map<String, FilterWrapper> filters = Map.from(state.filters);
      DateTime start = DateTime(state.selectedYear!, month, 1);
      DateTime end = DateTime(state.selectedYear!, month + 1, 1);

      filters["startDate"] = new FilterWrapper("startDate", start, (Event event, value) => event.end.isAfter(value) || event.end.isAtSameMomentAs(value));
      filters["endDate"] = new FilterWrapper("endDate", end, (Event event, value) => event.end.isBefore(value));
      filters.remove("dateRange");

      listEvent = await _databaseRepository.getEventsHistoryFiltered(state.selectedStatusTab, filters, limit: startingElements);
      canLoadMore[state.selectedStatusTab] = listEvent.length >= startingElements;
      loaded.forEach((key, value) { loaded[key] = false; });
      loaded[state.selectedStatusTab] = true;
      Map<int, List<Event>> eventsMap = Map.from(state.eventsMap);
      eventsMap[state.selectedStatusTab] = listEvent;

      int totalEvent = await _databaseRepository.getEventsHistoryFilteredCount(state.selectedStatusTab, filters);
      emit(state.assign(selectedMonth: month, eventsMap: eventsMap, numPage: 0, totalEvent: totalEvent, filters: filters));
    }
  }

  void initCubit() async {
    categories = _databaseRepository.categories;
    Map<int, int> countEventsArchives = await _loadCountHistory();
    emit(state.assign(countEventsArchives: countEventsArchives));
    onStatusTabSelected(EventStatus.Ended);
  }

  void loadMoreData() async {
    List<Event> selectedEvents = (state as ReadyHistoryPageState).selectedEvents();
    listEvent = List.from(selectedEvents);
    listEvent.addAll(await _databaseRepository.getEventsHistoryFiltered(state.selectedStatusTab, state.filters, limit: loadingElements, startFrom: selectedEvents.last.id));
    canLoadMore[state.selectedStatusTab] = listEvent.length >= selectedEvents.length+loadingElements;
    Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
    eventsMap[state.selectedStatusTab] = listEvent;
    emit(state.assign(eventsMap: eventsMap));
  }

  void onStatusTabSelected(int status) async {
    emit(LoadingHistoryPageState.fromState(state, status)); // show loading indicator
    Map<String, int> countEventsArchivesCateogry = await _loadCountHisotryCategory(status);

    // load years range and fetch counts for all available years
    List<int> range = await _databaseRepository.getHistoryYearsRange(status);
    List<int> availableYears = [];
    Map<int, int> yearCounts = {};
    if (range.length == 2) {
      final List<Future<void>> futures = [];
      for(int y = range[1]; y >= range[0]; y--) {
        availableYears.add(y);
        futures.add(_databaseRepository.getHistoryCountByDateRange(status, DateTime(y, 1, 1), DateTime(y + 1, 1, 1), filters: state.filters).then((count) => yearCounts[y] = count));
      }
      await Future.wait(futures);
    }

    int totalEvent = await _databaseRepository.getEventsHistoryFilteredCount(status, state.filters);
    if((state.eventsMap[status] == null && loaded[status] == null) || loaded[status] == false || state.eventsMap[status]!.length<startingElements){
      loaded.forEach((key, value) { loaded[key] = false; });
      loaded[status] = true; //declare loaded before actually have loaded is error prone but it's a way to prevent multiple call of the listener
      listEvent = await _databaseRepository.getEventsHistoryFiltered(status, state.filters, limit: startingElements);
      canLoadMore[status] = listEvent.length >= startingElements;
      Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
      eventsMap[status] = listEvent;
      emit(state.assign(selectedStatus: status, eventsMap: eventsMap, numPage: 0, totalEvent: totalEvent, availableYears: availableYears, yearCounts: yearCounts, clearYear: true, clearMonth: true, countEventsArchivesCateogry: countEventsArchivesCateogry));
    } else emit(state.assign(selectedStatus: status, totalEvent: totalEvent, availableYears: availableYears, yearCounts: yearCounts, clearYear: true, clearMonth: true, countEventsArchivesCateogry: countEventsArchivesCateogry));
  }

  void onCategorySelected(String category) async {
    Map<String, FilterWrapper> filters = Map.from(state.filters);
    if(filters["categories"] == null){
      filters["categories"] = new FilterWrapper("categories", <String,bool>{}, (Event event, List<String>? value) =>
      value == null || value.any((category) => category == event.category));
    }
    Map<String,bool> categoriesSelected = filters["categories"]!.fieldValue;
    categoriesSelected[category] = categoriesSelected[category] != null?!categoriesSelected[category]!:true;
    filters["categories"]!.fieldValue = categoriesSelected;

    // Refresh available years counts based on new filters
    List<int> range = await _databaseRepository.getHistoryYearsRange(state.selectedStatusTab);
    List<int> availableYears = [];
    Map<int, int> yearCounts = {};
    if (range.length == 2) {
      final List<Future<void>> futures = [];
      for(int y = range[1]; y >= range[0]; y--) {
        availableYears.add(y);
        futures.add(_databaseRepository.getHistoryCountByDateRange(state.selectedStatusTab, DateTime(y, 1, 1), DateTime(y + 1, 1, 1), filters: filters).then((count) => yearCounts[y] = count));
      }
      await Future.wait(futures);
    }

    Map<int, int> monthCounts = Map.from(state.monthCounts);
    if(state.selectedYear != null) {
      final List<Future<void>> futures = [];
      for(int m = 1; m <= 12; m++) {
        futures.add(_databaseRepository.getHistoryCountByDateRange(state.selectedStatusTab, DateTime(state.selectedYear!, m, 1), DateTime(state.selectedYear!, m + 1, 1), filters: filters).then((count) => monthCounts[m] = count));
      }
      await Future.wait(futures);
    }

    Map<String, FilterWrapper> activeFilters = Map.from(filters);
    if(state.selectedMonth != null && state.selectedYear != null) {
      DateTime start = DateTime(state.selectedYear!, state.selectedMonth!, 1);
      DateTime end = DateTime(state.selectedYear!, state.selectedMonth! + 1, 1);
      activeFilters["startDate"] = new FilterWrapper("startDate", start, (Event event, value) => event.end.isAfter(value) || event.end.isAtSameMomentAs(value));
      activeFilters["endDate"] = new FilterWrapper("endDate", end, (Event event, value) => event.end.isBefore(value));
      activeFilters.remove("dateRange");
    }

    listEvent = await _databaseRepository.getEventsHistoryFiltered(state.selectedStatusTab, activeFilters, limit: startingElements);
    canLoadMore[state.selectedStatusTab] = listEvent.length >= startingElements;
    Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
    eventsMap[state.selectedStatusTab] = listEvent;
    List<String> listCategorySelected = List.from(state.selectedCategory);
    if(!listCategorySelected.contains(category)){
      listCategorySelected.add(category);
    }else{
      listCategorySelected.remove(category);
    }
    int totalEvent = await _databaseRepository.getEventsHistoryFilteredCount(state.selectedStatusTab, activeFilters);
    emit(state.assign(eventsMap: eventsMap, selectedCategory: listCategorySelected, filters: filters, totalEvent: totalEvent, availableYears: availableYears, yearCounts: yearCounts, monthCounts: monthCounts));
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) async {
    HistoryPageState statePrev = state;
    emit(LoadingHistoryPageState.fromState(statePrev, statePrev.selectedStatusTab));
    
    // Refresh available years counts based on new filters
    List<int> range = await _databaseRepository.getHistoryYearsRange(statePrev.selectedStatusTab);
    List<int> availableYears = [];
    Map<int, int> yearCounts = {};
    if (range.length == 2) {
      final List<Future<void>> futures = [];
      for(int y = range[1]; y >= range[0]; y--) {
        availableYears.add(y);
        futures.add(_databaseRepository.getHistoryCountByDateRange(statePrev.selectedStatusTab, DateTime(y, 1, 1), DateTime(y + 1, 1, 1), filters: filters).then((count) => yearCounts[y] = count));
      }
      await Future.wait(futures);
    }

    Map<int, int> monthCounts = Map.from(statePrev.monthCounts);
    if(statePrev.selectedYear != null) {
      final List<Future<void>> futures = [];
      for(int m = 1; m <= 12; m++) {
        futures.add(_databaseRepository.getHistoryCountByDateRange(statePrev.selectedStatusTab, DateTime(statePrev.selectedYear!, m, 1), DateTime(statePrev.selectedYear!, m + 1, 1), filters: filters).then((count) => monthCounts[m] = count));
      }
      await Future.wait(futures);
    }

    // Update filters to include current time context if applicable
    Map<String, FilterWrapper> activeFilters = Map.from(filters);
    if(statePrev.selectedMonth != null && statePrev.selectedYear != null) {
      DateTime start = DateTime(statePrev.selectedYear!, statePrev.selectedMonth!, 1);
      DateTime end = DateTime(statePrev.selectedYear!, statePrev.selectedMonth! + 1, 1);
      activeFilters["startDate"] = new FilterWrapper("startDate", start, (Event event, value) => event.end.isAfter(value) || event.end.isAtSameMomentAs(value));
      activeFilters["endDate"] = new FilterWrapper("endDate", end, (Event event, value) => event.end.isBefore(value));
      activeFilters.remove("dateRange");
    }

    listEvent = await _databaseRepository.getEventsHistoryFiltered(statePrev.selectedStatusTab, activeFilters, limit: startingElements);
    canLoadMore[statePrev.selectedStatusTab] = listEvent.length >= startingElements;
    loaded.forEach((key, value) { loaded[key] = false; });
    loaded[statePrev.selectedStatusTab] = true;
    Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
    eventsMap[statePrev.selectedStatusTab] = listEvent;

    int totalEvent = await _databaseRepository.getEventsHistoryFilteredCount(statePrev.selectedStatusTab, activeFilters);
    emit(state.assign(filters: filters, eventsMap: eventsMap, numPage: 0, totalEvent: totalEvent, availableYears: availableYears, yearCounts: yearCounts, monthCounts: monthCounts));
  }

  Future<Map<int, int>> _loadCountHistory() async {
    Map<int, int> countEventsArchives = {};
    int countEnd = await _databaseRepository.getHistoryCountsByType(EventStatus.Ended, null);
    countEventsArchives[EventStatus.Ended] = countEnd;
    int countDelete = await _databaseRepository.getHistoryCountsByType(EventStatus.Deleted, null);
    countEventsArchives[EventStatus.Deleted] = countDelete;
    int countRefused = await _databaseRepository.getHistoryCountsByType(EventStatus.Refused, null);
    countEventsArchives[EventStatus.Refused] = countRefused;
    countEventsArchives[-99] = countEnd + countRefused + countDelete;
    return countEventsArchives;
  }

  Future<Map<String, int>> _loadCountHisotryCategory([int? status]) async{
    Map<String, int> countCustomerArchivesCategory = {};
    await Future.wait(
        categories.entries.map((entry) async {
          final key = entry.key;
          int count = await _databaseRepository.getHistoryCountsByType(status ?? state.selectedStatusTab, key);
          countCustomerArchivesCategory[key] = count;
        }),
    );
    return countCustomerArchivesCategory;
  }

  void onTouchPieChart(FlTouchEvent event, PieTouchResponse? pieTouchResponse){
    if(pieTouchResponse != null && pieTouchResponse.touchedSection != null && pieTouchResponse.touchedSection?.touchedSectionIndex != -1)
      onStatusTabSelected(Headers.tabsHeadersHistory.elementAt(pieTouchResponse.touchedSection!.touchedSectionIndex).value);
  }

  void onTouchPieChartCategory(FlTouchEvent event, PieTouchResponse? pieTouchResponse){
    if(pieTouchResponse != null && pieTouchResponse.touchedSection != null && pieTouchResponse.touchedSection?.touchedSectionIndex != -1)
      onCategorySelected(categories.keys.elementAt(pieTouchResponse.touchedSection!.touchedSectionIndex));
  }

  void nextPage(){
    if(canLoadMore[state.selectedStatusTab]??false){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage+loadingElements));
  }

  void previousPage(){
    if(canLoadMore[state.selectedStatusTab]??false){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage-loadingElements));
  }

  void forceRefresh() {
    emit(state.assign(refresh: true));
    emit(state.assign(refresh: false));
  }
}