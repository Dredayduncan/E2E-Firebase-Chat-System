import 'dart:io';
import 'package:dummy/utils/main_setup.dart';
import 'package:dummy/views/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// sender as current user
String senderId = "1";
String recipientId = "2";
String userPhoneNumber = "+233123456789";

// recipient as current user
// final String senderId = "2";
// final String recipientId = "1";
// final String senderPhone = "+233123456798";
// final String recipientPhone = "+233123456789";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // name: "Dummy",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (Platform.isAndroid){
    senderId = "2";
    recipientId = "1";
    userPhoneNumber = "+233123456798";
  }

  // check if app supports biometrics
  await registerDependencies();
  await getIt.allReady();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E2E Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
