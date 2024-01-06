import 'package:isar/isar.dart';
part 'local_conversation_model.g.dart';

@collection
class LocalConversationModel {
  String? id;
  Id get isarId => fastHash(id!);

  String? message;

  LocalConversationModel copyWith({
    String? id,
    String? message,
  }) {
    return LocalConversationModel()
      ..id = id ?? this.id
      ..message = message ?? this.message;
  }
}

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
