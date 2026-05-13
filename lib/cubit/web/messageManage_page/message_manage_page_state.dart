part of 'message_manage_page_cubit.dart';

abstract class MessageManagePageState extends Equatable {

  final String qrcode;
  final bool sessionActive;
  final List<ChatOverview> chats;
  final List<ChatOverview> filteredChats;
  final List<Message> currentMessages;
  final ChatOverview? selectedChat;
  final String searchQuery;

  MessageManagePageState({
    this.qrcode = "",
    this.sessionActive = false,
    this.chats = const [],
    this.filteredChats = const [],
    this.currentMessages = const [],
    this.selectedChat,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
    qrcode,
    sessionActive,
    chats,
    filteredChats,
    currentMessages,
    selectedChat,
    searchQuery
  ];

  MessageManagePageState copyWith({
    String? qrcode,
    bool? sessionActive,
    List<ChatOverview>? chats,
    List<ChatOverview>? filteredChats,
    List<Message>? currentMessages,
    ChatOverview? selectedChat,
    String? searchQuery,
  });
}

class LoadingMessagesManage extends MessageManagePageState {

  LoadingMessagesManage({
    super.qrcode,
    super.sessionActive,
  });

  @override
  MessageManagePageState copyWith({
    String? qrcode,
    bool? sessionActive,
    List<ChatOverview>? chats,
    List<ChatOverview>? filteredChats,
    List<Message>? currentMessages,
    ChatOverview? selectedChat,
    String? searchQuery,
  }) {
    // Return self or new instance if needed, but usually loading is just loading
    return LoadingMessagesManage();
  }
}

class LoadedMessageManage extends MessageManagePageState {

  LoadedMessageManage({
    super.qrcode,
    super.sessionActive,
    super.chats,
    super.filteredChats,
    super.currentMessages,
    super.selectedChat,
    super.searchQuery,
  });

  @override
  MessageManagePageState copyWith({
    String? qrcode,
    bool? sessionActive,
    List<ChatOverview>? chats,
    List<ChatOverview>? filteredChats,
    List<Message>? currentMessages,
    ChatOverview? selectedChat,
    String? searchQuery,
  }) {
    return LoadedMessageManage(
      qrcode: qrcode ?? this.qrcode,
      sessionActive: sessionActive ?? this.sessionActive,
      chats: chats ?? this.chats,
      filteredChats: filteredChats ?? this.filteredChats,
      currentMessages: currentMessages ?? this.currentMessages,
      selectedChat: selectedChat ?? this.selectedChat,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}