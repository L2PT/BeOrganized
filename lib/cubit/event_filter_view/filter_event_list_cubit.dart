import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';

part 'filter_event_list_state.dart';

class FilterEventListCubit extends Cubit<FilterEventListState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();
  List<Event> listEvent = [];
  final int startingElements = 25;
  final int loadingElements = 10;
  bool canLoadMore = true;
  final Account _account;
  final bool isBozze;

  FilterEventListCubit(this._databaseRepository, this._account, {this.isBozze = false}) : super(LoadingFilterEventList()){
    onFiltersChanged(state.filters);
  }

  void loadMoreData() async {
    listEvent = List.from(state.listEventFiltered);
    listEvent.addAll(await _databaseRepository.getEventsActiveFiltered(state.filters, limit: loadingElements, startFrom: state.listEventFiltered.last.id));
    canLoadMore = listEvent.length == state.listEventFiltered.length+loadingElements;
    emit(state.assign(eventsList: listEvent));
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) async {
    // Instead of do a basic repo get and evaluateEventsMap() the whole filtering process is handled directly in the query
    if(isBozze)
      filters["status"]!.fieldValue = EventStatus.Bozza;
    if(!_account.supervisor)
      filters["suboperators"]!.fieldValue = [_account];
    listEvent = await _databaseRepository.getEventsActiveFiltered(filters, limit: startingElements);
    canLoadMore = listEvent.length == startingElements;
    scrollToTheTop();
    emit(state.assign(filters: filters, eventsList: listEvent));
  }

  void scrollToTheTop(){
    if(scrollController.hasClients)
      scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 100),
      );
  }

}
