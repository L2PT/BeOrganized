part of 'customer_selection_cubit.dart';

enum _formStatus { normal, loading, success }

abstract class CustomerSelectionState extends Equatable {
  String searchNameField = "";
  Map<String, FilterWrapper> filters = FilterWrapper.initFilterCustomer() ;
  List<Customer> filteredCustomers = [];
  late Event event;
  late Customer customer;
  bool canLoadMore = true;
  int numPage = 0;
  _formStatus status = _formStatus.normal;

  CustomerSelectionState([ List<Customer>? filteredCustomers, Event? event, Customer? customer, Map<String, FilterWrapper>? filters, String? searchNameField, bool? canLoadMore, int? numPage,  _formStatus? status]) {
    this.searchNameField = searchNameField ?? "";
    this.event = event ?? Event.empty();
    this.filteredCustomers = filteredCustomers ?? [];
    this.canLoadMore = canLoadMore ?? true;
    this.numPage = numPage ?? 0;
    this.customer = (customer == null || customer.name.isEmpty)? (this.event.customer.name.isEmpty? Customer.empty(): this.event.customer) : customer ;
    this.filters = filters??FilterWrapper.initFilterCustomer();
    this.status = status ?? _formStatus.normal;
  }

  @override
  List<Object> get props => [searchNameField, status];

  ReadyCustomers assign(
      {List<Customer>? filteredCustomers,
        Event? event,Customer? customer,
        String? searchNameField,
        bool? canLoadMore,
        int? numPage,
        _formStatus? status,
        Map<String, FilterWrapper>? filters,}) => ReadyCustomers.update(filteredCustomers?? this.filteredCustomers, event??this.event, customer??this.customer,filters??this.filters,
        searchNameField??this.searchNameField, canLoadMore??this.canLoadMore, numPage??this.numPage, status??this.status);


}

class LoadingCustomers extends CustomerSelectionState {
  @override
  List<Object> get props => [];
}

class ReadyCustomers extends CustomerSelectionState {


  ReadyCustomers(): super();

  ReadyCustomers.update(List<Customer>? filteredCustomers, Event? event,Customer? customer,Map<String, FilterWrapper>? filters,  String? searchNameField, bool? canLoadMore, int? numPage, _formStatus status,): super(filteredCustomers, event, customer, filters,searchNameField, canLoadMore, numPage, status);

  @override
  List<Object> get props => [filteredCustomers.map((op) => op.id).join(),status, event.toString(), customer.toString(), canLoadMore];
}

