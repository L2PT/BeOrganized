
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/extensions.dart';

part 'customer_selection_state.dart';

class CustomerSelectionCubit extends Cubit<CustomerSelectionState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();
  late List<Customer> customers;
  final int startingElements = 10;
  final int loadingElements = 5;
  Map<String, ExpansionTileController> mapController = {};
  bool canLoadMore = true;

  CustomerSelectionCubit(this._databaseRepository, Event? _event) :
        super(LoadingCustomers()){
    getCustomers(_event ?? new Event.empty());
  }

  void getCustomers(Event event) async {
    customers = await _databaseRepository.getCustomers();
    canLoadMore = false;
    emit(new ReadyCustomers(customers, event));
  }

  void loadMoreData() async {
    if(state is ReadyCustomers){
      List<Customer> preLoaded = [...string.isNullOrEmpty(state.searchNameField) ? customers : (state as ReadyCustomers).filteredCustomers];
      List<Customer> loaded;
      loaded = await _databaseRepository.getCustomers(limit: loadingElements, startFrom: (state as ReadyCustomers).filteredCustomers.last.surname);
      customers.addAll(loaded);
      // update filtered operators with the new ones
      preLoaded.addAll(_filterData(loaded));
      canLoadMore = loaded.length >= loadingElements;
      emit((state as ReadyCustomers).assign( filteredCustomers: preLoaded));
    }
  }


  void onSearchFieldChanged(Map<String, FilterWrapper> filters) {
    String text = filters["name-surname"]!.fieldValue;
    state.searchNameField = text;
    scrollToTheTop();
    if(string.isNullOrEmpty(text))
      emit((state as ReadyCustomers).assign(searchNameField: text, filteredCustomers: customers));
    else if(text.toLowerCase().contains(state.searchNameField.toLowerCase()))
      emit((state as ReadyCustomers).assign(searchNameField: text,
          filteredCustomers: _filterData((state as ReadyCustomers).filteredCustomers)));
    else
      emit((state as ReadyCustomers).assign(searchNameField: text, filteredCustomers: _filterData(customers)));

    if(canLoadMore && state is ReadyCustomers && (state as ReadyCustomers).filteredCustomers.length<startingElements)
      loadMoreData();
  }

  void onFiltersChanged(Map<String, FilterWrapper> filters) {
    // not implemented
  }

  List<Customer> _filterData(customers){
    List<Customer> filteredOperators = [];
    if(string.isNullOrEmpty(state.searchNameField))
      filteredOperators = List.of(customers);
    else {
      customers.forEach((customer) {
        String searchedFields = customer.name + " " + customer.surname;
        if(searchedFields.toLowerCase().contains(state.searchNameField.toLowerCase())){
          filteredOperators.add(customer);
        }
      });
    }
    return filteredOperators;
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
    ReadyCustomers state = (this.state as ReadyCustomers);
    state.event.customer = state.customer;
  }

  bool validateAndSave() {
    if((state as ReadyCustomers).customer.id.isNotEmpty) {
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

  Event getEvent() => (state as ReadyCustomers).event;

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

}
