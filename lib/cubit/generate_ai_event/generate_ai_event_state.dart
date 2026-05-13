part of 'generate_ai_event_cubit.dart';

enum _formStatus { normal, loading, success }

class GenerateAiEventState extends Equatable {

  late Event event;
  _formStatus status = _formStatus.normal;

  GenerateAiEventState({ DateTime? dateSelect }){
    this.event = Event.empty();
    event.start = TimeUtils.getDefaultEventStartTime(dateSelect: dateSelect);
    event.end = event.start.add(Duration(minutes: Constants.WORKTIME_SPAN));
    event.recurrenceDayOfMonth = (dateSelect??_.DateUtils.now()).day;
  }

  bool isLoading() => this.status == _formStatus.loading;

  @override
  List<Object> get props => [status];

  GenerateAiEventState assign({
    _formStatus? status,
    Event? event,
  }) {
    var form = GenerateAiEventState(dateSelect: this.event.start);
    form.status = status??this.status;
    form.event = event??this.event;
    return form;
  }
}
