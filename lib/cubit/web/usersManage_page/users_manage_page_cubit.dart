import 'package:bloc/bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:venturiautospurghi/cubit/web/common/common_page_state.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'users_manage_page_state.dart';

class UsersManagePageCubit extends Cubit<UsersManagePageState> {

  final CloudFirestoreService _databaseRepository;
  bool canLoadMoreAccount = true;
  final int startingElements = 250;
  final int loadingElements = 10;

  UsersManagePageCubit(this._databaseRepository,) : super(LoadingUsersManagePageState());

  void initCubit(){
    onFiltersChangedAccount(FilterWrapper.initFilterAccount());
    emit(ReadyUsersManagePageState());
  }

  void loadMoreData() async {
    List<Account> listAccount = List.from(state.accountList);
    listAccount.addAll(await _databaseRepository.getAccountsActiveFiltered(state.filters, limit: loadingElements, startFrom: state.accountList.last.surname));
    canLoadMoreAccount = listAccount.length == state.accountList.length+loadingElements;
    emit(state.assign(accountList: listAccount));
  }
  //FILTER ACCOUNT //
  void onFiltersChangedAccount(Map<String, FilterWrapper> filters, [int? status, bool count = true]) async {
    UsersManagePageState statePrev = state;
    emit(LoadingUsersManagePageState());
    // Instead of do a basic repo get and evaluateEventsMap() the whole filtering process is handled directly in the query
    statePrev.filters.forEach((key, value) {
      if (!filters.containsKey(key)) {
        filters[key] = value;
      }
    });
    Map<int, int> countAccountTypology =  count?await loadCountAccount():statePrev.countEntity;
    List<Account> listAccount = await _databaseRepository.getAccountsActiveFiltered(filters, limit: startingElements);
    canLoadMoreAccount = listAccount.length >= startingElements;
    emit(state.assign(filters: filters, accountList: listAccount,selectedStatus: status??statePrev.selectedStatusTab, countAccountTypology: countAccountTypology,
        numPage: 0,totalEvent: canLoadMoreAccount?countAccountTypology[status??statePrev.selectedStatusTab]:listAccount.length));
  }

  Future<Map<int, int>> loadCountAccount() async {
    Map<int, int> countAccountTypology = {};
    countAccountTypology[Account.getIntTypology(Account.ALL)] = await _databaseRepository.getAccountCountsByType(null);
    countAccountTypology[Account.getIntTypology(Account.OPERATORE)] = await _databaseRepository.getAccountCountsByType(Account.OPERATORE);
    countAccountTypology[Account.getIntTypology(Account.RESPONSABILE)] = await _databaseRepository.getAccountCountsByType(Account.RESPONSABILE);
    return countAccountTypology;
  }

  void deleteAllAccount(){
    List<Account> filteredAccount = List.of(state.accountList);
    Map<String, bool> mapSelected = Map.from(state.mapSelected);
    List<String> idDeleteAccount = [];
    mapSelected.entries.where((entry) => entry.value).forEach((entry) {
      _databaseRepository.deleteOperator(entry.key);
      filteredAccount.removeWhere((element) => element.id == entry.key);
      idDeleteAccount.add(entry.key);
    });
    idDeleteAccount.forEach((id) => mapSelected.remove(id));
    emit(state.assign(mapSelected: mapSelected));
  }

  Event getEventAccount(Account operator) {
    Event event = Event.empty();
    event.operator = operator;
    return event;
  }

  bool isSelected(){
    return state.mapSelected.entries.where((entry) => entry.value).length > 0;
  }

  void onStatusTabSelected(int status) async {
    String typology = Account.getStringTypology(status);
    Map<String, FilterWrapper> filter = Map.from(state.filters);
    filter["typology"] = new FilterWrapper("typology", typology != Account.ALL?typology:null, (Account account, value) => value == null || account.typology == value);
    onFiltersChangedAccount(filter, status, false);
  }

  void onTouchPieChart(FlTouchEvent event, PieTouchResponse? pieTouchResponse){
    if(pieTouchResponse != null && pieTouchResponse.touchedSection != null && pieTouchResponse.touchedSection?.touchedSectionIndex != -1)
      onStatusTabSelected(pieTouchResponse.touchedSection!.touchedSectionIndex+1);
  }


  void nextPage(){
    if(canLoadMoreAccount){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage+loadingElements));
  }

  void previousPage(){
    if(canLoadMoreAccount){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage-loadingElements));
  }

  void onSelectedAccount(Account operator, bool? value){
    Map<String, bool> mapSelected = Map.from(state.mapSelected);
    mapSelected.remove(operator.id);
    mapSelected.putIfAbsent(operator.id, () => value??false);
    emit(state.assign(mapSelected: mapSelected));
  }

  void onSelectedAllAccount(bool? value){
    Map<String, bool> mapSelected = {};
    state.accountList.forEach((account) {
      mapSelected.putIfAbsent(account.id, () => value??false);
    });
    emit(state.assign(mapSelected: mapSelected));
  }

  Future<bool> deleteAccount(Account operator) async{
    if(await UserUtils.deleteUser(operator.id)){
      _databaseRepository.deleteOperator(operator.id);
      List<Account> filteredOperators = List.of(state.accountList);
      filteredOperators.removeWhere((element) => element.id == operator.id);
      Map<int, int> countAccountTypology = Map.from(state.countEntity);
      final key = Account.getIntTypology(operator.typology);
      countAccountTypology[key] = (countAccountTypology[key] ?? 0) - 1;
      countAccountTypology[Account.getIntTypology(Account.ALL)] = (countAccountTypology[Account.getIntTypology(Account.ALL)] ?? 0) -1;
      emit(state.assign(accountList: filteredOperators, countAccountTypology: countAccountTypology, totalEvent: countAccountTypology[Account.getIntTypology(Account.ALL)]));
      return true;
    }
    return false;
  }

  void forceRefresh() {
    emit(state.assign(refresh: true));
    emit(state.assign(refresh: false));
  }

}
