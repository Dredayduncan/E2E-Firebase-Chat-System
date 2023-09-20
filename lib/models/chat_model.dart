import 'dart:developer';

class ChatModel {
  final String sender;
  final DateTime timeSent;
  final String chat;
  final String chatID;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      sender: json["sender"],
      timeSent: json["timeSent"].toDate(),
      chat: json["chat"],
      chatID: json["chatID"] ?? "",
    );
  }

//<editor-fold desc="Data Methods">
  const ChatModel({
    required this.sender,
    required this.timeSent,
    required this.chat,
    required this.chatID,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatModel &&
          runtimeType == other.runtimeType &&
          sender == other.sender &&
          timeSent == other.timeSent &&
          chat == other.chat &&
          chatID == other.chatID);

  @override
  int get hashCode =>
      sender.hashCode ^ timeSent.hashCode ^ chat.hashCode ^ chatID.hashCode;

  @override
  String toString() {
    return 'Chat{ sender: $sender, timeSent: $timeSent, chat: $chat, chatID: $chatID,}';
  }

  ChatModel copyWith({
    String? sender,
    DateTime? timeSent,
    String? chat,
    String? chatID,
  }) {
    return ChatModel(
      sender: sender ?? this.sender,
      timeSent: timeSent ?? this.timeSent,
      chat: chat ?? this.chat,
      chatID: chatID ?? this.chatID,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': this.sender,
      'timeSent': this.timeSent,
      'chat': this.chat,
      'chatID': this.chatID,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      sender: map['sender'] as String,
      timeSent: map['timeSent'] as DateTime,
      chat: map['chat'] as String,
      chatID: map['chatID'] as String,
    );
  }


//

//</editor-fold>
}
