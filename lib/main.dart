import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dummy/firebase_chat/chat_manager.dart';
import 'package:dummy/models/remote_signal_public_info_model.dart';
import 'package:dummy/models/signal_protocol_info_model.dart';
import 'package:dummy/utils/encryption_key_manager.dart';
import 'package:dummy/models/conversation_model.dart';
import 'package:dummy/utils/aes_gcm_encryption.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'firebase_options.dart';

// sender as current user
final String senderId = "1";
final String recipientId = "2";
const String senderPhone = "+233123456789";
const String recipientPhone = "+233123456798";

// recipient as current user
// final String senderId = "2";
// final String recipientId = "1";
// const String senderPhone = "+233123456798";
// const String recipientPhone = "+233123456789";

// Get the current user's signal protocol credentials if the user has one.
// If the user doesn't have one, create one and store it in their firebase document
Future<SignalProtocolInfoModel> setupSignalProtocol(
    {required String userId}) async {
  // Create storage
  final storage = FlutterSecureStorage();

  // await storage.deleteAll();

  // get the stored identity key pair
  String? storedKeyPair = await storage.read(key: "identityKeyPair");
  String? storedPreKeys = await storage.read(key: "preKeys");
  String? storedRegistrationId = await storage.read(key: "registrationId");
  String? storedSignedPreKeyRecord =
      await storage.read(key: "signedPreKeyRecord");

  // check if there is an identity keypair in the keystore and load the info
  if (storedKeyPair != null &&
      storedPreKeys != null &&
      storedRegistrationId != null &&
      storedSignedPreKeyRecord != null) {

    IdentityKeyPair identityKeyPair = IdentityKeyPair.fromSerialized(
        Uint8List.fromList(List<int>.from(jsonDecode(storedKeyPair))));

    List<PreKeyRecord> preKeys = jsonDecode(storedPreKeys)
        .map<PreKeyRecord>((e) =>
        PreKeyRecord.fromBuffer(Uint8List.fromList(List<int>.from(e))))
        .toList();
    int registrationId = int.parse(storedRegistrationId);

    SignedPreKeyRecord signedPreKeyRecord = SignedPreKeyRecord.fromSerialized(
        Uint8List.fromList(
            List<int>.from(jsonDecode(storedSignedPreKeyRecord))));

    return SignalProtocolInfoModel(
        identityKeyPair: identityKeyPair,
        preKeys: preKeys,
        signedPreKeyRecord: signedPreKeyRecord,
        registrationId: registrationId);
  }

  // create new signal protocol credentials
  IdentityKeyPair identityKeyPair = generateIdentityKeyPair();

  final int registrationId = generateRegistrationId(false);

  final List<PreKeyRecord> preKeys = generatePreKeys(0, 100);

  final SignedPreKeyRecord signedPreKeyRecord =
      generateSignedPreKey(identityKeyPair, 0);

  // store the generated keys and info
  storage.write(
      key: "identityKeyPair", value: jsonEncode(identityKeyPair.serialize()));

  storage.write(key: "registrationId", value: registrationId.toString());
  storage.write(
      key: "preKeys",
      value: jsonEncode(preKeys.map((e) => e.serialize()).toList()));
  storage.write(
      key: "signedPreKeyRecord",
      value: jsonEncode(signedPreKeyRecord.serialize()));

  SignalProtocolInfoModel signalProtocolInfoModel = SignalProtocolInfoModel(
      identityKeyPair: identityKeyPair,
      preKeys: preKeys,
      signedPreKeyRecord: signedPreKeyRecord,
      registrationId: registrationId);

  // get deviceId
  final deviceInfo = await DeviceInfoPlugin();

  String deviceId = "";

  if (Platform.isIOS) {
    // import 'dart:io'
    var iosDeviceInfo = await deviceInfo.iosInfo;
    deviceId = iosDeviceInfo.identifierForVendor ?? ""; // unique ID on iOS
  } else if (Platform.isAndroid) {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    deviceId = androidDeviceInfo.id; // unique ID on Android
  }

  // get the public info for the signal protocol credentials
  Map<String, dynamic> publicSignalInfo =
      signalProtocolInfoModel.toPublicInfoMap();
  publicSignalInfo['deviceId'] = deviceId; //add the user's device id

  // send the credentials to the server
  await ChatManager.storeLocalUserSignalInfo(
      userId: userId,
      publicSignalInfo: publicSignalInfo);

  return signalProtocolInfoModel;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // name: "Dummy",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SignalProtocolInfoModel signalProtocolInfoModel =
      await setupSignalProtocol(userId: senderId);

  runApp(MyApp(
    signalProtocolInfoModel: signalProtocolInfoModel,
  ));
}

class MyApp extends StatelessWidget {
  final SignalProtocolInfoModel signalProtocolInfoModel;
  const MyApp({super.key, required this.signalProtocolInfoModel});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E2E Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'E2E Chat App',
        signalProtocolInfoModel: signalProtocolInfoModel,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final SignalProtocolInfoModel signalProtocolInfoModel;
  const MyHomePage(
      {super.key, required this.title, required this.signalProtocolInfoModel});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController chatController = TextEditingController();
  ChatManager chatManager = ChatManager();
  String chatId = "";
  RemoteSignalPublicInfoModel? remoteSignalPublicInfoModel;
  late PreKeyBundle preKeyBundle;
  SessionCipher? sessionCipher;

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

  // create the pre key bundle from the remote signal protocol info
  initializePreKeyBundle(
      RemoteSignalPublicInfoModel? remoteSignalPublicInfoModel) async {
    if (remoteSignalPublicInfoModel != null) {
      // create the preKey bundle
      preKeyBundle = PreKeyBundle(
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

      setState(() {});
    }
  }

  @override
  void initState() {
    getRemoteSignalPublicInfoModel()
        .then((value) => initializePreKeyBundle(value));
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

                                    final decodedBase64CipherText =
                                        base64Decode(conversationModel
                                            .chats[index].chat);

                                    log("decodedCipherText: $decodedBase64CipherText");

                                    if (sessionCipher != null){
                                      return FutureBuilder(
                                          future: sessionCipher!.decrypt(
                                              PreKeySignalMessage(
                                                  decodedBase64CipherText)),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<Uint8List?>
                                              snapshot) {
                                            String message = "";

                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              message = "...";
                                            }

                                            if (snapshot.hasData) {
                                              log(snapshot.data.toString());
                                              message = utf8
                                                  .decode(snapshot.data ?? []);
                                            }

                                            return _buildMessage(message, isMe);
                                          });
                                    }

                                    return _buildMessage(conversationModel.chats[index].chat, isMe);


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
