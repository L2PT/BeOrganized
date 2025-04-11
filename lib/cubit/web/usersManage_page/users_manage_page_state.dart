part of 'users_manage_page_cubit.dart';

class UsersManagePageState extends CommonPageState {

  final List<Account> accountList;
  int totalEvent;

  UsersManagePageState([int? selectedStatus,int? numPage,int? totalEvent, List<Account>? accountList, Map<String, FilterWrapper>? filters, Map<int, int>? countAccountTypology,  Map<String, bool>? mapSelected, bool? refresh]):
        this.accountList = accountList ?? [],
        this.totalEvent = totalEvent??0,
        super(numPage: numPage??0, filters: filters, mapSelected: mapSelected,
          selectedStatusTab: selectedStatus ?? Account.getIntTypology(Account.ALL), countEntity: countAccountTypology, refresh:  refresh);

  @override
  List<Object> get props => [selectedStatusTab, numPage, accountList, refresh,
    countEntity.keys.join(), countEntity.values.join(), mapSelected.keys.join(), mapSelected.values.join()];

  ReadyUsersManagePageState assign({
    Map<String, FilterWrapper>? filters,
    Map<int, int>? countAccountTypology,
    Map<String, bool>? mapSelected,
    List<Account>? accountList,
    int? selectedStatus,
    int? numPage,
    int? totalEvent,
    bool? refresh
  }) => ReadyUsersManagePageState.update(
    selectedStatus??this.selectedStatusTab,
    numPage??this.numPage,
    filters ?? this.filters,
    totalEvent ?? this.totalEvent,
    List<Account>.from(accountList ?? this.accountList),
    countAccountTypology ?? this.countEntity,
    mapSelected ?? this.mapSelected,
    refresh ?? this.refresh,
  );
}

class LoadingUsersManagePageState extends UsersManagePageState {}

class ReadyUsersManagePageState extends UsersManagePageState {

  ReadyUsersManagePageState(): super();

  ReadyUsersManagePageState.update( int selectedStatus, int numPage, Map<String, FilterWrapper> filters, int totalEvent, List<Account> accountList, Map<int, int> countCustomerTypology,  Map<String, bool> mapSelected, bool refresh) : super(selectedStatus, numPage, totalEvent, accountList,filters, countCustomerTypology, mapSelected, refresh);

}