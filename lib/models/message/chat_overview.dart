import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;

class ChatOverview extends Equatable {
  final String id;
  final String name;
  final String? phoneNumber;
  final String realPhoneNumber;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isGroup;

  ChatOverview({
    this.id = '',
    this.name = '',
    this.phoneNumber,
    this.realPhoneNumber = '',
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isGroup = false,
  });

  factory ChatOverview.fromMap(String id, Map<String, dynamic> json) {
    return ChatOverview(
      id: id,
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'],
      realPhoneNumber: json['realPhoneNumber'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json["lastMessageTime"] is DateTime?json["lastMessageTime"]:_.DateUtils.firestoreToItalianTime(json["lastMessageTime"]),
      unreadCount: json['unreadCount'] ?? 0,
      isGroup: json['isGroup'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'realPhoneNumber': realPhoneNumber,
      'lastMessage': lastMessage,
      'lastMessageTime': this.lastMessageTime,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
    };
  }

  ChatOverview copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? realPhoneNumber,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isGroup,
  }) {
    return ChatOverview(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      realPhoneNumber: realPhoneNumber ?? this.realPhoneNumber,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
    );
  }

  ChatOverview update({
    String? id,
    String? name,
    String? phoneNumber,
    String? realPhoneNumber,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isGroup,
  }) => copyWith(
    id: id,
    name: name,
    phoneNumber: phoneNumber,
    realPhoneNumber: realPhoneNumber,
    lastMessage: lastMessage,
    lastMessageTime: lastMessageTime,
    unreadCount: unreadCount,
    isGroup: isGroup,
  );

  @override
  List<Object?> get props => [id, name, phoneNumber, realPhoneNumber, lastMessage, lastMessageTime, unreadCount, isGroup];
}
