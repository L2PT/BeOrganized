part of 'create_referrals_cubit.dart';

class CreateReferralsState extends Equatable {

  @override
  List<Object?> get props => [customer.toString()];

  CreateReferralsState(Event? event){
    event == null? this.event = Event.empty(): this.event = event;
    this.event.customer.name.isEmpty? this.customer = Customer.empty(): this.customer = this.event.customer;
  }

  late Customer customer;
  late final Event event;

  CreateReferralsState assign({
    Event? event,
    Customer? customer,
    List<String>? locations,
  }) {
    var form = CreateReferralsState(event??this.event);
    form.customer = customer??this.customer;
    return form;
  }
}
