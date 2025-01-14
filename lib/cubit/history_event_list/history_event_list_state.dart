part of 'history_event_list_cubit.dart';

abstract class HistoryEventListState extends Equatable {
  Map<String, FilterWrapper> filters = {};
  final Map<int, List<Event>> eventsMap;
  final int selectedStatusTab;


  HistoryEventListState(int? selectedStatus, [Map<int, List<Event>>? eventsMap, Map<String, FilterWrapper>? filters]):
      this.selectedStatusTab = selectedStatus ?? EventStatus.Ended,
      this.eventsMap = eventsMap ?? {},
      this.filters = filters ?? {};

  @override
  List<Object> get props => [selectedStatusTab, eventsMap[selectedStatusTab]!=null?eventsMap[selectedStatusTab]!.map((e) => e).join():"",];

  HistoryReady assign({
    Map<String, FilterWrapper>? filters,
    Map<int, List<Event>>? eventsMap,
    int? selectedStatus,
  }) => HistoryReady(selectedStatus ?? this.selectedStatusTab, eventsMap ?? this.eventsMap, filters ?? this.filters);

}


class HistoryLoading extends HistoryEventListState{
  HistoryLoading(int? selectedStatus):super(selectedStatus);
}

class HistoryReady extends HistoryEventListState{

  List<Event> selectedEvents() => eventsMap[selectedStatusTab] ?? [];

  List<Event> events(int status) => (eventsMap[status] ?? []).toList() ;

  HistoryReady(int selectedStatus, Map<int, List<Event>> eventsMap, Map<String, FilterWrapper> filters) :
        super(selectedStatus,eventsMap,filters);

}
