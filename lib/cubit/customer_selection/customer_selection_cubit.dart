
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/agolia_service.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';

part 'customer_selection_state.dart';

class CustomerSelectionCubit extends Cubit<CustomerSelectionState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();
  late List<Customer> customers;
  final int startingElements = 30;
  final int loadingElements = 15;
  Map<String, ExpansionTileController> mapController = {};

  CustomerSelectionCubit(this._databaseRepository, Event? _event) :
        super(LoadingCustomers()){
    getCustomers(_event ?? new Event.empty());
  }

  void getCustomers(Event event) async {
    customers = await _databaseRepository.getCustomers(state.filters, limit: startingElements);
    emit(state.assign(filteredCustomers: customers,event:  event));
  }

  void loadMoreData() async {
    if(state is ReadyCustomers){
      List<Customer> loaded;
      if(state.searchNameField.isNotEmpty){
        List<String> idCustomers = await AlgoliaService.searchCustomer(state.searchNameField, hitsPerPage: loadingElements, page: state.numPage);
        loaded = await _databaseRepository.getCustomersByIds(idCustomers);
      }else{
        loaded = await _databaseRepository.getCustomers(state.filters,limit: loadingElements, startFrom: (state as ReadyCustomers).filteredCustomers.last.id);
      }
      customers.addAll(loaded);
      bool canLoadMore = loaded.length >= loadingElements;
      emit((state as ReadyCustomers).assign( filteredCustomers: customers, canLoadMore: canLoadMore));
    }
  }


  void onSearchFieldChanged(Map<String, FilterWrapper> filters) {
    CustomerSelectionState stateprev = state;
    emit(LoadingCustomers());
    scrollToTheTop();
    _filterData(filters, stateprev.event, stateprev.customer);
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) {
    // not implemented
  }

  void _filterData(Map<String, FilterWrapper> filters, Event e, Customer customer) async{
    String searchquery = filters['searchQuery']!.fieldValue;
    List<Customer> loaded = List.empty();
    if(searchquery.isNotEmpty){
      List<String> idCustomers = await AlgoliaService.searchCustomer(filters['searchQuery']!.fieldValue, hitsPerPage: startingElements, );
      if(idCustomers.isNotEmpty)
        loaded = await _databaseRepository.getCustomersByIds(idCustomers);
    }else{
      loaded = await _databaseRepository.getCustomers(state.filters, limit: startingElements);
    }
    bool canLoadMore = loaded.length >= startingElements;
    emit(state.assign( filteredCustomers: loaded, searchNameField: filters["searchQuery"]!.fieldValue, filters: filters,
        event: e, canLoadMore: canLoadMore, customer: customer));
  }

  void onExpansionChanged(bool isOpen, Customer customer){
    Customer customerCopy = Customer.fromMap("", customer.toMap());
    if(isOpen){
      ExpansionTileController? controller = mapController[(state as ReadyCustomers).customer.id];
      if(controller != null && controller.isExpanded)
        controller.collapse();
      emit((state as ReadyCustomers).assign(customer: customerCopy));
    }else{
      if(customer == (state as ReadyCustomers).customer){
        state.event.customer = Customer.empty();
        emit((state as ReadyCustomers).assign(customer: Customer.empty()));
      }
    }
  }

  ExpansionTileController getController(String id){
    ExpansionTileController controller = new ExpansionTileController();
    if(mapController[id] == null){
      mapController[id] = controller;
      return controller;
    }
    return mapController[id]!;
  }

  bool getExpadedMode(Customer customer){
    if((state as ReadyCustomers).customer.id == customer.id){
      return true;
    }
    return false;
  }
  void saveSelectionToEvent(){
    state.event.customer = state.customer;
  }

  bool validateAndSave() {
    if(state.customer.id.isNotEmpty) {
      saveSelectionToEvent();
      return true;
    } else {
      PlatformUtils.notifyErrorMessage("Seleziona un cliente, cliccando su di esso");
      return false;
    }
  }

  bool deleteCustomer(Customer customer){
    _databaseRepository.deleteCustomer(customer.id);
    List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
    int posOpe = filteredCustomers.indexOf(customer);
    ExpansionTileController? controller = mapController[(state as ReadyCustomers).customer.id];
    if(controller != null && controller.isExpanded)
      controller.collapse();
    filteredCustomers.removeWhere((element) => element.id == customer.id);
    List<String> keys = List.of(List.of(mapController.keys.skip(posOpe)).reversed);
    int pos = 1;
    keys.forEach((key) {
      if(pos < keys.length)
        mapController[key] = mapController[keys.elementAt(pos)]!;
      pos++;
    });
    mapController.remove(customer.id);
    if((state as ReadyCustomers).event.customer.id == customer.id){
      (state as ReadyCustomers).event.customer = Customer.empty();
    }
    emit((state as ReadyCustomers).assign( filteredCustomers: filteredCustomers));
    return true;
  }

  Event getEvent() {
    state.customer = state.event.customer;
    return state.event;
  }

  Event getEventCustomerEmpty() {
    (state as ReadyCustomers).event.customer = Customer.empty();
    return (state as ReadyCustomers).event;
  }

  Event getEventCustomer(Customer customer) {
    (state as ReadyCustomers).event.customer = customer;
    return (state as ReadyCustomers).event;
  }

  void scrollToTheTop(){
    scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 100),
    );
  }

  void removeAddressOnCustomer(Address address){
    Customer customer = Customer.fromMap("", (state as ReadyCustomers).customer.toMap());
    customer.addresses.removeWhere((element) => element == address);
    if(customer.address == address && customer.addresses.isNotEmpty){
      customer.address = customer.addresses.first;
    }else{
      customer.address = Address.empty();
    }
    List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
    filteredCustomers.where((element) => element.id == customer.id).first.addresses.removeWhere((element) => element == address);
    _databaseRepository.updateCustomer(customer.id, customer);
    emit((state as ReadyCustomers).assign(customer: customer, filteredCustomers: filteredCustomers));
  }

  void selectAddressOnCustomer(Address address){
    Customer customer = Customer.fromMap("", (state as ReadyCustomers).customer.toMap());
    customer.address = address;
    List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
    filteredCustomers.where((element) => element.id == customer.id).first.address = address;
    emit((state as ReadyCustomers).assign(customer: customer, filteredCustomers: filteredCustomers));
  }

  void forceRefresh() {
    emit(state.assign(status: _formStatus.loading));
    emit(state.assign(status: _formStatus.normal));
  }

}
