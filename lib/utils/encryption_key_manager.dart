// import 'dart:convert';
// import 'dart:developer';
//
// import 'package:better_cryptography/better_cryptography.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:cryptography/cryptography.dart';
// // import 'package:cryptography_flutter/cryptography_flutter.dart';
// import 'package:diffie_hellman/diffie_hellman.dart';
// import 'package:dummy/firebase_chat/chat_manager.dart';
// import 'package:dummy/models/user_model.dart';
// import 'package:dummy/utils/aes_gcm_encryption.dart';
//
// class EncryptionKeyManager {
//   final CollectionReference _users =
//       FirebaseFirestore.instance.collection("users");
//
//   final String _userId = "1";
//   final DhPkcs3Engine _dhEngine = DhPkcs3Engine.fromGroup(15);
//   Ecdh algorithm = Ecdh.p256(length: 256);
//
//   // example user password
//   String userPassword = "password123";
//
//   // update the encryption keys of the user in firebase
//   Future updateEncryptionKey() async {
//     // generate the encryption keys with Diffie-hellman
//
//     // check if the user already has a public key, and set one
//     UserModel? userKeys = await ChatManager.getUserKeyPair(userId: _userId);
//
//     // log("KEYPAIR DATA: $keyPairData");
//
//     EcKeyPair algorithmKeyPair = await algorithm.newKeyPair();
//     EcKeyPairData thePrivateKey = await algorithmKeyPair.extract();
//     EcPublicKey thePublicKey = await algorithmKeyPair.extractPublicKey();
//
//     String pubKey = base64Encode(thePublicKey);
//     String privKey = base64Encode(thePrivateKey.toDer());
//
//     log('Public Key: $pubKey');
//     log('Private Key: $privKey');
//
//
//     // print('Public Key: ${algorithmKeyPair.extractPublicKey()}');
//
//     // only generate a key pair if the user does not have one
//     if (userKeys == null) {
//       // DhKeyPair keyPair = _dhEngine.generateKeyPair();
//
//
//
//       EcKeyPair algorithmKeyPair = await algorithm.newKeyPair();
//       EcKeyPairData thePrivateKey = await algorithmKeyPair.extract();
//       EcPublicKey thePublicKey = await algorithmKeyPair.extractPublicKey();
//
//       String pubKey = base64Encode(thePublicKey.toDer());
//       String privKey = base64Encode(thePrivateKey.toDer());
//
//
//
//       // print('Public Key: ${keyPair.publicKey}');
//       // print('Private Key: ${keyPair.privateKey}');
//
//       print('Public Key: ${pubKey}');
//       print('Private Key: ${privKey}');
//
//
//       // store the user's public key and private key in firebase with the former being encrypted with the user's password
//       // await _users.doc(_userId).set({
//       //   "publicKey": keyPair.publicKey.toString(),
//       //   "privateKey": AESGCMEncryption.encryptAESCryptoJS(
//       //       keyPair.privateKey.toString(), userPassword)
//       // });
//     } else {
//       // _dhEngine.setPrivateKey = BigInt.parse(
//       //     AESGCMEncryption.decryptAESCryptoJS(
//       //         userKeys.privateKey, userPassword));
//     }
//   }
//
//   // generate a shared secret key used to encrypt the message with
//   String generateEncryptionSecretKey({required String recipientPublicKey}) {
//
//     String secretKey =
//         _dhEngine.computeSecretKey(BigInt.parse(recipientPublicKey)).toString();
//
//     log("Encryption secret key: $secretKey");
//
//     return secretKey.toString();
//   }
//
//   // Generate the key that would be used to decrypt the chat messages
//   Future<String> generateDecryptionSecretKey(
//       {bool isMe = false,
//       required String senderId,
//       required String recipientId}) async {
//     // get the public key of the recipient of the message
//     UserModel? userKeyPair =
//         await ChatManager.getUserKeyPair(userId: isMe ? recipientId : senderId);
//
//     if (userKeyPair == null) {
//       return "";
//     }
//
//     BigInt publicKey = BigInt.parse(userKeyPair.publicKey);
//
//     String secretKey = _dhEngine.computeSecretKey(publicKey).toString();
//
//     log("Decryption SECRET KEY: $secretKey");
//
//     return secretKey;
//   }
// }
