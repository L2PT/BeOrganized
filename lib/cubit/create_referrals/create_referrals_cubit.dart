import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';

part 'create_referrals_state.dart';

class CreateReferralsCubit extends Cubit<CreateReferralsState> with CreateEntityUtils{

  final CloudFirestoreService _databaseRepository;
  final GlobalKey<FormState> formKeyReferralsInfo = GlobalKey<FormState>();
  late Referrals referralToModify;

  CreateReferralsCubit(this._databaseRepository,Event? event, TypeStatus type) : super(CreateReferralsState(event)) {
    setType(type);
    if(isModify()){
      referralToModify = Referrals.fromMap(state.customer.referral.toMap());
    }
  }

  bool validateAndSave() {
    if(formKeyReferralsInfo.currentState!.validate()) {
      formKeyReferralsInfo.currentState!.save();
      if(isModify()) {
        state.customer.referrals.removeWhere((element) => element == referralToModify);
      }
      state.customer.referrals.add(state.customer.referral);
      if(isModify() && state.customer.id.isNotEmpty){
        _databaseRepository.updateCustomer(state.customer.id, state.customer);
      }
      state.event.customer = state.customer;
      return true;
    } else {
      return false;
    }
  }

}
