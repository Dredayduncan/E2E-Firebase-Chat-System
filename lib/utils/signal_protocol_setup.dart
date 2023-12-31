// Get the current user's signal protocol credentials if the user has one.
// If the user doesn't have one, create one and store it in their firebase document
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dummy/main.dart';
import 'package:dummy/models/local_chat_db/local_conversation_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../firebase_chat/chat_manager.dart';
import '../models/signal_protocol_info_model.dart';

Future<SignalProtocolInfoModel> setupSignalProtocol(
    {required String userId}) async {
  // Create storage
  const storage = FlutterSecureStorage();

  // await storage.deleteAll();

  // get the stored identity key pair
  String? storedKeyPair = await storage.read(key: "identityKeyPair");
  String? storedPreKeys = await storage.read(key: "preKeys");
  String? storedRegistrationId = await storage.read(key: "registrationId");
  String? storedSignedPreKeyRecord =
      await storage.read(key: "signedPreKeyRecord");

  // get deviceId
  final deviceInfo = DeviceInfoPlugin();

  String deviceId = "";

  if (Platform.isIOS) {
    // import 'dart:io'
    var iosDeviceInfo = await deviceInfo.iosInfo;
    deviceId = iosDeviceInfo.identifierForVendor ?? ""; // unique ID on iOS
  } else if (Platform.isAndroid) {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    deviceId = androidDeviceInfo.id; // unique ID on Android
  }

  // use the fast hash to hash the deviceId to an int value
  int hashedDeviceId = fastHash(deviceId);

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
        deviceId: hashedDeviceId,
        phoneNumber: userPhoneNumber,
        signedPreKeyRecord: signedPreKeyRecord,
        registrationId: registrationId);
  }

  // create new signal protocol credentials
  IdentityKeyPair identityKeyPair = generateIdentityKeyPair();

  final int registrationId = generateRegistrationId(false);

  final List<PreKeyRecord> preKeys = generatePreKeys(0, 100);

  final SignedPreKeyRecord signedPreKeyRecord =
      generateSignedPreKey(identityKeyPair, 1);

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

  // create the signal protocol model
  SignalProtocolInfoModel signalProtocolInfoModel = SignalProtocolInfoModel(
      identityKeyPair: identityKeyPair,
      preKeys: preKeys,
      phoneNumber: userPhoneNumber,
      signedPreKeyRecord: signedPreKeyRecord,
      deviceId: hashedDeviceId,
      registrationId: registrationId);

  // send the credentials to the server
  await ChatManager.storeLocalUserSignalInfo(
      userId: userId,
      publicSignalInfo: signalProtocolInfoModel.toPublicInfoMap());

  return signalProtocolInfoModel;
}
