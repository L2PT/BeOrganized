part of 'filter_operators_cubit.dart';

enum _filterStatus { normal, loading }

class OperatorsFilterState extends Equatable {

  Map<String, FilterWrapper> filters = {};
  bool filtersBoxVisibile = false;
  _filterStatus status = _filterStatus.normal;

  OperatorsFilterState(){
    // maybe we can put the dbconstants strings
    filters["name"] = new FilterWrapper("name", null, null );
    filters["date"] = new FilterWrapper("date", null, null );
  }

  bool isLoading() => this.status == _filterStatus.loading;

  @override
  List<Object> get props => [filters.values.join(), filtersBoxVisibile];

  OperatorsFilterState.update(this.filters, this.filtersBoxVisibile);

  OperatorsFilterState assign({
    Map<String, FilterWrapper>? filters,
    bool? filtersBoxVisibile,
  }) => OperatorsFilterState.update(
      filters??this.filters,
      filtersBoxVisibile??this.filtersBoxVisibile);

}