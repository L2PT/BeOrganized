import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

part 'operator_selection_state.dart';

class OperatorSelectionCubit extends Cubit<OperatorSelectionState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();
  final Event _event;
  final bool isTriState;
  late List<Account> operators;
  final int startingElements = 10;
  final int loadingElements = 5;
  bool canLoadMore = true;

  OperatorSelectionCubit(this._databaseRepository, Event? _event, this.isTriState) :
        this._event = _event ?? new Event.empty(),
        super(LoadingOperators()){
      getOperators(isTriState);
  }

  void getOperators(bool isTriState) async {
    if (isTriState) {
      operators = await _databaseRepository.getOperatorsFree(
          _event.id, _event.start, _event.end);
      operators.sort((a, b) => a.surname.compareTo(b.surname));
      canLoadMore = false;
    } else {
      operators = await _databaseRepository.getOperators();
      canLoadMore = false;
    }
    emit(new ReadyOperators(operators, event: _event));
  }

  void loadMoreData() async {
    if(state is ReadyOperators){
      List<Account> preLoaded = [...string.isNullOrEmpty(state.searchNameField) ? operators : (state as ReadyOperators).filteredOperators];
      List<Account> loaded;
      if (isTriState) {
        loaded = await _databaseRepository.getOperatorsFree(_event.id, _event.start, _event.end,
            limit: loadingElements,
            startFrom: (state as ReadyOperators).filteredOperators.last.id);
      }else {
        loaded = await _databaseRepository.getOperators(limit: loadingElements, startFrom: (state as ReadyOperators).filteredOperators.last.surname);
      }

      operators.addAll(loaded);
      // update the selection map with new operators
      Map<String,int> preLoadedSelectionList = Map.from((state as ReadyOperators).selectionList);
      loaded.forEach((operator) { preLoadedSelectionList[operator.id] = 0; });
      // update filtered operators with the new ones
      preLoaded.addAll(_filterData(loaded));
      canLoadMore = loaded.length >= loadingElements;
      emit((state as ReadyOperators).assign(preSelectedList: preLoadedSelectionList, filteredOperators: preLoaded));
    }
  }

  void onTap(Account operator) {
    if(Constants.debug) print("${operator.name} ${operator.surname} selected");
    ReadyOperators state = (this.state as ReadyOperators);
    Map<String,int> selectionListUpdated = new Map.from(state.selectionList);
    if(selectionListUpdated.containsKey(operator.id)) {
      bool newFlag = state.primaryOperatorSelected;
      int newValue = (selectionListUpdated[operator.id]!+1) % ((isTriState && (!newFlag || selectionListUpdated[operator.id] == 2))? 3 : 2);
      if(newValue == 2) newFlag = true;
      else if(newValue == 0 && selectionListUpdated[operator.id] == 2) newFlag = false;
      selectionListUpdated[operator.id] = newValue;
      emit(state.assign(preSelectedList: selectionListUpdated, primaryOperatorSelected: newFlag));
    }
  }


  void onSearchFieldChanged(Map<String, FilterWrapper> filters) {
    String text = filters["name"]!.fieldValue;
    state.searchNameField = text;
    scrollToTheTop();
    if(string.isNullOrEmpty(text))
      emit((state as ReadyOperators).assign(searchNameField: text, filteredOperators: operators));
    else if(text.toLowerCase().contains(state.searchNameField.toLowerCase()))
      emit((state as ReadyOperators).assign(searchNameField: text,
          filteredOperators: _filterData((state as ReadyOperators).filteredOperators)));
    else
      emit((state as ReadyOperators).assign(searchNameField: text, filteredOperators: _filterData(operators)));

    if(canLoadMore && state is ReadyOperators && (state as ReadyOperators).filteredOperators.length<startingElements)
      loadMoreData();
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) {
    // not implemented
  }

  List<Account> _filterData(operators){
    List<Account> filteredOperators = [];
    if(string.isNullOrEmpty(state.searchNameField))
      filteredOperators = List.of(operators);
    else {
      operators.forEach((operator) {
        String searchedFields = operator.name + " " + operator.surname;
        if(searchedFields.toLowerCase().contains(state.searchNameField.toLowerCase())){
          filteredOperators.add(operator);
        }
      });
    }
    return filteredOperators;
  }

  void saveSelectionToEvent(){
    ReadyOperators state = (this.state as ReadyOperators);
    List<Account> subOperators = [];
    state.selectionList.forEach((key, value) {
      Account tempAccount = operators.firstWhere((account) => account.id == key);
      if(value == 1) subOperators.add(tempAccount);
      else if(value == 2) _event.operator = tempAccount;
      operators.remove(tempAccount);
    });
    while(_event.suboperators.length>0) _event.suboperators.removeAt(0);
    _event.suboperators.addAll(subOperators);
  }

  bool validateAndSave() {
    if(!isTriState || (state as ReadyOperators).primaryOperatorSelected) {
      saveSelectionToEvent();
      return true;
    } else {
      PlatformUtils.notifyErrorMessage("Seleziona l'operatore principale, tappando due volte");
      return false;
    }
  }

  Event getEvent() => _event;

  void scrollToTheTop(){
    scrollController.animateTo(
    0.0,
    curve: Curves.easeOut,
    duration: const Duration(milliseconds: 100),
  );
  }

}