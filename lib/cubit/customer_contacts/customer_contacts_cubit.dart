import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';

part 'customer_contacts_state.dart';

class CustomerContactsCubit extends Cubit<CustomerContactsState> {
  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();

  List<Customer> listCustomer = [];
  final int startingElements = 25;
  final int loadingElements = 10;
  bool canLoadMore = true;

  CustomerContactsCubit(this._databaseRepository, Map<String, dynamic> filters,
      ): super(LoadingCustomerContacts()) {
      onFiltersChanged(state.filters);
  }

  void loadMoreData() async {
    listCustomer = List.from(state.customerList);
    listCustomer.addAll(await _databaseRepository.getCustomersActiveFiltered(state.filters, limit: loadingElements, startFrom: state.customerList.last.surname));
    canLoadMore = listCustomer.length == state.customerList.length+loadingElements;
    emit(state.assign(customerList: listCustomer));
  }

  Future<List<Customer>> onFiltersChanged(Map<String, FilterWrapper> filters, [int? status]) async {
    // Instead of do a basic repo get and evaluateEventsMap() the whole filtering process is handled directly in the query
    listCustomer = await _databaseRepository.getCustomersActiveFiltered(filters, limit: startingElements);
    canLoadMore = listCustomer.length == startingElements;
    scrollToTheTop();
    emit(state.assign(selectedStatus: status, filters: filters, customerList: listCustomer));
    return listCustomer;
  }


  void scrollToTheTop(){
    if(scrollController.hasClients)
      scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 100),
      );
  }

  Event getEventCustomer(Customer customer) {
    Event event = Event.empty();
    event.customer = customer;
    return event;
  }
}
