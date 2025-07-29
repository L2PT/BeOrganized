import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_response_ai.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/agolia_service.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'generate_ai_event_state.dart';

class GenerateAiEventCubit extends Cubit<GenerateAiEventState> {
  final CloudFirestoreService _databaseRepository;
  final Account _account;
  late String text = Constants.protoGenerateEvent;
  final GlobalKey<FormState> formKeyBasiclyInfo = GlobalKey<FormState>();

  GenerateAiEventCubit(this._databaseRepository, this._account, DateTime? dateSelect,) :
        super(GenerateAiEventState(dateSelect: dateSelect));



  Future<bool> generateEvent() async {
    if(state.isLoading()) return Future<bool>(()=>false);
    if(formKeyBasiclyInfo.currentState!.validate()){
      formKeyBasiclyInfo.currentState!.save();
      emit(state.assign(status: _formStatus.loading));
      state.event.supervisor = _account;
      text = _removePlaceholdersClean(text);
      EventResponseAi eventResponseAi = await AiUtils.estraiIncarico(text);
      eventResponseAi.color = _databaseRepository.getColorByCategory(eventResponseAi.categoria);
      eventResponseAi.indirizzo = await getLocations(eventResponseAi.indirizzo);
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

  Future<String> getLocations(String text) async {
    List<String> locations = [];
    if (PlatformUtils.isMobile) {
      locations = await GeoUtils.getLocations(text);
    } else {
      locations = await GeoUtils.getLocationsWeb(text);
    }
    return locations.isEmpty ? text : locations.first;
  }

  /// Rimuove tutti i placeholder dal testo e pulisce le righe vuote
  String _removePlaceholdersClean(String text) {
    String result = text;

    // Ordina i placeholder per lunghezza decrescente per evitare sostituzioni parziali
    List<String> sortedPlaceholders = List.from(Constants.placeholders);
    sortedPlaceholders.sort((a, b) => b.length.compareTo(a.length));

    // Rimuove ogni placeholder dalla lista
    for (String placeholder in sortedPlaceholders) {
      result = result.replaceAll(placeholder, '');
    }

    // Rimuove righe vuote o che contengono solo spazi/punteggiatura
    List<String> lines = result.split('\n');
    lines = lines.where((line) {
      String trimmed = line.trim();

      // Se la riga è vuota, rimuovila
      if (trimmed.isEmpty) return false;

      // Se la riga contiene i due punti, controlla se ha contenuto dopo
      if (trimmed.contains(':')) {
        String afterColon = trimmed.split(':').skip(1).join(':').trim();
        // Rimuove la riga se dopo i due punti non c'è nulla o solo punteggiatura/spazi
        if (afterColon.isEmpty || RegExp(r'^[,\s()-]*$').hasMatch(afterColon)) {
          return false;
        }
      }

      // Mantiene la riga se contiene lettere o numeri significativi
      return RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed);
    }).toList();

    return lines.join('\n');
  }
}
