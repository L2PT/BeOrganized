import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'create_address_state.dart';

class CreateAddressCubit extends Cubit<CreateAddressState> with CreateEntityUtils{

  final CloudFirestoreService _databaseRepository;
  final GlobalKey<FormState> formKeyAddressInfo = GlobalKey<FormState>();
  late TextEditingController addressController;
  late Address addressToModify;

  CreateAddressCubit(this._databaseRepository,Event? event, TypeStatus type) : super(CreateAddressState(event)) {
    addressController = new TextEditingController();
    setType(type);
    addressController.text = state.customer.address.address;
      if(isModify()){
      addressToModify = state.customer.address;
    }
  }

  bool validateAndSave() {
    if(formKeyAddressInfo.currentState!.validate()) {
      formKeyAddressInfo.currentState!.save();
      if(isModify()) {
        state.customer.addresses.removeWhere((element) => element.address == addressToModify.address);
      }
      state.customer.addresses.add(state.customer.address);
      if(isModify() && state.customer.id.isNotEmpty){
        _databaseRepository.updateCustomer(state.customer.id, state.customer);
      }
      state.event.customer = state.customer;
      return true;
    } else {
      return false;
    }
  }

  void getLocations(String text) async {
    if(text.length > 5 && text != state.customer.address.address){
      List<String> locations = [];
      if(PlatformUtils.isMobile){
        locations = await GeoUtils.getLocations(text);
      }else{
        locations = await GeoUtils.getLocationsWeb(text);
      }
      emit(state.assign(locations: locations, address: text));
    }
  }

  setAddress(String address) {
    addressController.text = address;
    emit(state.assign(locations: <String>[], address: address));
  }

}
