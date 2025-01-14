part of 'customer_filter_cubit.dart';

enum _filterStatus { normal, loading }

class CustomersFilterState extends Equatable {

  Map<String, FilterWrapper> filters = {};
  bool filtersBoxVisibile = false;
  _filterStatus status = _filterStatus.normal;

  CustomersFilterState() {
    filters = FilterWrapper.initFilterCustomer();
  }

  @override
  List<Object> get props => [filters.values.join(), filtersBoxVisibile, status];

  bool isLoading() => this.status == _filterStatus.loading;

  CustomersFilterState.update(this.filters, this.filtersBoxVisibile, this.status);

  CustomersFilterState assign({
    Map<String, FilterWrapper>? filters,
    bool? filtersBoxVisibile,
    _filterStatus? status,
    bool? isCompany,
    bool? isPrivate,
  }) => new CustomersFilterState.update(
      filters??this.filters,
      filtersBoxVisibile??this.filtersBoxVisibile,
      status??this.status,
  );

}
