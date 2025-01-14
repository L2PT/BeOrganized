part of 'customer_contacts_cubit.dart';

abstract class CustomerContactsState extends Equatable {
  Map<String, FilterWrapper> filters = {};
  final List<Customer> customerList;
  final int selectedStatusTab;

  CustomerContactsState( [int? selectedStatus,List<Customer>? customerList, Map<String, FilterWrapper>? filters]):
        this.customerList = customerList ?? [],
        this.filters = filters ?? {},
        this.selectedStatusTab = selectedStatus ?? Customer.getIntTypology(Customer.ALL);

  @override
  List<Object> get props => [selectedStatusTab, this.customerList.map((e) => e.toString()).join(),];

  ReadyCustomerContacts assign({
    Map<String, FilterWrapper>? filters,
    List<Customer>? customerList,
    int? selectedStatus,
  }) => ReadyCustomerContacts(
      selectedStatus??this.selectedStatusTab,
      filters ?? this.filters,
      customerList ?? this.customerList
  );
}

class LoadingCustomerContacts extends CustomerContactsState {}

class ReadyCustomerContacts extends CustomerContactsState {

  ReadyCustomerContacts( int selectedStatus, Map<String, FilterWrapper> filters, List<Customer> customerList) : super(selectedStatus, customerList,filters, );

}

