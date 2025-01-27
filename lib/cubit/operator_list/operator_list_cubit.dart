import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

part 'operator_list_state.dart';

class OperatorListCubit extends Cubit<OperatorListState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();
  late List<Account> operators;
  final int startingElements = 15;
  final int loadingElements = 10;
  late bool canLoadMore;

  OperatorListCubit(this._databaseRepository) :
        super(LoadingOperators()){
    getOperators();
  }

  void getOperators() async {
    operators = await _databaseRepository.getOperators(limit: startingElements);
    canLoadMore = operators.length >= startingElements;
    emit(ReadyOperators(operators));
  }

  void loadMoreData() async {
    int prevSize = operators.length;
    operators.addAll(await _databaseRepository.getOperatorsFree("", state.searchTimeField, state.searchTimeField.add(new Duration(minutes: Constants.WORKTIME_SPAN)), limit: loadingElements, startFrom: operators.last.id));
    canLoadMore = operators.length >= prevSize + loadingElements;
    emit((state as ReadyOperators).assign(operators: operators));
  }

  void onSearchFieldChanged(Map<String, FilterWrapper> filters) {
    String text = filters["name"]!.fieldValue;
    if(state is ReadyOperators) {
      emit((state as ReadyOperators).assign(searchNameField: text, operators:
        !string.isNullOrEmpty(text) && text.toLowerCase().contains(state.searchNameField.toLowerCase())?
        (state as ReadyOperators).filteredOperators : operators)
      );
    }
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) async {
    DateTime? newDate = filters["date"]!.fieldValue;
    if(newDate == null)
      operators = await _databaseRepository.getOperators(limit: startingElements);
    else if(state.searchTimeField != newDate)
      operators = await _databaseRepository.getOperatorsFree("", newDate, newDate.add(new Duration(minutes: Constants.WORKTIME_SPAN)), limit: startingElements);
    canLoadMore = operators.length >= startingElements;
    scrollToTheTop();
    emit((state as ReadyOperators).assign(searchTimeField: newDate, operators: operators));
  }

  void scrollToTheTop(){
    scrollController.animateTo(
    0.0,
    curve: Curves.easeOut,
    duration: const Duration(milliseconds: 100),
  );
  }

}
