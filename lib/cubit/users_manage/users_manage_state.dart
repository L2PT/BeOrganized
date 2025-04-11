part of 'users_manage_cubit.dart';

enum _formStatus { normal, loading, success }

abstract class UsersManageState extends Equatable {

  Map<String, FilterWrapper> filters = {};
  final List<Account> accountList;
  final int selectedStatusTab;
  _formStatus status = _formStatus.normal;

  UsersManageState( [int? selectedStatus,List<Account>? accountList, Map<String, FilterWrapper>? filters, _formStatus? status,]):
        this.accountList = accountList ?? [],
        this.filters = filters ?? {},
        this.selectedStatusTab = selectedStatus ?? Account.getIntTypology(Account.ALL),
        this.status = status ?? _formStatus.normal;

  @override
  List<Object> get props => [selectedStatusTab, status, this.accountList.map((e) => e.toString()).join(),];

  ReadyUsersManage assign({
    Map<String, FilterWrapper>? filters,
    List<Account>? accountList,
    _formStatus? status,
    int? selectedStatus,
  }) => ReadyUsersManage(
    selectedStatus??this.selectedStatusTab,
    filters ?? this.filters,
    accountList ?? this.accountList,
    status??this.status,
  );
}

class LoadingUsersManage extends UsersManageState {}

class ReadyUsersManage extends UsersManageState {

  ReadyUsersManage( int selectedStatus, Map<String, FilterWrapper> filters, List<Account> customerList, _formStatus status,) : super(selectedStatus, customerList,filters, status);

}
