import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy/main.dart';
import 'package:dummy/models/user_model.dart';
import 'package:dummy/utils/encryption_key_manager.dart';
import 'package:dummy/utils/aes_gcm_encryption.dart';

class ChatManager {
  final String senderId = "1";
  CollectionReference messages =
      FirebaseFirestore.instance.collection("messages");
  CollectionReference chats = FirebaseFirestore.instance.collection("chats");

  // get the Id of chat between the current user and the selected respondent
  Future getChatId(
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
  Stream<DocumentSnapshot>? getChatStream({required String? chatId}) {
    return chats.doc(chatId).snapshots();
  }

  // generate a shared secret key with the public key of the recipient
  static Future getUserKeyPair(
      {required String userId}) async {
    DocumentSnapshot userInfo = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    if (userInfo.exists) {
      return UserModel.fromJson(userInfo.data() as Map<String, dynamic>);
    }

    return null;
  }

  /* Start a new conversation with the respondent where the messageID
    is a concatenation of the sender's id and the recipient's id
  */
  Future sendChat(
      {required String recipientId,
      required String existingChatId,
      required String chat,
      required String recipientPushToken,
      required Function(String) onSubmitNewChat,
      isNewChat = false}) async {
    // create the chat
    try {
      late DocumentReference document;
      late String chatId;
      // String secretKey;

      // generate a new chatId if the conversation is happening for the first time
      if (existingChatId.isNotEmpty) {
        document = chats.doc(existingChatId);
      } else {
        document = chats.doc();
      }

      UserModel? recipientKeys = await getUserKeyPair(userId: recipientId);

      if (recipientKeys == null){
        return "An error occurred while sending your message";
      }

      // encrypt the message that is being sent
      String encryptedMessage = AESGCMEncryption.encryptAESCryptoJS(chat,
          encryptionKeyManager.generateEncryptionSecretKey(
              recipientPublicKey:recipientKeys.publicKey));

      await document.set({
        "senderId": senderId,
        "recipientId": recipientId,
        "chats": FieldValue.arrayUnion([
          {
            "chat": encryptedMessage,
            "sender": senderId,
            "timeSent": DateTime.now()
          }
        ]),
      }, SetOptions(merge: true));

      // update the id of the provider with the new chat Id
      if (isNewChat) {
        onSubmitNewChat(document.id);
      }

      // get the id of the chat document that was just created
      chatId = isNewChat ? document.id : existingChatId;

      // check if the conversation is happening for the first time and create a message record for both sender and recipient
      if (isNewChat) {
        // add the chat record to the sender's data
        await messages
            .doc(senderId)
            .collection("recipients")
            .doc(recipientId)
            .set({"chatId": chatId});

        // add the chat record to the recipient's data
        await messages
            .doc(recipientId)
            .collection("recipients")
            .doc(senderId)
            .set({"chatId": chatId});
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
