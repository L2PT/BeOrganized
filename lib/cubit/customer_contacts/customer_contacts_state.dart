part of 'customer_contacts_cubit.dart';

enum _formStatus { normal, loading, success }

abstract class CustomerContactsState extends Equatable {
  Map<String, FilterWrapper> filters = {};
  final List<Customer> customerList;
  final int selectedStatusTab;
  _formStatus status = _formStatus.normal;

  CustomerContactsState( [int? selectedStatus,List<Customer>? customerList, Map<String, FilterWrapper>? filters, _formStatus? status,]):
        this.customerList = customerList ?? [],
        this.filters = filters ?? {},
        this.selectedStatusTab = selectedStatus ?? Customer.getIntTypology(Customer.ALL),
        this.status = status ?? _formStatus.normal;

  @override
  List<Object> get props => [selectedStatusTab, status, this.customerList.map((e) => e.toString()).join(),];

  ReadyCustomerContacts assign({
    Map<String, FilterWrapper>? filters,
    List<Customer>? customerList,
    _formStatus? status,
    int? selectedStatus,
  }) => ReadyCustomerContacts(
      selectedStatus??this.selectedStatusTab,
      filters ?? this.filters,
      customerList ?? this.customerList,
      status??this.status,
  );
}

class LoadingCustomerContacts extends CustomerContactsState {}

class ReadyCustomerContacts extends CustomerContactsState {

  ReadyCustomerContacts( int selectedStatus, Map<String, FilterWrapper> filters, List<Customer> customerList, _formStatus status,) : super(selectedStatus, customerList,filters, status);

}

