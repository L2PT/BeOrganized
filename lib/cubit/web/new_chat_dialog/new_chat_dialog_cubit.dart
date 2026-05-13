import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:venturiautospurghi/models/message/contact_whatsapp.dart';
import 'package:venturiautospurghi/repositories/agolia_service.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

import 'new_chat_dialog_state.dart';

class NewChatDialogCubit extends Cubit<NewChatDialogState> {
  final CloudFirestoreService databaseRepository;
  DateTime? firstClick;

  NewChatDialogCubit(this.databaseRepository) : super(NewChatDialogLoading()) {
    _checkConnection();
  }

  void setFirstClick(DateTime date){
    firstClick = date;
  }

  int getCurrentStep(){
    if(state is NewChatDialogData) return (state as NewChatDialogData).currentStep;
    return 0;
  }

  void _checkConnection() async {
    try {
      var config = await databaseRepository.subscribeMessageConfig().first;
      if (config.sessionActive == true) {
        List<ContactWhatsapp> initialContacts = await databaseRepository.getContactWhatsapp({}, limit: 20);
        emit(NewChatDialogData(currentStep: 0, searchResults: initialContacts));
      } else {
        emit(NewChatDialogDisconnected());
      }
    } catch (e) {
      emit(NewChatDialogDisconnected());
    }
  }

  void searchContacts(String query) async {
    if (state is! NewChatDialogData) return;
    var currentState = state as NewChatDialogData;
    
    if (query.isEmpty) {
      List<ContactWhatsapp> initialContacts = await databaseRepository.getContactWhatsapp({}, limit: 20);
      emit(currentState.copyWith(searchResults: initialContacts));
      return;
    }

    try {
      List<String> contactsChatIds = await AlgoliaService.searchContactsChat(query);
      if (contactsChatIds.isEmpty) {
        emit(currentState.copyWith(searchResults: []));
        return;
      }

      List<ContactWhatsapp> customers = await databaseRepository.getContactWhatsappByIds(contactsChatIds);
      emit(currentState.copyWith(searchResults: customers, hasReachedMax: true, currentQuery: query));
    } catch (e) {
      emit(currentState.copyWith(searchResults: []));
    }
  }

  void loadMoreContacts() async {
    if (state is! NewChatDialogData) return;
    var currentState = state as NewChatDialogData;

    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    // Algolia search non gestisce il loadMore attualmente, solo firebase
    if (currentState.currentQuery.isNotEmpty) return;

    try {
      if (currentState.searchResults.isEmpty) return;

      emit(currentState.copyWith(isLoadingMore: true));
      String lastId = (currentState.searchResults.last as ContactWhatsapp).id;
      List<ContactWhatsapp> moreContacts = await databaseRepository.getContactWhatsapp({}, limit: 20, startFrom: lastId);

      bool hasReachedMax = moreContacts.isEmpty || moreContacts.length < 20;

      emit(currentState.copyWith(
        searchResults: [...currentState.searchResults, ...moreContacts],
        hasReachedMax: hasReachedMax,
        isLoadingMore: false
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void selectContact(ContactWhatsapp contact) {
    if (state is NewChatDialogData) {
      emit((state as NewChatDialogData).copyWith(currentStep: 1, selectedContact: contact));
    }
  }

  void backToSearch() {
    if (state is NewChatDialogData) {
      emit((state as NewChatDialogData).copyWith(currentStep: 0));
    }
  }

  void updateMessage(String text) {
    if (state is NewChatDialogData) {
      emit((state as NewChatDialogData).copyWith(messageText: text));
    }
  }

  Future<bool> sendMessage() async {
    if (state is NewChatDialogData) {
      var st = state as NewChatDialogData;
      if (st.selectedContact == null) return false;
      
      String text = st.messageText;
      ContactWhatsapp contactWhatsapp = st.selectedContact!;

      if (text.isNotEmpty && contactWhatsapp.phoneNumber.isNotEmpty) {
        String phoneStr = contactWhatsapp.phoneNumber.trim().replaceAll(' ', '').replaceAll('+', '');
        if (!phoneStr.startsWith('39') && phoneStr.length <= 10) {
          phoneStr = '39$phoneStr';
        }

        try {
          final url = Uri.parse('${Constants.whatsappBaseUrl}/send-message');
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': Constants.whatsappApiKey,
            },
            body: jsonEncode({
              'phone': phoneStr,
              'message': text,
            }),
          );

          if (response.statusCode == 200) {
            return true;
          } else {
            debugPrint("Failed to send message via API: ${response.body}");
          }
        } catch (e) {
          debugPrint("Error sending message via API: $e");
        }
      }
    }
    return false;
  }
}
