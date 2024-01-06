import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy/firebase_chat/chat_manager.dart';
import 'package:dummy/models/chat_model.dart';
import 'package:dummy/models/remote_signal_public_info_model.dart';
import 'package:dummy/models/signal_protocol_info_model.dart';
import 'package:dummy/utils/main_setup.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import '../main.dart';
import '../models/local_chat_db/local_conversation_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController chatController = TextEditingController();
  ChatManager chatManager = ChatManager();
  String conversationId = "";
  RemoteSignalPublicInfoModel? remoteSignalPublicInfoModel;
  SessionCipher? sessionCipher;
  SessionCipher? remoteSessionCipher;

  // get the remote user's (recipient's) public signal credentials
  Future<RemoteSignalPublicInfoModel?> getRemoteSignalPublicInfoModel() async {
    final result = await ChatManager.getUserSignalInfo(userId: recipientId);

    // check if an error occurred
    if (result is String) {
      log(result);
      return null;
    }

    remoteSignalPublicInfoModel = result;
    return remoteSignalPublicInfoModel;
  }

  // Create the session cipher that will be used by the recipient to decrypt the messages
  createRemoteSessionCipher() async {
    try {
      // create the remote session cipher
      final signalProtocolStore = InMemorySignalProtocolStore(
          getIt<SignalProtocolInfoModel>().identityKeyPair,
          getIt<SignalProtocolInfoModel>().registrationId);

      SignalProtocolAddress recipientAddress = SignalProtocolAddress(
          remoteSignalPublicInfoModel!.phoneNumber,
          remoteSignalPublicInfoModel!.deviceId);

      // create the remote session store
      remoteSessionCipher =
          SessionCipher.fromStore(signalProtocolStore, recipientAddress);

      for (final p in getIt<SignalProtocolInfoModel>().preKeys) {
        await signalProtocolStore.storePreKey(p.id, p);
      }
      await signalProtocolStore.storeSignedPreKey(
          getIt<SignalProtocolInfoModel>().signedPreKeyRecord.id,
          getIt<SignalProtocolInfoModel>().signedPreKeyRecord);
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
    }
  }

  //  Create the session cipher that would be used by the sender to encrypt the messages
  createLocalSessionCipher(PreKeyBundle preKeyBundle) async {
    final sessionStore = InMemorySessionStore();
    final preKeyStore = InMemoryPreKeyStore();
    final signedPreKeyStore = InMemorySignedPreKeyStore();
    final identityStore = InMemoryIdentityKeyStore(
        getIt<SignalProtocolInfoModel>().identityKeyPair,
        getIt<SignalProtocolInfoModel>().registrationId);

    for (final p in getIt<SignalProtocolInfoModel>().preKeys) {
      await preKeyStore.storePreKey(p.id, p);
    }

    await signedPreKeyStore.storeSignedPreKey(
        getIt<SignalProtocolInfoModel>().signedPreKeyRecord.id,
        getIt<SignalProtocolInfoModel>().signedPreKeyRecord);

    log("ENCRYPTION ADDRESS: ${remoteSignalPublicInfoModel!.phoneNumber}");

    SignalProtocolAddress recipientAddress = SignalProtocolAddress(
        remoteSignalPublicInfoModel!.phoneNumber,
        remoteSignalPublicInfoModel!.deviceId);

    //bob's phone number and device id
    final sessionBuilder = SessionBuilder(sessionStore, preKeyStore,
        signedPreKeyStore, identityStore, recipientAddress);
    await sessionBuilder.processPreKeyBundle(preKeyBundle);

    sessionCipher = SessionCipher(sessionStore, preKeyStore, signedPreKeyStore,
        identityStore, recipientAddress);
  }

  // create the pre key bundle from the remote signal protocol info
  initializeSessionCiphers(
      RemoteSignalPublicInfoModel? remoteSignalPublicInfoModel) async {
    if (remoteSignalPublicInfoModel != null) {
      // create the preKey bundle
      PreKeyBundle preKeyBundle = PreKeyBundle(
          remoteSignalPublicInfoModel.registrationId,
          remoteSignalPublicInfoModel.deviceId,
          remoteSignalPublicInfoModel.preKeys[0].id,
          remoteSignalPublicInfoModel.preKeys[0].getKeyPair().publicKey,
          remoteSignalPublicInfoModel.signedPreKeyRecordId,
          remoteSignalPublicInfoModel.signedPublicPreKey,
          remoteSignalPublicInfoModel.signedPreKeySignature,
          remoteSignalPublicInfoModel.identityKey);

      // create the local session cipher
      await createLocalSessionCipher(preKeyBundle);
      //  create the remote session cipher
      await createRemoteSessionCipher();

      setState(() {});
    }
  }

  @override
  void initState() {
    getRemoteSignalPublicInfoModel()
        .then((value) => initializeSessionCiphers(value));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return remoteSignalPublicInfoModel == null
        ? const Scaffold(
            backgroundColor: Color(0xFF212121),
            body: Center(child: CircularProgressIndicator()),
          )
        : Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text(
                "E2E Chat",
                style: TextStyle(color: Color(0xFFF2F2F2)),
              ),
              backgroundColor: const Color(0xFF212121),
            ),
            backgroundColor: const Color(0xFF212121),
            bottomSheet: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: chatController,
                        decoration: InputDecoration(
                            hintText: 'Type message',
                            icon: const Icon(Icons.message),
                            suffixIcon: IconButton(
                              onPressed: () async {
                                String chat = chatController.text.trim();

                                if (chat.isEmpty) {
                                  return;
                                }

                                if (sessionCipher != null) {
                                  await chatManager.sendChat(
                                    recipientId: recipientId,
                                    senderId: senderId,
                                    existingConversationId: conversationId,
                                    isNewChat: conversationId.isEmpty,
                                    sessionCipher: sessionCipher!,
                                    chat: chat,
                                    // recipientPushToken: '',
                                    onSubmitNewChat: (String value) {
                                      setState(() {
                                        conversationId = value;
                                      });
                                    },
                                  );

                                  chatController.clear();
                                }
                              },
                              icon: const Icon(
                                Icons.send,
                              ),
                            )),
                      ),
                    ),
                  )
                ],
              ),
            ),
            body: FutureBuilder(
              future: chatManager.getConversationId(
                  senderId: senderId, recipientId: recipientId),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasData) {
                  if (snapshot.data is String) {
                    return const Center(
                        child: Text("Start a new conversation"));
                  }

                  conversationId = snapshot.data['chatId'];

                  return SingleChildScrollView(
                    reverse: true,
                    child: StreamBuilder<QuerySnapshot<ChatModel>>(
                      stream: ChatManager().getChatStream(
                          conversationId:
                              conversationId.isEmpty ? null : conversationId),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot<ChatModel>> snapshot) {
                        //Check if an error occurred
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              "Something went wrong",
                            ),
                          );
                        }

                        // Check if the connection is still loading
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // Check if there has been no conversation between them
                        if (!snapshot.hasData) {
                          // indicate that the chat is new
                          return const Center(
                            child: Text(
                              "Say Something.",
                            ),
                          );
                        }

                        List<ChatModel> chats =
                            snapshot.data!.docs.map((e) => e.data()).toList();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).size.height * 0.11,
                                ),
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: chats.length,
                                  itemBuilder: ((context, index) {
                                    bool isMe = chats[index].sender == senderId;

                                    return FutureBuilder(
                                        future:
                                        getDecryptedChat(chats[index]),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<String> snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return _buildMessage("...", isMe);
                                          }

                                          if (snapshot.hasData) {
                                            // store the decrypted message in the db
                                            // allChats.put(LocalConversationModel())
                                            log("HAS: ${snapshot.data.toString()}");

                                            return _buildMessage(
                                                snapshot.data!, isMe);
                                          }

                                          return _buildMessage("", isMe);
                                        });

                                    return _buildMessage(
                                        chats[index].chat, isMe);
                                  }),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }

                return Center(
                  child: Text(snapshot.data.toString()),
                );
              },
            ),
          );
  }

  Future<String> getDecryptedChat(ChatModel chat) async {
    int localConversationId = fastHash(conversationId);
    // get the local db
    IsarCollection<LocalConversationModel> localDb =
        getIt<Isar>().localConversationModels;

    // get this conversation from the local db
    LocalConversationModel? allChatsForThisConversation =
        await localDb.get(localConversationId);

    // check if the chat was sent by the current user
    if (chat.sender == senderId) {
      // get the message from the local db since the sender can't decrypt messages they sent
      return allChatsForThisConversation != null
          ? allChatsForThisConversation.message != null
              ? jsonDecode(allChatsForThisConversation.message!)[chat.id]
              : ""
          : "";
    }

    // log("message");

    // // create a new conversation model is it doesn't exist already
    allChatsForThisConversation ??= LocalConversationModel()
      ..message = jsonEncode({})
      ..id = conversationId;

    Map<String, dynamic> existingChat =
        allChatsForThisConversation.message != null
            ? jsonDecode(allChatsForThisConversation.message!)
            : {};

    // return the raw message if it's already been saved
    if (existingChat.containsKey(chat.id)) {
      log(existingChat[chat.id]);
      return existingChat[chat.id] ?? "Chat not found.";
    }

    try {
      Uint8List decodedBase64CipherText = base64Decode(chat.chat);

      if (remoteSessionCipher != null){
        String decryptedChat = utf8.decode(await remoteSessionCipher!
            .decrypt(PreKeySignalMessage(decodedBase64CipherText)));

        log("decodedCipherText: $decryptedChat");

        // add the new chat to the db
        existingChat[chat.id] = decryptedChat;

        await getIt<Isar>().writeTxn(() async {
          // insert the decrypted chat into the db
          await localDb.put(allChatsForThisConversation!
              .copyWith(message: jsonEncode(existingChat)));
        });

        // return the decrypted chat
        return jsonDecode(
            (await localDb.get(localConversationId))!.message!)[chat.id];
      }

      return "No remote session cipher";

    } catch (e, st) {
      log(e.toString(), stackTrace: st);
      return e.toString();
    }
  }

  _buildMessage(String message, bool isMe) {
    return BubbleSpecialThree(
      text: message,
      color: isMe ? Colors.red.withOpacity(0.7) : Colors.grey,
      tail: true,
      textStyle: const TextStyle(color: Colors.white, fontSize: 16),
      isSender: isMe,
    );
  }
}
