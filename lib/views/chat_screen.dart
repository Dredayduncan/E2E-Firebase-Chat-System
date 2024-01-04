import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy/firebase_chat/chat_manager.dart';
import 'package:dummy/main.dart';
import 'package:dummy/models/conversation_model.dart';
import 'package:dummy/models/local_chat_db/local_conversation_model.dart';
import 'package:dummy/models/remote_signal_public_info_model.dart';
import 'package:dummy/models/signal_protocol_info_model.dart';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

// sender as current user
const String senderId = "1";
const String recipientId = "2";
const String senderPhone = "+233123456789";
const String recipientPhone = "+233123456798";

// recipient as current user
// const String senderId = "2";
// const String recipientId = "1";
// const String senderPhone = "+233123456798";
// const String recipientPhone = "+233123456789";

class ChatScreen extends StatefulWidget {
  final SignalProtocolInfoModel signalProtocolInfoModel;

  const ChatScreen({super.key, required this.signalProtocolInfoModel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController chatController = TextEditingController();
  ChatManager chatManager = ChatManager();
  String chatId = "";
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

  createRemoteSessionCipher() async {

    try{


      // create the remote session cipher
      final signalProtocolStore = InMemorySignalProtocolStore(
          widget.signalProtocolInfoModel.identityKeyPair, 1);

      const recipientAddress = SignalProtocolAddress(recipientPhone, 1);

      remoteSessionCipher =
          SessionCipher.fromStore(signalProtocolStore, recipientAddress);
      for (final p in widget.signalProtocolInfoModel.preKeys) {
        await signalProtocolStore.storePreKey(p.id, p);
      }
      await signalProtocolStore.storeSignedPreKey(
          widget.signalProtocolInfoModel.signedPreKeyRecord.id,
          widget.signalProtocolInfoModel.signedPreKeyRecord);
    }
    catch(e, st){
      log(e.toString(), stackTrace: st);

    }


  }

  // create the pre key bundle from the remote signal protocol info
  initializeSessionCiphers(
      RemoteSignalPublicInfoModel? remoteSignalPublicInfoModel) async {
    if (remoteSignalPublicInfoModel != null) {
      // create the preKey bundle
      PreKeyBundle preKeyBundle = PreKeyBundle(
          remoteSignalPublicInfoModel.registrationId,
          1,
          remoteSignalPublicInfoModel.preKeys[0].id,
          remoteSignalPublicInfoModel.preKeys[0].getKeyPair().publicKey,
          remoteSignalPublicInfoModel.signedPreKeyRecordId,
          remoteSignalPublicInfoModel.signedPublicPreKey,
          remoteSignalPublicInfoModel.signedPreKeySignature,
          remoteSignalPublicInfoModel.identityKey);

      final sessionStore = InMemorySessionStore();
      final preKeyStore = InMemoryPreKeyStore();
      final signedPreKeyStore = InMemorySignedPreKeyStore();
      final identityStore = InMemoryIdentityKeyStore(
          widget.signalProtocolInfoModel.identityKeyPair,
          widget.signalProtocolInfoModel.registrationId);

      for (final p in widget.signalProtocolInfoModel.preKeys) {
        await preKeyStore.storePreKey(p.id, p);
      }

      await signedPreKeyStore.storeSignedPreKey(
          widget.signalProtocolInfoModel.signedPreKeyRecord.id,
          widget.signalProtocolInfoModel.signedPreKeyRecord);

      const recipientAddress = SignalProtocolAddress(recipientPhone, 1);

      //bob's phone number and device id
      final sessionBuilder = SessionBuilder(sessionStore, preKeyStore,
          signedPreKeyStore, identityStore, recipientAddress);
      await sessionBuilder.processPreKeyBundle(preKeyBundle);
      sessionCipher = SessionCipher(sessionStore, preKeyStore,
          signedPreKeyStore, identityStore, recipientAddress);

      //  create the remote session cipher
      createRemoteSessionCipher();

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
            body: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(title: const Text("E2E Chat")),
            backgroundColor: const Color(0xFFF6F6F6),
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
                                if (chatController.text.trim().isEmpty) {
                                  return;
                                }

                                if (sessionCipher != null) {
                                  //encrypt the text
                                  final cipherText = await sessionCipher!
                                      .encrypt(Uint8List.fromList(utf8
                                          .encode(chatController.text.trim())));
                                  //the cipher text string can be to large so,
                                  final encryptedMessage =
                                      base64Encode(cipherText.serialize());

                                  await chatManager.sendChat(
                                    recipientId: recipientId,
                                    senderId: senderId,
                                    existingChatId: chatId,
                                    isNewChat: chatId.isEmpty,
                                    chat: encryptedMessage,
                                    // recipientPushToken: '',
                                    onSubmitNewChat: (String value) {
                                      setState(() {
                                        chatId = value;
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
              future: chatManager.getChatId(
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

                  chatId = snapshot.data['chatId'];

                  return SingleChildScrollView(
                    reverse: true,
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: ChatManager().getChatStream(
                          chatId: chatId.isEmpty ? null : chatId),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
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
                          return const CircularProgressIndicator();
                        }

                        // Check if there has been no conversation between them
                        if (!snapshot.data!.exists) {
                          // indicate that the chat is new
                          return const Center(
                            child: Text(
                              "Say Something.",
                            ),
                          );
                        }

                        // Get the chats between the user and the respondent
                        DocumentSnapshot doc =
                            snapshot.data as DocumentSnapshot;

                        ConversationModel conversationModel =
                            ConversationModel.fromJson(
                                doc.data() as Map<String, dynamic>);

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
                                  itemCount: conversationModel.chats.length,
                                  itemBuilder: ((context, index) {
                                    bool isMe =
                                        conversationModel.chats[index].sender ==
                                            senderId;

                                    log("chat: ${conversationModel.chats[index].chat}");

                                    Uint8List decodedBase64CipherText =
                                        base64Decode(conversationModel
                                            .chats[index].chat);

                                    log("decodedCipherText: $decodedBase64CipherText");



                                    if (!isMe && remoteSessionCipher != null) {
                                      remoteSessionCipher!.decryptWithCallback(PreKeySignalMessage(
                                          decodedBase64CipherText), (plaintext) {

                                      }).then((value) => log("PLAINTEXT: ${utf8.decode(value)}"));

                                      return FutureBuilder(
                                          future: remoteSessionCipher!.decrypt(
                                              PreKeySignalMessage(
                                                  decodedBase64CipherText)),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<Uint8List?>
                                                  snapshot) {

                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return _buildMessage("...", isMe);
                                            }

                                            if (snapshot.hasData) {
                                              // store the decrypted message in the db
                                              // allChats.put(LocalConversationModel())
                                              log("HAS: ${snapshot.data.toString()}");

                                              return _buildMessage(utf8
                                                  .decode(snapshot.data!), isMe);
                                            }

                                            return _buildMessage("", isMe);
                                          });
                                    }

                                    return _buildMessage(
                                        conversationModel.chats[index].chat,
                                        isMe);
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
