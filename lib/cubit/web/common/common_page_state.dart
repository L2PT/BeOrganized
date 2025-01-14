import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';

abstract class CommonPageState extends Equatable {

  final int _numPage;
  final int _selectedStatusTab;
  Map<String, bool> _mapSelected;
  Map<String, FilterWrapper> _filters;
  Map<int, int> _countEventsArchives;
  bool _refresh;

  CommonPageState({
    int numPage = 0,
    int selectedStatusTab = 0,
    Map<String, bool>? mapSelected,
    Map<String, FilterWrapper>? filters,
    Map<int, int>? countEntity,
    bool? refresh,
  })  : _numPage = numPage,
        _selectedStatusTab = selectedStatusTab,
        _mapSelected = mapSelected ?? {},
        _filters = filters ?? {},
        _refresh = refresh ?? false,
        _countEventsArchives = countEntity??{};

  int get numPage => _numPage;
  int get selectedStatusTab => _selectedStatusTab;
  Map<String, bool> get mapSelected => _mapSelected;
  bool get refresh => _refresh;
  void set refresh(bool refresh) => _refresh = refresh;
  Map<String, FilterWrapper> get filters => _filters;
  void set filters(Map<String, FilterWrapper> filter) => _filters = filter;
  Map<int, int> get countEntity => _countEventsArchives;
  @override
  List<Object> get props => [_numPage, _selectedStatusTab, _mapSelected, _filters, countEntity.keys.join(), countEntity.values.join(), _refresh];
}