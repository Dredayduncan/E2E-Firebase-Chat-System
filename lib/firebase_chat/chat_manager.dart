import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy/models/local_chat_db/local_conversation_model.dart';
import 'package:dummy/models/remote_signal_public_info_model.dart';
import 'package:dummy/models/user_model.dart';
import 'package:dummy/utils/main_setup.dart';
import 'package:isar/isar.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../models/chat_model.dart';

class ChatManager {
  // final String senderId = "1";
  CollectionReference messages =
      FirebaseFirestore.instance.collection("messages");
  CollectionReference chats = FirebaseFirestore.instance.collection("chats");

  // get the Id of chat between the current user and the selected respondent
  Future getConversationId(
      {required String senderId, required String recipientId}) async {
    try {
      DocumentSnapshot document = await messages
          .doc(senderId)
          .collection("recipients")
          .doc(recipientId)
          .get();

      if (document.exists) {
        return (document.data() as Map<String, dynamic>);
      }

      return "";
    } catch (exception, st) {
      log(exception.toString(), stackTrace: st);
      return "An error occurred while retrieving your chat";
    }
  }

  // Get the chats the current user has with the given respondent
  Stream<QuerySnapshot<ChatModel>>? getChatStream({required String? conversationId}) {
    // return chats.doc(chatId).collection("messages").snapshots();
    return chats
        .doc(conversationId)
        .collection("messages")
        .orderBy("timeSent", descending: false)
        .withConverter<ChatModel>(fromFirestore: (document, options) {
      return ChatModel.fromJson(document.data() as Map<String, dynamic>);
    }, toFirestore: (document, options) {
      return document.toMap();
    }).snapshots();
  }

  static Future<bool> storeLocalUserSignalInfo(
      {required String userId,
      required Map<String, dynamic> publicSignalInfo}) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .set({"publicSignalInfo": publicSignalInfo});

      return true;
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
      return false;
    }
  }

  static Future getUserSignalInfo({required String userId}) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        return RemoteSignalPublicInfoModel.fromMap(
            documentSnapshot.get("publicSignalInfo"));
      }

      return "User does not exist";
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
      return "Unable to get remote user signal info";
    }
  }

  /* Start a new conversation with the respondent where the messageID
    is a concatenation of the sender's id and the recipient's id
  */
  Future sendChat(
      {required String recipientId,
      required String existingConversationId,
      required String chat,
      required String senderId,
      required SessionCipher sessionCipher,
      // required String recipientPushToken,
      required Function(String) onSubmitNewChat,
      isNewChat = false}) async {
    // create the chat
    try {
      late DocumentReference document;

      // generate a new chatId if the conversation is happening for the first time
      if (existingConversationId.isNotEmpty) {
        document = chats.doc(existingConversationId);
      } else {
        document = chats.doc();
      }

      // get the id of the chat document that was just created
      String conversationId = isNewChat ? document.id : existingConversationId;

      DocumentReference newMessageDocument = document.collection("messages").doc();

      // store the raw chat in the local db
      IsarCollection<LocalConversationModel> allChats =
          getIt<Isar>().localConversationModels;

      // get this conversation from the local db
      LocalConversationModel? allChatsForThisConversation =
          await allChats.get(fastHash(conversationId));

      // check if there is no conversation stored and create one
      if (allChatsForThisConversation == null) {
        // store the raw chat in the db
        await getIt<Isar>().writeTxn(() async {
          Map<String, dynamic> existingConversation = {newMessageDocument.id: chat};

          await allChats.put(LocalConversationModel()
            ..id = conversationId
            ..message = jsonEncode(existingConversation));
        });

      }
      else{

        Map<String, dynamic> existingConversation = allChatsForThisConversation.message != null
            ? jsonDecode(allChatsForThisConversation.message!)
            : {};

        // add the new chat to the messages in the existing conversation
        existingConversation[newMessageDocument.id] = chat;

        // store the raw chat in the db
        await getIt<Isar>().writeTxn(() async {

          await allChats.put(allChatsForThisConversation.copyWith(
            message: jsonEncode(existingConversation)
          ));
        });

      }

      //encrypt the text
      final cipherText =
          await sessionCipher.encrypt(Uint8List.fromList(utf8.encode(chat)));
      //the cipher text string can be to large so,
      final encryptedMessage = base64Encode(cipherText.serialize());

      await newMessageDocument.set({
        "chat": encryptedMessage,
        "sender": senderId,
        "timeSent": DateTime.now(),
        "conversationId": conversationId,
        "id": newMessageDocument.id
      });

      // update the id of the provider with the new chat Id
      if (isNewChat) {
        onSubmitNewChat(document.id);
      }

      // check if the conversation is happening for the first time and create a message record for both sender and recipient
      if (isNewChat) {
        // add the chat record to the sender's data
        await messages
            .doc(senderId)
            .collection("recipients")
            .doc(recipientId)
            .set({"chatId": conversationId});

        // add the chat record to the recipient's data
        await messages
            .doc(recipientId)
            .collection("recipients")
            .doc(senderId)
            .set({"chatId": conversationId});
      }

      // // send a push notification
      // await CustomNotification.sendNotification(
      //     toPushToken: recipientPushToken,
      //     title: "Message from ${user.name}",
      //     body: chat);

      return;
    } catch (exception, st) {
      log(exception.toString(), stackTrace: st);
      return "An error occurred while sending your message";
    }
  }
}
