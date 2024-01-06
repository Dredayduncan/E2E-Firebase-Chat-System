class ChatModel {
  final String sender;
  final DateTime timeSent;
  final String chat;
  final String conversationId;
  final String id;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      sender: json["sender"],
      timeSent: json["timeSent"].toDate(),
      chat: json["chat"],
      conversationId: json["conversationId"] ?? "",
      id: json['id']
    );
  }

//<editor-fold desc="Data Methods">
  const ChatModel({
    required this.sender,
    required this.timeSent,
    required this.chat,
    required this.conversationId,
    required this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatModel &&
          runtimeType == other.runtimeType &&
          sender == other.sender &&
          timeSent == other.timeSent &&
          chat == other.chat &&
          conversationId == other.conversationId &&
          id == other.id);

  @override
  int get hashCode =>
      sender.hashCode ^
      timeSent.hashCode ^
      chat.hashCode ^
      conversationId.hashCode ^
      id.hashCode;

  @override
  String toString() {
    return 'ChatModel{ sender: $sender, timeSent: $timeSent, chat: $chat, conversationId: $conversationId, id: $id,}';
  }

  ChatModel copyWith({
    String? sender,
    DateTime? timeSent,
    String? chat,
    String? conversationId,
    String? id,
  }) {
    return ChatModel(
      sender: sender ?? this.sender,
      timeSent: timeSent ?? this.timeSent,
      chat: chat ?? this.chat,
      conversationId: conversationId ?? this.conversationId,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': this.sender,
      'timeSent': this.timeSent,
      'chat': this.chat,
      'conversationId': this.conversationId,
      'id': this.id,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      sender: map['sender'] as String,
      timeSent: map['timeSent'] as DateTime,
      chat: map['chat'] as String,
      conversationId: map['conversationId'] as String,
      id: map['id'] as String,
    );
  }

//</editor-fold>
}
