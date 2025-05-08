part of 'create_user_cubit.dart';

enum _formStatus { normal, loading, success }

class CreateUserState extends Equatable {

  CreateUserState(Event? event){
    event == null? this.event = Event.empty(): this.event = event;
    this.event.operator.name.isEmpty? this.user = Account.empty(): this.user = this.event.operator;
  }
  late Account user;
  late final Event event;
  int currentStep = 0;
  String typeSelected = 'Operatore';
  _formStatus status = _formStatus.normal;

  @override
  List<Object> get props => [user.toString(), event.toString(), status, currentStep, typeSelected];

  bool isLoading() => this.status == _formStatus.loading;

  CreateUserState assign({
    Account? user,
    List<String>? locations,
    Event? event,
    _formStatus? status,
    int? currentStep,
    String? typeSelected,
  }) {
    var form = CreateUserState(event??this.event);
    form.user = user??this.user;
    form.status = status??this.status;
    form.currentStep = currentStep ?? this.currentStep;
    form.typeSelected = typeSelected ?? this.typeSelected;
    return form;
  }


}

