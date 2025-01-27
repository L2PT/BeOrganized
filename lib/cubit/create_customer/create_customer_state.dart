part of 'create_customer_cubit.dart';

enum _formStatus { normal, loading, success }

class CreateCustomerState extends Equatable {

  CreateCustomerState(Event? event){
    event == null? this.event = Event.empty(): this.event = event;
    this.event.customer.name.isEmpty? this.customer = Customer.empty(): this.customer = this.event.customer;
  }
  late Customer customer;
  late final Event event;
  int currentStep = 0;
  String typeSelected = 'Privato';
  _formStatus status = _formStatus.normal;

  @override
  List<Object> get props => [customer.toString(), event.toString(), status, currentStep, typeSelected];

  bool isLoading() => this.status == _formStatus.loading;

  CreateCustomerState assign({
    Customer? customer,
    List<String>? locations,
    Event? event,
    Address? address,
    _formStatus? status,
    int? currentStep,
    String? typeSelected,
  }) {
    var form = CreateCustomerState(event??this.event);
    form.customer = customer??this.customer;
    form.status = status??this.status;
    form.currentStep = currentStep ?? this.currentStep;
    form.typeSelected = typeSelected ?? this.typeSelected;
    return form;
  }


}
