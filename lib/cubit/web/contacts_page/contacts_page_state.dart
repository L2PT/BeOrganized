part of 'contacts_page_cubit.dart';

class ContactsPageState extends CommonPageState {

  final List<Customer> customerList;
  int totalEvent;

  ContactsPageState([int? selectedStatus,int? numPage,int? totalEvent, List<Customer>? customerList, Map<String, FilterWrapper>? filters, Map<int, int>? countCustomerTypology,  Map<String, bool>? mapSelected, bool? refresh]):
    this.customerList = customerList ?? [],
    this.totalEvent = totalEvent??0,
    super(numPage: numPage??0, filters: filters, mapSelected: mapSelected,
          selectedStatusTab: selectedStatus ?? Customer.getIntTypology(Customer.ALL), countEntity: countCustomerTypology, refresh:  refresh);

  @override
  List<Object> get props => [selectedStatusTab, numPage, customerList, refresh,
    countEntity.keys.join(), countEntity.values.join(), mapSelected.keys.join(), mapSelected.values.join()];

  ReadyContactsPageState assign({
    Map<String, FilterWrapper>? filters,
    Map<int, int>? countCustomerTypology,
    Map<String, bool>? mapSelected,
    List<Customer>? customerList,
    int? selectedStatus,
    int? numPage,
    int? totalEvent,
    bool? refresh
  }) => ReadyContactsPageState.update(
      selectedStatus??this.selectedStatusTab,
      numPage??this.numPage,
      filters ?? this.filters,
      totalEvent ?? this.totalEvent,
      List<Customer>.from(customerList ?? this.customerList),
      countCustomerTypology ?? this.countEntity,
      mapSelected ?? this.mapSelected,
      refresh ?? this.refresh,
  );
}

class LoadingContactsPageState extends ContactsPageState {}

class ReadyContactsPageState extends ContactsPageState {

  ReadyContactsPageState(): super();

  ReadyContactsPageState.update( int selectedStatus, int numPage, Map<String, FilterWrapper> filters, int totalEvent, List<Customer> customerList, Map<int, int> countCustomerTypology,  Map<String, bool> mapSelected, bool refresh) : super(selectedStatus, numPage, totalEvent, customerList,filters, countCustomerTypology, mapSelected, refresh);

}