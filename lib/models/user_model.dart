class UserModel {
  final String publicKey;
  final String privateKey;

  const UserModel({
    required this.publicKey,
    required this.privateKey,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      publicKey: json["publicKey"],
      privateKey: json["privateKey"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "publicKey": this.publicKey,
      "privateKey": this.privateKey,
    };
  }

//
}