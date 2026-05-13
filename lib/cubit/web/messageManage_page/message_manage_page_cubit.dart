import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/message/chat_overview.dart';
import 'package:venturiautospurghi/models/message/message.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

part 'message_manage_page_state.dart';

class MessageManagePageCubit extends Cubit<MessageManagePageState> {

  final CloudFirestoreService _databaseRepository;
  final ScrollController scrollController = new ScrollController();

  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  MessageManagePageCubit(this._databaseRepository): super(LoadingMessagesManage());

  void initCubit() {
    _databaseRepository.subscribeMessageConfig().listen((config) {
      if(!config.sessionActive) {
        emit(LoadingMessagesManage(
          qrcode: config.qrCode,
          sessionActive: config.sessionActive,
        ));
      }else{
        if(state is LoadingMessagesManage) {
          emit(LoadedMessageManage(
            qrcode: config.qrCode,
            sessionActive: config.sessionActive,
          ));
          _subscribeChats();
        } else {
          emit(state.copyWith(qrcode: config.qrCode, sessionActive: config.sessionActive));
        }
      }
    });
  }

  void _subscribeChats() {
    _chatsSubscription?.cancel();
    _chatsSubscription = _databaseRepository.subscribeChats().listen((chats) {
      _filterChats(chats, state.searchQuery);
    });
  }

  void selectChat(ChatOverview chat) {
    _messagesSubscription?.cancel();
    emit(state.copyWith(selectedChat: chat, currentMessages: []));

    // Mark as read
    if(chat.unreadCount > 0) {
      _databaseRepository.markChatAsRead(chat.id);
    }

    _messagesSubscription = _databaseRepository.subscribeMessages(chat.id).listen((messages) {
      emit(state.copyWith(currentMessages: messages));
    });
  }

  Future<void> sendMessage(String text) async {
    if (state.selectedChat != null && text.trim().isNotEmpty) {
      final chatId = state.selectedChat!.id;
      
      // We'll call API first, then log if error, but also save to Firestore for local consistency if needed.
      // The API expects 'phone'. User confirmed chat ID format is 'number@c.us', which is standard for WhatsApp APIs.
      
      try {
        final url = Uri.parse('${Constants.whatsappBaseUrl}/send-message');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': Constants.whatsappApiKey,
          },
          body: jsonEncode({
            'phone': chatId, // Sends 'number@c.us'
            'message': text,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint("Message sent via API successfully");
        } else {
          debugPrint("Failed to send message via API: ${response.body}");
        }
      } catch (e) {
        debugPrint("Error sending message via API: $e");
      }
    }
  }

  void updateSearchQuery(String query) {
    _filterChats(state.chats, query);
  }

  void goToEventDetails(BuildContext context, String eventId) async {
    Event? e = await _databaseRepository.getEvent(eventId);
    if (e != null) {
      PlatformUtils.navigator(context, Constants.detailsEventViewRoute, <String, dynamic>{"objectParameter": e});
    }
  }

  void _filterChats(List<ChatOverview> allChats, String query) {
    var filtered = allChats;

    if (query.isNotEmpty) {
      filtered = filtered.where((chat) =>
      chat.name.toLowerCase().contains(query.toLowerCase()) ||
          chat.id.contains(query)
      ).toList();
    }

    emit(state.copyWith(
        chats: allChats,
        filteredChats: filtered,
        searchQuery: query,
    ));
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    scrollController.dispose();
    return super.close();
  }
}
