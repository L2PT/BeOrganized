import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';

part 'history_event_list_state.dart';

class HistoryEventListCubit extends Cubit<HistoryEventListState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();
  List<Event> listEvent = [];
  int startingElements = 10;
  int loadingElements = 1;
  Map<int, bool> canLoadMore = {};
  Map<int, bool> loaded = {};

  HistoryEventListCubit(this._databaseRepository, [int? _selectedStatusTab]) :
        super(HistoryLoading(_selectedStatusTab)){
    startingElements = PlatformUtils.isMobile? 10 : 20;
    loadingElements = PlatformUtils.isMobile? 5 : 10;
    onStatusTabSelected(state.selectedStatusTab);
  }

  void loadMoreData() async {
    List<Event> selectedEvents = (state as HistoryReady).selectedEvents();
    listEvent = List.from(selectedEvents);
    listEvent.addAll(await _databaseRepository.getEventsHistoryFiltered(state.selectedStatusTab, state.filters, limit: loadingElements, startFrom: selectedEvents.last.id));
    canLoadMore[state.selectedStatusTab] = listEvent.length >= selectedEvents.length+loadingElements;
    Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
    eventsMap[state.selectedStatusTab] = listEvent;
    emit(state.assign(eventsMap: eventsMap));
  }

  void onStatusTabSelected(int status) async {
    if((state.eventsMap[status] == null && loaded[status] == null) || loaded[status] == false || state.eventsMap[status]!.length<startingElements){
      loaded.forEach((key, value) { loaded[key] = false; });
      loaded[status] = true; //declare loaded before actually have loaded is error prone but it's a way to prevent multiple call of the listener
      listEvent = await _databaseRepository.getEventsHistoryFiltered(status, state.filters, limit: startingElements);
      canLoadMore[status] = listEvent.length >= startingElements;
      Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
      eventsMap[status] = listEvent;
      emit(state.assign(selectedStatus: status, eventsMap: eventsMap,));
    } else emit(state.assign(selectedStatus: status));
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) async {
    listEvent = await _databaseRepository.getEventsHistoryFiltered(state.selectedStatusTab, filters, limit: startingElements);
    canLoadMore[state.selectedStatusTab] = listEvent.length >= startingElements;
    loaded.forEach((key, value) { loaded[key] = false; });
    loaded[state.selectedStatusTab] = true;
    Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
    eventsMap[state.selectedStatusTab] = listEvent;
    // filtering moved into the repository
    // Map<int, List<Event>> eventsMap =  Map.from(state.eventsMap);
    // eventsMap[state.selectedStatusTab] = state.eventsMap[state.selectedStatusTab]!.where((event) => event.isFilteredEvent(e, categorySelected, filterStartDate, filterEndDate)).toList();
    scrollToTheTop();
    emit(state.assign(filters: filters, eventsMap: eventsMap));
  }

  void scrollToTheTop(){
    scrollController.animateTo(0.0, curve: Curves.easeOut, duration: const Duration(milliseconds: 100),);
  }

}
