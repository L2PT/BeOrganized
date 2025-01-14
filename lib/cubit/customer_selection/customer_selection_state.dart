part of 'customer_selection_cubit.dart';

abstract class CustomerSelectionState extends Equatable {
  String searchNameField = "";
  Map<String, FilterWrapper> filters = FilterWrapper.initFilterCustomer() ;
  List<Customer> filteredCustomers = [];
  late Event event;
  late Customer customer;
  bool canLoadMore = true;

  CustomerSelectionState([ List<Customer>? filteredCustomers, Event? event, Map<String, FilterWrapper>? filters, String? searchNameField, bool? canLoadMore]) {
    this.searchNameField = searchNameField ?? "";
    this.event = event ?? Event.empty();
    this.filteredCustomers = filteredCustomers ?? [];
    this.canLoadMore = canLoadMore ?? true;
    this.event.customer.name.isEmpty? this.customer = Customer.empty(): this.customer = this.event.customer;
    this.filters = filters??FilterWrapper.initFilterCustomer();
  }

  @override
  List<Object> get props => [searchNameField];

  ReadyCustomers assign(
      {List<Customer>? filteredCustomers,
        Event? event,Customer? customer,
        String? searchNameField,
        bool? canLoadMore,
        Map<String, FilterWrapper>? filters,}) {

    var form = ReadyCustomers.update(filteredCustomers?? this.filteredCustomers, event??this.event, filters??this.filters,
        searchNameField??this.searchNameField, canLoadMore??this.canLoadMore);
    form.customer = customer??this.customer;
    return form;
  }

}

class LoadingCustomers extends CustomerSelectionState {
  @override
  List<Object> get props => [];
}

class ReadyCustomers extends CustomerSelectionState {


  ReadyCustomers(): super();

  ReadyCustomers.update(List<Customer>? filteredCustomers, Event? event,Map<String, FilterWrapper>? filters,  String? searchNameField, bool? canLoadMore): super(filteredCustomers, event, filters,searchNameField, canLoadMore);

  @override
  List<Object> get props => [filteredCustomers.map((op) => op.id).join(), event.toString(), customer.toString(), canLoadMore];
}

