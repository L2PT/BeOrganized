import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/repositories/agolia_service.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';

part 'customer_selection_state.dart';

class CustomerSelectionCubit extends Cubit<CustomerSelectionState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();
  late List<Customer> customers;
  final int startingElements = 30;
  final int loadingElements = 15;
  Map<String, ExpansibleController> mapController = {};
  String selectedTypology = Customer.ALL;

  CustomerSelectionCubit(this._databaseRepository, Event? _event) :
        super(LoadingCustomers()){
    getCustomers(_event ?? new Event.empty());
  }

  List<Customer> _applyTypologyFilter(List<Customer> listToFilter) {
    if (selectedTypology == Customer.ALL) return listToFilter;
    return listToFilter.where((c) => c.typology == selectedTypology).toList();
  }

  void onTypologyChanged(String typology) {
    selectedTypology = typology;
    if (state is ReadyCustomers) {
      var filtered = _applyTypologyFilter(customers);
      emit((state as ReadyCustomers).assign(
        filteredCustomers: filtered,
      ));
      if (filtered.length < startingElements && state.canLoadMore) {
        loadMoreData();
      }
    }
  }

  void getCustomers(Event event) async {
    customers = await _databaseRepository.getCustomers(state.filters, limit: startingElements);
    bool canLoadMore = customers.length >= startingElements;
    emit(state.assign(filteredCustomers: _applyTypologyFilter(customers), event: event, canLoadMore: canLoadMore));
  }

  bool _isLoadingMore = false;

  void loadMoreData() async {
    if (state is! ReadyCustomers || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      List<Customer> loaded;
      if(state.searchNameField.isNotEmpty){
        List<String> idCustomers = await AlgoliaService.searchCustomer(state.searchNameField, hitsPerPage: loadingElements, page: state.numPage);
        loaded = await _databaseRepository.getCustomersByIds(idCustomers);
      }else{
        // Always paginate from the last element of the FULL (unfiltered) list
        var lastId = customers.isNotEmpty ? customers.last.id : null;
        loaded = await _databaseRepository.getCustomers(state.filters, limit: loadingElements, startFrom: lastId);
      }
      // Deduplicate: only add customers not already in the list
      final existingIds = customers.map((c) => c.id).toSet();
      final newItems = loaded.where((c) => !existingIds.contains(c.id)).toList();
      customers.addAll(newItems);
      bool canLoadMore = loaded.length >= loadingElements;
      var filtered = _applyTypologyFilter(customers);
      if (state is ReadyCustomers) {
        emit((state as ReadyCustomers).assign(filteredCustomers: filtered, canLoadMore: canLoadMore));
        _isLoadingMore = false;
        if (filtered.length < startingElements && canLoadMore) {
          loadMoreData();
        }
      }
    } catch (e) {
      _isLoadingMore = false;
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
    List<Customer> loaded = [];
    if(searchquery.isNotEmpty){
      List<String> idCustomers = await AlgoliaService.searchCustomer(filters['searchQuery']!.fieldValue, hitsPerPage: startingElements, );
      if(idCustomers.isNotEmpty)
        loaded = await _databaseRepository.getCustomersByIds(idCustomers);
    }else{
      loaded = await _databaseRepository.getCustomers(state.filters, limit: startingElements);
    }
    bool canLoadMore = loaded.length >= startingElements;
    customers = loaded;
    emit(state.assign( filteredCustomers: _applyTypologyFilter(loaded), searchNameField: filters["searchQuery"]!.fieldValue, filters: filters,
        event: e, canLoadMore: canLoadMore, customer: customer));
  }

  void onExpansionChanged(bool isOpen, Customer customer){
    Customer customerCopy = Customer.fromMap("", customer.toMap());
    if(isOpen){
      ExpansibleController? controller = mapController[(state as ReadyCustomers).customer.id];
      if(controller != null && controller.isExpanded)
        controller.collapse();
      List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
      int idx = filteredCustomers.indexWhere((element) => element.id == customer.id);
      if (idx != -1) {
        filteredCustomers[idx] = customerCopy;
      }
      emit((state as ReadyCustomers).assign(customer: customerCopy, filteredCustomers: filteredCustomers));
    }else{
      if(customer.id == (state as ReadyCustomers).customer.id){
        state.event.customer = Customer.empty();
        emit((state as ReadyCustomers).assign(customer: Customer.empty()));
      }
    }
  }

  ExpansibleController getController(String id){
    ExpansibleController controller = new ExpansibleController();
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
    state.event.title = state.customer.nameCustomer();
  }

  bool validateAndSave(BuildContext context) {
    if(state.customer.id.isNotEmpty) {
      saveSelectionToEvent();
      return true;
    } else {
      SuccessAlert(
        context,
        title: "ERRORE",
        text: "Seleziona un cliente, cliccando su di esso",
        showAction: true,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red,
      ).show();
      return false;
    }
  }

  bool deleteCustomer(Customer customer){
    _databaseRepository.deleteCustomer(customer.id);
    List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
    int posOpe = filteredCustomers.indexOf(customer);
    ExpansibleController? controller = mapController[(state as ReadyCustomers).customer.id];
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
    int idx = filteredCustomers.indexWhere((element) => element.id == customer.id);
    if (idx != -1) {
      filteredCustomers[idx] = customer;
    }
    _databaseRepository.updateCustomer(customer.id, customer);
    emit((state as ReadyCustomers).assign(customer: customer, filteredCustomers: filteredCustomers));
  }

  void removeReferralOnCustomer(Referrals referral){
    Customer customer = Customer.fromMap("", (state as ReadyCustomers).customer.toMap());
    customer.referrals.removeWhere((element) => element == referral);
    if(customer.referral == referral && customer.referrals.isNotEmpty){
      customer.referral = customer.referrals.first;
    }else{
      customer.referral = Referrals.empty();
    }
    List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
    int idx = filteredCustomers.indexWhere((element) => element.id == customer.id);
    if (idx != -1) {
      filteredCustomers[idx] = customer;
    }
    _databaseRepository.updateCustomer(customer.id, customer);
    emit((state as ReadyCustomers).assign(customer: customer, filteredCustomers: filteredCustomers));
  }

  void selectAddressOnCustomer(Address address){
    Customer customer = Customer.fromMap("", (state as ReadyCustomers).customer.toMap());
    customer.address = address;
    List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
    int idx = filteredCustomers.indexWhere((element) => element.id == customer.id);
    if (idx != -1) {
      filteredCustomers[idx] = customer;
    }
    emit((state as ReadyCustomers).assign(customer: customer, filteredCustomers: filteredCustomers));
  }

  void selectReferralsOnCustomer(Referrals referral ){
    Customer customer = Customer.fromMap("", (state as ReadyCustomers).customer.toMap());
    if(customer.selectedReferrals.contains(referral)){
      if(customer.selectedReferrals.length > 1){
        customer.selectedReferrals.remove(referral);
      }
    } else {
      customer.selectedReferrals.add(referral);
    }
    customer.referral = customer.selectedReferrals.isNotEmpty ? customer.selectedReferrals.first : Referrals.empty();
    List<Customer> filteredCustomers = List.of((state as ReadyCustomers).filteredCustomers);
    int idx = filteredCustomers.indexWhere((element) => element.id == customer.id);
    if (idx != -1) {
      filteredCustomers[idx] = customer;
    }
    emit((state as ReadyCustomers).assign(customer: customer, filteredCustomers: filteredCustomers));
  }

  void forceRefresh() {
    if (!isClosed) {
      emit(state.assign(status: _formStatus.loading));
      emit(state.assign(status: _formStatus.normal));
    }
  }

}
