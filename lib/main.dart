import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy/firebase_chat/chat_manager.dart';
import 'package:dummy/utils/encryption_key_manager.dart';
import 'package:dummy/models/chat_model.dart';
import 'package:dummy/models/conversation_model.dart';
import 'package:dummy/utils/aes_gcm_encryption.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

EncryptionKeyManager encryptionKeyManager = EncryptionKeyManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // name: "Dummy",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await encryptionKeyManager.updateEncryptionKey();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController chatController = TextEditingController();
  ChatManager chatManager = ChatManager();
  final String senderId = "1";
  final String recipientId = "2";

  String chatId = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dummy Chat")),
      backgroundColor: const Color(0xFFF6F6F6),
      bottomSheet: Container(
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

                          if (chatController.text.trim().isEmpty){
                            return;
                          }

                          await chatManager.sendChat(
                            recipientId: recipientId,
                            existingChatId: chatId,
                            isNewChat: chatId.isEmpty,
                            chat: chatController.text.trim(),
                            recipientPushToken: '',
                            onSubmitNewChat: (String value) {
                              setState(() {
                                chatId = value;
                              });
                            },
                          );

                          chatController.clear();
                        },
                        icon: const Icon(
                          Icons.send,
                        ),
                      )
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      body: FutureBuilder(
        future:
            chatManager.getChatId(senderId: senderId, recipientId: recipientId),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasData) {
            if (snapshot.data is String) {
              return const Center(child: Text("Start a new conversation"));
            }

            chatId = snapshot.data['chatId'];

            return SingleChildScrollView(
              reverse: true,
              child: StreamBuilder<DocumentSnapshot>(
                stream: ChatManager()
                    .getChatStream(chatId: chatId.isEmpty ? null : chatId),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
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
                  DocumentSnapshot doc = snapshot.data as DocumentSnapshot;

                  ConversationModel conversationModel =
                      ConversationModel.fromJson(
                          doc.data() as Map<String, dynamic>);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.11,
                          ),
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: conversationModel.chats.length,
                            itemBuilder: ((context, index) {
                              bool isMe =
                                  conversationModel.chats[index].sender ==
                                      senderId;

                              return FutureBuilder(
                                  future: encryptionKeyManager
                                      .generateDecryptionSecretKey(
                                          isMe: isMe, senderId: senderId, recipientId: recipientId),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String?> snapshot) {
                                    return _buildMessage(
                                        AESGCMEncryption.decryptAESCryptoJS(
                                            conversationModel.chats[index].chat,
                                            snapshot.data ?? ""),
                                        isMe);
                                  });
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
