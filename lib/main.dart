import 'package:dummy/models/signal_protocol_info_model.dart';
import 'package:dummy/utils/signal_protocol_setup.dart';
import 'package:dummy/views/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';


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
      home: ChatScreen(
        signalProtocolInfoModel: signalProtocolInfoModel,
      ),
    );
  }
}