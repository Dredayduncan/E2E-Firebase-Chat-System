import 'dart:convert';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class SignalProtocolInfoModel {
  final IdentityKeyPair identityKeyPair;
  final List<PreKeyRecord> preKeys;
  final SignedPreKeyRecord signedPreKeyRecord;
  final int registrationId;

//<editor-fold desc="Data Methods">
  const SignalProtocolInfoModel({
    required this.identityKeyPair,
    required this.preKeys,
    required this.signedPreKeyRecord,
    required this.registrationId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalProtocolInfoModel &&
          runtimeType == other.runtimeType &&
          identityKeyPair == other.identityKeyPair &&
          preKeys == other.preKeys &&
          signedPreKeyRecord == other.signedPreKeyRecord &&
          registrationId == other.registrationId);

  @override
  int get hashCode =>
      identityKeyPair.hashCode ^
      preKeys.hashCode ^
      signedPreKeyRecord.hashCode ^
      registrationId.hashCode;

  @override
  String toString() {
    return 'SignalProtocolInfoModel{ identityKeyPair: $identityKeyPair, prekeys: $preKeys, signedPreKeyRecord: $signedPreKeyRecord, registrationId: $registrationId,}';
  }

  SignalProtocolInfoModel copyWith({
    IdentityKeyPair? identityKeyPair,
    List<PreKeyRecord>? prekeys,
    SignedPreKeyRecord? signedPreKeyRecord,
    int? registrationId,
  }) {
    return SignalProtocolInfoModel(
      identityKeyPair: identityKeyPair ?? this.identityKeyPair,
      preKeys: prekeys ?? this.preKeys,
      signedPreKeyRecord: signedPreKeyRecord ?? this.signedPreKeyRecord,
      registrationId: registrationId ?? this.registrationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identityKeyPair': this.identityKeyPair,
      'prekeys': this.preKeys,
      'signedPreKeyRecord': this.signedPreKeyRecord,
      'registrationId': this.registrationId,
    };
  }

  factory SignalProtocolInfoModel.fromRemoteMap(Map<String, dynamic> map) {
    return SignalProtocolInfoModel(
      identityKeyPair: map['identityKeyPair'] as IdentityKeyPair,
      preKeys: map['prekeys'] as List<PreKeyRecord>,
      signedPreKeyRecord: map['signedPreKeyRecord'] as SignedPreKeyRecord,
      registrationId: int.parse(map['registrationId']),
    );
  }

  Map<String, dynamic> toPublicInfoMap() {
    return {
      "identityPublicKey":
          jsonEncode(identityKeyPair.getPublicKey().serialize()),
      "registrationId": registrationId.toString(),
      "signedPreKeyPublic": jsonEncode(
          base64.encode(signedPreKeyRecord.getKeyPair().publicKey.serialize())),
      "signedPreKeySignature":
          jsonEncode(base64.encode(signedPreKeyRecord.signature)),
      "signedPreKeyId": signedPreKeyRecord.id.toString(),
      "preKeys": jsonEncode(preKeys.map((e) => jsonEncode(e.serialize())).toList())
    };
  }

//</editor-fold>
}
