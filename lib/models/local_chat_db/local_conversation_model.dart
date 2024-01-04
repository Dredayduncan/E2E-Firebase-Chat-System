import 'package:isar/isar.dart';


@collection
class LocalConversationModel {
  Id id = Isar.autoIncrement;
  String? conversationId;
  String? chatId;
  String? message;
}