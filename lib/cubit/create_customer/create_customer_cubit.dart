import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'create_customer_state.dart';

class CreateCustomerCubit extends Cubit<CreateCustomerState> with CreateEntityUtils{
  final CloudFirestoreService _databaseRepository;
  final GlobalKey<FormState> formKeyBasiclyInfo = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyAddressInfo = GlobalKey<FormState>();
  final formFieldPhoneKey = GlobalKey<FormFieldState>();
  late Map<String,dynamic> types;
  DateTime? firstClick;

  CreateCustomerCubit(this._databaseRepository,Event? event, int currentStep, TypeStatus type)
      : super(CreateCustomerState(event)) {
    state.currentStep = currentStep;
    setType(type);
    types = _databaseRepository.typesCustomer;
  }

  void setFirstClick(DateTime date){
    firstClick = date;
  }

  Future<bool> saveCustomer() async {
    if(state.isLoading()) return Future<bool>(()=>false);
    else if(this.formKeyBasiclyInfo.currentState!.validate()) {
      //get all data before refresh
      formKeyAddressInfo.currentState!.save();
      emit(state.assign(status: _formStatus.loading));
      try {
        if(this.isNew() || this.isCopy()) {
          state.customer.id = await _databaseRepository.addCustomer(state.customer);
        } else {
          _databaseRepository.updateCustomer(state.customer.id, state.customer);
        }
        if(Constants.debug) print("Firebase save complete");
        return true;
      } catch (e) {
        emit(state.assign(status: _formStatus.normal));
        print(e);
        PlatformUtils.notifyErrorMessage("Errore nella creazione del cliente.");
      }
    }
    return false;
  }

  void getLocations(String text) async {
    if(text.length > 5 && text != state.customer.addresses){
      List<String> locations = [];
      if(PlatformUtils.isMobile){
        locations = await GeoUtils.getLocations(text);
      }else{
        locations = await GeoUtils.getLocationsWeb(text);
      }
      //emit(state.assign(locations: locations, address: text));
    }
  }

  void removePhoneOnCustomer(String phone){
    Customer customer = Customer.fromMap("", state.customer.toMap());
    customer.phones.removeWhere((element) => element == phone);
    emit(state.assign(customer: customer));
  }

  void addPhoneOnCustomer(){
    String value = formFieldPhoneKey.currentState?.value;
    if(formFieldPhoneKey.currentState!.validate() && value.isNotEmpty){
      Customer customer = Customer.fromMap("", state.customer.toMap());
      customer.phones.add(value);
      formFieldPhoneKey.currentState?.reset();
      emit(state.assign(customer: customer));
    }
  }

  void addAddressOnCustomer(BuildContext context){
    state.customer.address = Address.empty();
    state.event.customer = state.customer;
    PlatformUtils.navigator(context, Constants.createAddressViewRoute,
        <String, dynamic>{'objectParameter' : state.event, 'currentStep': state.currentStep, 'typeStatus' : TypeStatus.create, 'context' : context, 'callback': PlatformUtils.isMobile?forceRefresh:null});
  }

  /* STEPPER CONTROLLER */
  void onStepContinue(int numberStep){
    if(state.currentStep != numberStep-1){
      GlobalKey<FormState>? form = formKeyBasiclyInfo;
      if(state.currentStep > 0){
        if(form.currentState!.validate()){
          form.currentState!.save();
          emit(state.assign(currentStep: state.currentStep+1));
        }
      }else{
        emit(state.assign(currentStep: state.currentStep+1));
      }
    }
  }

  void onStepCancel(){
    if(state.currentStep != 0){
      formKeyBasiclyInfo.currentState?.reset();
      emit(state.assign(currentStep: state.currentStep-1));
    }
  }

  void onSelectedType(String key){
    state.customer.typology = key;
    emit(state.assign(typeSelected: key));
  }

  bool onClickModeAddress(){
    return state.customer.addresses.length > 1;
  }

  bool onSelectItemAddress(Address address){
    return state.customer.addresses.length > 1 && state.customer.address == address;
  }

  void removeAddressOnCustomer(Address address){
    Customer customer = Customer.fromMap("", state.customer.toMap());
    customer.addresses.removeWhere((element) => element == address);
    if(customer.address == address && customer.addresses.isNotEmpty){
      customer.address = customer.addresses.first;
    }else{
      customer.address = Address.empty();
    }
    emit(state.assign(customer: customer));
  }

  void selectAddressOnCustomer(Address address){
    Customer customer = Customer.fromMap("", state.customer.toMap());
    customer.address = address;
    emit(state.assign(customer: customer));
  }

  Event getEventCustomer() {
    Event event = Event.fromMap("", "", state.event.toMap());
    Customer customer = Customer.fromMap("", state.customer.toMap());
    event.customer = customer;
    return event;
  }
  Event getEvent() => this.state.event;

  void forceRefresh() {
    emit(state.assign(status: _formStatus.loading));
    emit(state.assign(status: _formStatus.normal));
  }
}
