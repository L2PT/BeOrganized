import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';

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
  String selectedTypology = Account.ALL;

  OperatorSelectionCubit(this._databaseRepository, Event? _event, this.isTriState) :
        this._event = _event ?? new Event.empty(),
        super(LoadingOperators()){
      getOperators(isTriState);
  }

  void getOperators(bool isTriState) async {
    if (isTriState && !_event.isRepeated) {
      operators = await _databaseRepository.getOperatorsFree(
          _event.id, _event.start, _event.end);
      operators.sort((a, b) => a.surname.compareTo(b.surname));
      canLoadMore = false;
    } else {
      operators = await _databaseRepository.getOperators();
      canLoadMore = false;
    }
    operators.removeWhere((op) => op.supervisor || op.typology == Account.RESPONSABILE);
    emit(new ReadyOperators(_filterData(operators), event: _event, allOperators: operators));
  }

  void loadMoreData() async {
    if(state is ReadyOperators){
      List<Account> preLoaded = [...(state as ReadyOperators).filteredOperators];
      List<Account> loaded;
      if (isTriState) {
        loaded = await _databaseRepository.getOperatorsFree(_event.id, _event.start, _event.end,
            limit: loadingElements,
            startFrom: (state as ReadyOperators).filteredOperators.last.id);
      }else {
        loaded = await _databaseRepository.getOperators(limit: loadingElements, startFrom: (state as ReadyOperators).filteredOperators.last.surname);
      }

      loaded.removeWhere((op) => op.supervisor || op.typology == Account.RESPONSABILE);
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
    // Deprecated in favor of onTapPrimary and onTapSecondary, but kept for simple-select compatibility
    if (state is! ReadyOperators) return;
    ReadyOperators readyState = (state as ReadyOperators);
    Map<String, int> selectionListUpdated = Map.from(readyState.selectionList);
    if (selectionListUpdated.containsKey(operator.id)) {
      int currentValue = selectionListUpdated[operator.id]!;
      int newValue = currentValue == 1 ? 0 : 1;
      selectionListUpdated[operator.id] = newValue;
      emit(readyState.assign(preSelectedList: selectionListUpdated));
    }
  }

  void onTapPrimary(Account operator) {
    if (state is! ReadyOperators) return;
    ReadyOperators readyState = (state as ReadyOperators);
    Map<String, int> selectionListUpdated = Map.from(readyState.selectionList);
    
    bool newFlag = readyState.primaryOperatorSelected;
    
    if (selectionListUpdated[operator.id] == 2) {
      selectionListUpdated[operator.id] = 0;
      newFlag = false;
    } else {
      selectionListUpdated.forEach((key, value) {
        if (value == 2) {
          selectionListUpdated[key] = 0;
        }
      });
      selectionListUpdated[operator.id] = 2;
      newFlag = true;
    }
    
    emit(readyState.assign(
      preSelectedList: selectionListUpdated,
      primaryOperatorSelected: newFlag,
    ));
  }

  void onTapSecondary(Account operator) {
    if (state is! ReadyOperators) return;
    ReadyOperators readyState = (state as ReadyOperators);
    Map<String, int> selectionListUpdated = Map.from(readyState.selectionList);
    
    bool newFlag = readyState.primaryOperatorSelected;
    
    if (selectionListUpdated[operator.id] == 1) {
      selectionListUpdated[operator.id] = 0;
    } else {
      if (selectionListUpdated[operator.id] == 2) {
        newFlag = false;
      }
      selectionListUpdated[operator.id] = 1;
    }
    
    emit(readyState.assign(
      preSelectedList: selectionListUpdated,
      primaryOperatorSelected: newFlag,
    ));
  }

  void onTypologyChanged(String typology) {
    selectedTypology = typology;
    if (state is ReadyOperators) {
      emit((state as ReadyOperators).assign(
        filteredOperators: _filterData(operators),
      ));
    }
  }

  void onSearchFieldChanged(Map<String, FilterWrapper> filters) {
    String text = filters["name"]!.fieldValue;
    state.searchNameField = text;
    scrollToTheTop();
    if (state is ReadyOperators) {
      emit((state as ReadyOperators).assign(
        searchNameField: text,
        filteredOperators: _filterData(operators),
      ));
    }

    if(canLoadMore && state is ReadyOperators && (state as ReadyOperators).filteredOperators.length<startingElements)
      loadMoreData();
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) {
    // not implemented
  }

  List<Account> _filterData(List<Account> operatorsList) {
    List<Account> filtered = [];
    for (var operator in operatorsList) {
      if (selectedTypology != Account.ALL && operator.typology != selectedTypology) {
        continue;
      }
      if (!string.isNullOrEmpty(state.searchNameField)) {
        String searchedFields = "${operator.name} ${operator.surname}";
        if (!searchedFields.toLowerCase().contains(state.searchNameField.toLowerCase())) {
          continue;
        }
      }
      filtered.add(operator);
    }
    return filtered;
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

  bool validateAndSave(BuildContext context) {
    if(!isTriState || (state as ReadyOperators).primaryOperatorSelected) {
      saveSelectionToEvent();
      return true;
    } else {
      SuccessAlert(
        context,
        title: "ERRORE",
        text: "Seleziona l'operatore principale",
        showAction: true,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red,
      ).show();
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

  @override
  Future<void> close() {
    scrollController.dispose();
    return super.close();
  }

}