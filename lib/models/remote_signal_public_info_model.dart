import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class RemoteSignalPublicInfoModel {
  final IdentityKey identityKey;
  final ECPublicKey signedPublicPreKey;
  final Uint8List signedPreKeySignature;
  final List<PreKeyRecord> preKeys;
  final int signedPreKeyRecordId;
  final int registrationId;
  final String deviceId;

//<editor-fold desc="Data Methods">

  const RemoteSignalPublicInfoModel({
    required this.identityKey,
    required this.signedPublicPreKey,
    required this.signedPreKeySignature,
    required this.preKeys,
    required this.signedPreKeyRecordId,
    required this.registrationId,
    required this.deviceId,
  });

// fa@override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteSignalPublicInfoModel &&
          runtimeType == other.runtimeType &&
          identityKey == other.identityKey &&
          signedPublicPreKey == other.signedPublicPreKey &&
          signedPreKeySignature == other.signedPreKeySignature &&
          preKeys == other.preKeys &&
          signedPreKeyRecordId == other.signedPreKeyRecordId &&
          registrationId == other.registrationId &&
          deviceId == other.deviceId);

  @override
  int get hashCode =>
      identityKey.hashCode ^
      signedPublicPreKey.hashCode ^
      signedPreKeySignature.hashCode ^
      preKeys.hashCode ^
      signedPreKeyRecordId.hashCode ^
      registrationId.hashCode ^
      deviceId.hashCode;

  @override
  String toString() {
    return 'RemoteSignalPublicInfoModel{' +
        ' identityKey: $identityKey,' +
        ' signedPublicPreKey: $signedPublicPreKey,' +
        ' signedPreKeySignature: $signedPreKeySignature,' +
        ' preKeys: $preKeys,' +
        ' signedPreKeyRecordId: $signedPreKeyRecordId,' +
        ' registrationId: $registrationId,' +
        ' deviceId: $deviceId,' +
        '}';
  }

  RemoteSignalPublicInfoModel copyWith({
    IdentityKey? identityKey,
    ECPublicKey? signedPublicPreKey,
    Uint8List? signedPreKeySignature,
    List<PreKeyRecord>? preKeys,
    int? signedPreKeyRecordId,
    int? registrationId,
    String? deviceId,
  }) {
    return RemoteSignalPublicInfoModel(
      identityKey: identityKey ?? this.identityKey,
      signedPublicPreKey: signedPublicPreKey ?? this.signedPublicPreKey,
      signedPreKeySignature:
          signedPreKeySignature ?? this.signedPreKeySignature,
      preKeys: preKeys ?? this.preKeys,
      signedPreKeyRecordId: signedPreKeyRecordId ?? this.signedPreKeyRecordId,
      registrationId: registrationId ?? this.registrationId,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identityKey': this.identityKey,
      'signedPublicPreKey': this.signedPublicPreKey,
      'signedPreKeySignature': this.signedPreKeySignature,
      'preKeys': this.preKeys,
      'signedPreKeyRecordId': this.signedPreKeyRecordId,
      'registrationId': this.registrationId,
      'deviceId': this.deviceId,
    };
  }

  factory RemoteSignalPublicInfoModel.fromMap(Map<String, dynamic> map) {
    return RemoteSignalPublicInfoModel(
        identityKey: IdentityKey.fromBytes(
            Uint8List.fromList(
                List<int>.from(jsonDecode(map['identityPublicKey']))),
            0),
        signedPublicPreKey: Curve.decodePointList(
            List<int>.from(base64.decode(jsonDecode(map['signedPreKeyPublic']))), 0),
        signedPreKeySignature: Uint8List.fromList(
            List<int>.from(base64Decode(jsonDecode(map['signedPreKeySignature'])))),
        preKeys: jsonDecode(map['preKeys']).map<PreKeyRecord>((element) =>
            PreKeyRecord.fromBuffer(
                Uint8List.fromList(List<int>.from(jsonDecode(element))))).toList(),
        signedPreKeyRecordId: int.parse(map['signedPreKeyId']),
        registrationId: int.parse(map['registrationId']),
        deviceId: map['deviceId']);
  }

  //</editor-fold>
}
