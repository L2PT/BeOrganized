import 'package:bloc/bloc.dart';
import 'package:venturiautospurghi/cubit/web/common/common_page_state.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;

part 'event_list_page_state.dart';

class EventListPageCubit extends Cubit<EventListPageState> {
  final CloudFirestoreService _databaseRepository;
  List<Event> listEvent = [];
  final int startingElements = 250;
  final int loadingElements = 10;
  bool canLoadMore = true;
  bool _isBozze = false;

  EventListPageCubit(this._databaseRepository) : super(LoadingEventListPageState());

  void initCubit([bool isBozze = false,]) {
    _isBozze = isBozze;
    emit(state.assign(isBozze: isBozze,));
    Map<String, FilterWrapper> filters = Map.from(state.filters);
    if (_isBozze) {
      filters["status"] = filters["status"]!.update(EventStatus.Bozza);
    } else {
      filters["status"] = filters["status"]!.update(null);
    }
    emit(state.assign(filters: filters));
    onFiltersChanged(state.filters);
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) async {
    if (_isBozze) {
      filters["status"] = filters["status"]!.update(EventStatus.Bozza);
    } else {
      filters["status"] = filters["status"]!.update(null);
    }
    await loadCountEvent();
    emit(LoadingEventListPageState(isBozze: _isBozze, filters: filters));
    // Instead of do a basic repo get and evaluateEventsMap() the whole filtering process is handled directly in the query
    listEvent = await _databaseRepository.getEventsActiveFiltered(filters, limit: startingElements);
    canLoadMore = listEvent.length >= startingElements;
    emit(state.assign(isBozze: _isBozze, filters: filters, eventsList: listEvent, numPage: 0, totalEvent: canLoadMore ? state.totalEvent : listEvent.length));
  }

  void loadMoreData() async {
    listEvent = List.from(state.listEventFiltered);
    listEvent.addAll(await _databaseRepository.getEventsActiveFiltered(state.filters, limit: loadingElements, startFrom: state.listEventFiltered.last.id));
    canLoadMore = listEvent.length >= state.listEventFiltered.length+loadingElements;
    emit(state.assign(eventsList: listEvent));
  }

  Future<int> loadCountEvent() async {
    int totalCount = await _databaseRepository.getEventCountsByStatus(_isBozze ? EventStatus.Bozza : null);
    emit(state.assign(totalEvent: totalCount));
    return totalCount;
  }

  void nextPage(){
    if(canLoadMore){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage+loadingElements));
  }

  void previousPage(){
    if(canLoadMore){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage-loadingElements));
  }

  void onSelectedEvent(Event event, bool? value){
    Map<String, bool> mapSelected = Map.from(state.mapSelected);
    mapSelected.remove(event.id);
    mapSelected.putIfAbsent(event.id, () => value??false);
    emit(state.assign(mapSelected: mapSelected));
  }

  void onSelectedAllEvent(bool? value){
    Map<String, bool> mapSelected = {};
    state.listEventFiltered.forEach((customer) {
      mapSelected.putIfAbsent(customer.id, () => value??false);
    });
    emit(state.assign(mapSelected: mapSelected));
  }

  bool deleteEvent(Event event, bool repeatMode ){
    _.DateUtils.isBefore(event.start,_.DateUtils.now())?
    _databaseRepository.deleteEventPast(event, repeatMode)
        :_databaseRepository.deleteEvent(event, repeatMode);
    List<Event> filteredEvents = List.of(state.listEventFiltered);
    filteredEvents.removeWhere((element) => element.id == event.id);
    return true;
  }

  void deleteAllEvent(bool repeatMode){
    List<Event> filteredEvents = List.of(state.listEventFiltered);
    Map<String, bool> mapSelected = Map.from(state.mapSelected);
    List<String> idDeleteCustomer = [];
    mapSelected.entries.where((entry) => entry.value).forEach((entry) {
      Event e = filteredEvents.where((element) => element.id == entry.key).first;
      _.DateUtils.isBefore(e.start,_.DateUtils.now())?
      _databaseRepository.deleteEventPast(e, repeatMode)
          :_databaseRepository.deleteEvent(e, repeatMode);
      filteredEvents.removeWhere((element) => element.id == entry.key);
      idDeleteCustomer.add(entry.key);
    });
    idDeleteCustomer.forEach((id) => mapSelected.remove(id));
    emit(state.assign(mapSelected: mapSelected));
  }

  bool isSelected(){
    return state.mapSelected.entries.where((entry) => entry.value).length > 0;
  }

  void forceRefresh() {
    emit(state.assign(refresh: true));
    emit(state.assign(refresh: false));
  }

}
