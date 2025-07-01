import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_response_ai.dart';
import 'package:venturiautospurghi/repositories/agolia_service.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'generate_ai_event_state.dart';

class GenerateAiEventCubit extends Cubit<GenerateAiEventState> {
  final CloudFirestoreService _databaseRepository;
  final Account _account;
  late String text = "";
  final GlobalKey<FormState> formKeyBasiclyInfo = GlobalKey<FormState>();

  GenerateAiEventCubit(this._databaseRepository, this._account, DateTime? dateSelect,) :
        super(GenerateAiEventState(dateSelect: dateSelect));



  Future<bool> generateEvent() async {
    if(state.isLoading()) return Future<bool>(()=>false);
    if(formKeyBasiclyInfo.currentState!.validate()){
      formKeyBasiclyInfo.currentState!.save();
      emit(state.assign(status: _formStatus.loading));
      state.event.supervisor = _account;
      EventResponseAi eventResponseAi = await AiUtils.estraiIncarico(text);
      eventResponseAi.color = _databaseRepository.getColorByCategory(eventResponseAi.categoria);
      state.event.fromGenerateData(eventResponseAi);
      List<String> idCustomers = await AlgoliaService.searchCustomer(eventResponseAi.indirizzo, hitsPerPage: 1);
      List<String> idUsers = await AlgoliaService.searchUser(eventResponseAi.operatore, hitsPerPage: 1);
      if(idCustomers.isNotEmpty) {
        Customer cliente = await _databaseRepository.getCustomer(idCustomers.first)??Customer.empty();
        state.event.customer = cliente;
      } else{
        state.event.customer = Customer.fromGenerateData(eventResponseAi);
      }
      if(idUsers.isNotEmpty){
        Account user = await _databaseRepository.getAccount(id: idUsers.first);
        state.event.operator = user;
      }
      return true;
    }
    return false;
  }
}
