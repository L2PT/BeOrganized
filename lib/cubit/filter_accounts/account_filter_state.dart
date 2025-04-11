part of 'account_filter_cubit.dart';

enum _filterStatus { normal, loading }

class AccountsFilterState extends Equatable {

  Map<String, FilterWrapper> filters = {};
  bool filtersBoxVisibile = false;
  _filterStatus status = _filterStatus.normal;

  AccountsFilterState() {
    filters = FilterWrapper.initFilterAccount();
  }

  @override
  List<Object> get props => [filters.values.join(), filtersBoxVisibile, status];

  bool isLoading() => this.status == _filterStatus.loading;

  AccountsFilterState.update(this.filters, this.filtersBoxVisibile, this.status);

  AccountsFilterState assign({
    Map<String, FilterWrapper>? filters,
    bool? filtersBoxVisibile,
    _filterStatus? status,
  }) => new AccountsFilterState.update(
      filters??this.filters,
      filtersBoxVisibile??this.filtersBoxVisibile,
      status??this.status,
  );

}
