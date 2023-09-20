import 'package:dummy/models/chat_model.dart';

class ConversationModel {
  final String senderId;
  final String recipientId;
  final List<ChatModel> chats;


  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      senderId: json["senderId"],
      recipientId: json["recipientId"],
      chats: json['chats'] == null ? [] : json["chats"]
          .map<ChatModel>((i) => ChatModel.fromJson(i)).toList(),
    );
  }

//<editor-fold desc="Data Methods">
  const ConversationModel({
    required this.senderId,
    required this.recipientId,
    required this.chats,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationModel &&
          runtimeType == other.runtimeType &&
          senderId == other.senderId &&
          recipientId == other.recipientId &&
          chats == other.chats);

  @override
  int get hashCode => senderId.hashCode ^ recipientId.hashCode ^ chats.hashCode;

  @override
  String toString() {
    return 'ConversationModel{' +
        ' senderId: $senderId,' +
        ' recipientId: $recipientId,' +
        ' chats: $chats,' +
        '}';
  }

  ConversationModel copyWith({
    String? senderId,
    String? recipientId,
    List<ChatModel>? chats,
  }) {
    return ConversationModel(
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      chats: chats ?? this.chats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': this.senderId,
      'recipientId': this.recipientId,
      'chats': this.chats,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      senderId: map['senderId'] as String,
      recipientId: map['recipientId'] as String,
      chats: map['chats'] as List<ChatModel>,
    );
  }

//</editor-fold>
}