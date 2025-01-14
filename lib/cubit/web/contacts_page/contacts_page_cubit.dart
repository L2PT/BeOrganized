import 'package:bloc/bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:venturiautospurghi/cubit/web/common/common_page_state.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';

part 'contacts_page_state.dart';

class ContactsPageCubit extends Cubit<ContactsPageState> {

  final CloudFirestoreService _databaseRepository;
  bool canLoadMoreCustomer = true;
  final int startingElements = 250;
  final int loadingElements = 10;

  ContactsPageCubit(this._databaseRepository,) : super(LoadingContactsPageState());

  void initCubit(){
    onFiltersChangedCustomer(FilterWrapper.initFilterCustomer());
    emit(ReadyContactsPageState());    
  }

  void loadMoreData() async {
    List<Customer> listCustomer = List.from(state.customerList);
    listCustomer.addAll(await _databaseRepository.getCustomersActiveFiltered(state.filters, limit: loadingElements, startFrom: state.customerList.last.surname));
    canLoadMoreCustomer = listCustomer.length == state.customerList.length+loadingElements;
    emit(state.assign(customerList: listCustomer));
  }
  //FILTER CUSTOMER //
  void onFiltersChangedCustomer(Map<String, FilterWrapper> filters, [int? status, bool count = true]) async {
    ContactsPageState statePrev = state;
    emit(LoadingContactsPageState());
    // Instead of do a basic repo get and evaluateEventsMap() the whole filtering process is handled directly in the query
    statePrev.filters.forEach((key, value) {
      if (!filters.containsKey(key)) {
        filters[key] = value;
      }
    });
    Map<int, int> countCustomerTypology =  count?await loadCountCustomer():statePrev.countEntity;
    List<Customer> listCustomer = await _databaseRepository.getCustomersActiveFiltered(filters, limit: startingElements);
    canLoadMoreCustomer = listCustomer.length >= startingElements;
    emit(state.assign(filters: filters, customerList: listCustomer,selectedStatus: status??statePrev.selectedStatusTab, countCustomerTypology: countCustomerTypology,
        numPage: 0,totalEvent: canLoadMoreCustomer?countCustomerTypology[status??statePrev.selectedStatusTab]:listCustomer.length));
  }

  Future<Map<int, int>> loadCountCustomer() async {
    Map<int, int> countCustomerTypology = {};
    countCustomerTypology[Customer.getIntTypology(Customer.ALL)] = await _databaseRepository.getCustomerCountsByType(null);
    countCustomerTypology[Customer.getIntTypology(Customer.PRIVATO)] = await _databaseRepository.getCustomerCountsByType(Customer.PRIVATO);
    countCustomerTypology[Customer.getIntTypology(Customer.AZIENDA)] = await _databaseRepository.getCustomerCountsByType(Customer.AZIENDA);
    countCustomerTypology[Customer.getIntTypology(Customer.REFERENTE)] = await _databaseRepository.getCustomerCountsByType(Customer.REFERENTE);
    countCustomerTypology[Customer.getIntTypology(Customer.AMMINISTRATORE)] = await _databaseRepository.getCustomerCountsByType(Customer.AMMINISTRATORE);
    return countCustomerTypology;
  }

  void deleteAllCustomer(){
    List<Customer> filteredCustomers = List.of(state.customerList);
    Map<String, bool> mapSelected = Map.from(state.mapSelected);
    List<String> idDeleteCustomer = [];
    mapSelected.entries.where((entry) => entry.value).forEach((entry) {
      _databaseRepository.deleteCustomer(entry.key);
      filteredCustomers.removeWhere((element) => element.id == entry.key);
      idDeleteCustomer.add(entry.key);
    });
    idDeleteCustomer.forEach((id) => mapSelected.remove(id));
    emit(state.assign(mapSelected: mapSelected));
  }

  Event getEventCustomer(Customer customer) {
    Event event = Event.empty();
    event.customer = customer;
    return event;
  }

  bool isSelected(){
    return state.mapSelected.entries.where((entry) => entry.value).length > 0;
  }

  void onStatusTabSelected(int status) async {
    String typology = Customer.getStringTypology(status);
    Map<String, FilterWrapper> filter = Map.from(state.filters);
    filter["typology"] = new FilterWrapper("typology", typology != Customer.ALL?typology:null, (Customer customer, value) => value == null || customer.typology == value);
    onFiltersChangedCustomer(filter, status, false);
  }

  void onTouchPieChart(FlTouchEvent event, PieTouchResponse? pieTouchResponse){
    if(pieTouchResponse != null && pieTouchResponse.touchedSection != null && pieTouchResponse.touchedSection?.touchedSectionIndex != -1)
      onStatusTabSelected(pieTouchResponse.touchedSection!.touchedSectionIndex+1);
  }


  void nextPage(){
    if(canLoadMoreCustomer){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage+loadingElements));
  }

  void previousPage(){
    if(canLoadMoreCustomer){
      loadMoreData();
    }
    emit(state.assign(numPage: state.numPage-loadingElements));
  }

  void onSelectedCustomer(Customer customer, bool? value){
    Map<String, bool> mapSelected = Map.from(state.mapSelected);
    mapSelected.remove(customer.id);
    mapSelected.putIfAbsent(customer.id, () => value??false);
    emit(state.assign(mapSelected: mapSelected));
  }

  void onSelectedAllCustomer(bool? value){
    Map<String, bool> mapSelected = {};
    state.customerList.forEach((customer) {
      mapSelected.putIfAbsent(customer.id, () => value??false);
    });
    emit(state.assign(mapSelected: mapSelected));
  }

  bool deleteCustomer(Customer customer){
    _databaseRepository.deleteCustomer(customer.id);
    List<Customer> filteredCustomers = List.of(state.customerList);
    filteredCustomers.removeWhere((element) => element.id == customer.id);
    return true;
  }

  void forceRefresh() {
    emit(state.assign(refresh: true));
    emit(state.assign(refresh: false));
  }

}
