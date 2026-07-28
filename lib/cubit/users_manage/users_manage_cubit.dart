import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'users_manage_state.dart';

class UsersManageCubit extends Cubit<UsersManageState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();

  List<Account> accountList = [];
  final int startingElements = 25;
  final int loadingElements = 10;
  bool canLoadMore = true;

  UsersManageCubit(this._databaseRepository, Map<String, dynamic> filters,
      ): super(LoadingUsersManage()) {
    onFiltersChanged(state.filters);
  }

  void loadMoreData() async {
    accountList = List.from(state.accountList);
    accountList.addAll(await _databaseRepository.getAccountsActiveFiltered(state.filters, limit: loadingElements, startFrom: state.accountList.last.surname));
    canLoadMore = accountList.length == state.accountList.length+loadingElements;
    emit(state.assign(accountList: accountList));
  }

  Future<List<Account>> onFiltersChanged(Map<String, FilterWrapper> filters, [int? status]) async {
    // Instead of do a basic repo get and evaluateEventsMap() the whole filtering process is handled directly in the query
    accountList = await _databaseRepository.getAccountsActiveFiltered(filters, limit: startingElements);
    canLoadMore = accountList.length == startingElements;
    scrollToTheTop();
    emit(state.assign(selectedStatus: status, filters: filters, accountList: accountList));
    return accountList;
  }


  void scrollToTheTop(){
    if(scrollController.hasClients)
      scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 100),
      );
  }

  Event getEventAccount(Account operator) {
    Event event = Event.empty();
    event.operator = operator;
    return event;
  }

  void forceRefresh() {
    if (!isClosed) {
      emit(state.assign(status: _formStatus.loading));
      emit(state.assign(status: _formStatus.normal));
    }
  }

  Future<bool> deleteAccount(Account operator) async{
    if(await UserUtils.deleteUser(operator.id)){
      _databaseRepository.deleteOperator(operator.id);
      List<Account> filteredOperators = List.of(state.accountList);
      filteredOperators.removeWhere((element) => element.id == operator.id);
      emit(state.assign(accountList: filteredOperators));
      return true;
    }
    return false;
  }
}
