import 'dart:convert';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class SignalProtocolInfoModel {
  final IdentityKeyPair identityKeyPair;
  final List<PreKeyRecord> preKeys;
  final SignedPreKeyRecord signedPreKeyRecord;
  final int registrationId;
  final int deviceId;
  final String phoneNumber;

  Map<String, dynamic> toPublicInfoMap() {
    return {
      "identityPublicKey":
          jsonEncode(identityKeyPair.getPublicKey().serialize()),
      "registrationId": registrationId.toString(),
      "signedPreKeyPublic": jsonEncode(
          base64.encode(signedPreKeyRecord.getKeyPair().publicKey.serialize())),
      "signedPreKeySignature":
          jsonEncode(base64.encode(signedPreKeyRecord.signature)),
      "deviceId": deviceId,
      "signedPreKeyId": signedPreKeyRecord.id.toString(),
      "phoneNumber": phoneNumber,
      "preKeys": jsonEncode(preKeys.map((e) => jsonEncode(e.serialize())).toList())
    };
  }

//<editor-fold desc="Data Methods">
  const SignalProtocolInfoModel({
    required this.identityKeyPair,
    required this.preKeys,
    required this.signedPreKeyRecord,
    required this.registrationId,
    required this.deviceId,
    required this.phoneNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalProtocolInfoModel &&
          runtimeType == other.runtimeType &&
          identityKeyPair == other.identityKeyPair &&
          preKeys == other.preKeys &&
          signedPreKeyRecord == other.signedPreKeyRecord &&
          registrationId == other.registrationId &&
          deviceId == other.deviceId &&
          phoneNumber == other.phoneNumber);

  @override
  int get hashCode =>
      identityKeyPair.hashCode ^
      preKeys.hashCode ^
      signedPreKeyRecord.hashCode ^
      registrationId.hashCode ^
      deviceId.hashCode ^
      phoneNumber.hashCode;

  @override
  String toString() {
    return 'SignalProtocolInfoModel{' +
        ' identityKeyPair: $identityKeyPair,' +
        ' preKeys: $preKeys,' +
        ' signedPreKeyRecord: $signedPreKeyRecord,' +
        ' registrationId: $registrationId,' +
        ' deviceId: $deviceId,' +
        ' phoneNumber: $phoneNumber,' +
        '}';
  }

  SignalProtocolInfoModel copyWith({
    IdentityKeyPair? identityKeyPair,
    List<PreKeyRecord>? preKeys,
    SignedPreKeyRecord? signedPreKeyRecord,
    int? registrationId,
    int? deviceId,
    String? phoneNumber,
  }) {
    return SignalProtocolInfoModel(
      identityKeyPair: identityKeyPair ?? this.identityKeyPair,
      preKeys: preKeys ?? this.preKeys,
      signedPreKeyRecord: signedPreKeyRecord ?? this.signedPreKeyRecord,
      registrationId: registrationId ?? this.registrationId,
      deviceId: deviceId ?? this.deviceId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identityKeyPair': this.identityKeyPair,
      'preKeys': this.preKeys,
      'signedPreKeyRecord': this.signedPreKeyRecord,
      'registrationId': this.registrationId,
      'deviceId': this.deviceId,
      'phoneNumber': this.phoneNumber,
    };
  }

  factory SignalProtocolInfoModel.fromMap(Map<String, dynamic> map) {
    return SignalProtocolInfoModel(
      identityKeyPair: map['identityKeyPair'] as IdentityKeyPair,
      preKeys: map['preKeys'] as List<PreKeyRecord>,
      signedPreKeyRecord: map['signedPreKeyRecord'] as SignedPreKeyRecord,
      registrationId: map['registrationId'] as int,
      deviceId: map['deviceId'] as int,
      phoneNumber: map['phoneNumber'] as String,
    );
  }

//</editor-fold>
}
