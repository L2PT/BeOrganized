part of 'create_address_cubit.dart';

class CreateAddressState extends Equatable {

  @override
  List<Object?> get props => [locations.join(),customer.toString(), version];

  CreateAddressState(Event? event, {this.version = 0}){
    this.locations = List<String>.empty();
    event == null? this.event = Event.empty(): this.event = event;
    this.customer = this.event.customer;
  }

  late List<String> locations;
  late Customer customer;
  late final Event event;
  final int version;

  CreateAddressState assign({
    Event? event,
    Customer? customer,
    String? address,
    String? phone,
    List<String>? locations,
  }) {
    var form = CreateAddressState(event??this.event, version: this.version + 1);
    form.customer = customer??this.customer;
    form.locations = locations??this.locations;
    if(!string.isNullOrEmpty(address)) form.customer.address.address.add(address!);
    if(!string.isNullOrEmpty(phone)) form.customer.address.phone = phone!;
    return form;
  }
}
