import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dummy/utils/signal_protocol_setup.dart';
import 'package:dummy/views/chat_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import '../models/local_chat_db/local_conversation_model.dart';
import '../models/signal_protocol_info_model.dart';

GetIt getIt = GetIt.instance;

Future<void> registerDependencies() async {
  //  setup Isar db
  final dir = await getApplicationDocumentsDirectory();
  Isar isar = await Isar.open(
    [LocalConversationModelSchema],
    directory: dir.path,
  );

  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

  // get Signal protocols info
  SignalProtocolInfoModel signalProtocolInfoModel =
  await setupSignalProtocol(userId: senderId);

  getIt.registerSingleton<Isar>(isar);
  getIt.registerSingleton<SignalProtocolInfoModel>(signalProtocolInfoModel);
}
