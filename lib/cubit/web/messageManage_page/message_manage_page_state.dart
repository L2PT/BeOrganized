part of 'message_manage_page_cubit.dart';

abstract class MessageManagePageState extends Equatable {

  final String qrcode;
  final bool sessionActive;
  final List<ChatOverview> chats;
  final List<ChatOverview> filteredChats;
  final List<Message> currentMessages;
  final ChatOverview? selectedChat;
  final String searchQuery;
  final bool onlyUnread;

  MessageManagePageState({
    this.qrcode = "",
    this.sessionActive = false,
    this.chats = const [],
    this.filteredChats = const [],
    this.currentMessages = const [],
    this.selectedChat,
    this.searchQuery = '',
    this.onlyUnread = false,
  });

  @override
  List<Object?> get props => [
    qrcode,
    sessionActive,
    chats,
    filteredChats,
    currentMessages,
    selectedChat,
    searchQuery,
    onlyUnread
  ];

  MessageManagePageState copyWith({
    String? qrcode,
    bool? sessionActive,
    List<ChatOverview>? chats,
    List<ChatOverview>? filteredChats,
    List<Message>? currentMessages,
    ChatOverview? selectedChat,
    String? searchQuery,
    bool? onlyUnread,
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
    bool? onlyUnread,
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
    super.onlyUnread = false,
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
    bool? onlyUnread,
  }) {
    return LoadedMessageManage(
      qrcode: qrcode ?? this.qrcode,
      sessionActive: sessionActive ?? this.sessionActive,
      chats: chats ?? this.chats,
      filteredChats: filteredChats ?? this.filteredChats,
      currentMessages: currentMessages ?? this.currentMessages,
      selectedChat: selectedChat ?? this.selectedChat,
      searchQuery: searchQuery ?? this.searchQuery,
      onlyUnread: onlyUnread ?? this.onlyUnread,
    );
  }
}