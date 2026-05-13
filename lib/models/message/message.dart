import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;

class Message extends Equatable {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;
  final String eventoId;

  Message({
    this.id = '',
    this.text = '',
    required this.timestamp,
    this.isMe = false,
    this.isRead = false,
    this.eventoId = '',
  });

  factory Message.fromMap(String id, Map<String, dynamic> json) {
    return Message(
      id: id,
      text: json['text'] ?? '',
      timestamp: json["timestamp"] is DateTime?json["timestamp"]:_.DateUtils.firestoreToItalianTime(json["timestamp"]),
      isMe: json['isMe'] ?? false,
      isRead: json['isRead'] ?? false,
      eventoId: json['eventoId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'timestamp': this.timestamp,
      'isMe': isMe,
      'isRead': isRead,
      'eventoId': eventoId,
    };
  }

  Message copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isMe,
    bool? isRead,
    String? eventoId,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      isRead: isRead ?? this.isRead,
      eventoId: eventoId ?? this.eventoId,
    );
  }

  Message update({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isMe,
    bool? isRead,
    String? eventoId,
  }) => copyWith(
    id: id,
    text: text,
    timestamp: timestamp,
    isMe: isMe,
    isRead: isRead,
    eventoId: eventoId,
  );

  @override
  List<Object?> get props => [id, text, timestamp, isMe, isRead,  eventoId];
}
