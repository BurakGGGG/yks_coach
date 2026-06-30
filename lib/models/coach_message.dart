import 'package:flutter/foundation.dart';

/// One message in the YKS coach conversation, stored under
/// `users/{uid}/coachMessages`.
@immutable
class CoachMessage {
  const CoachMessage({
    this.id = '',
    required this.text,
    required this.fromUser,
    required this.createdAt,
    this.conversationId = 'main',
  });

  final String id;
  final String text;
  final bool fromUser;
  final DateTime createdAt;
  final String conversationId;

  CoachMessage copyWith({String? id}) => CoachMessage(
    id: id ?? this.id,
    text: text,
    fromUser: fromUser,
    createdAt: createdAt,
    conversationId: conversationId,
  );

  Map<String, Object?> toMap() => {
    'text': text,
    'fromUser': fromUser,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'conversationId': conversationId,
  };

  factory CoachMessage.fromMap(String id, Map<String, dynamic> map) =>
      CoachMessage(
        id: id,
        text: map['text'] as String? ?? '',
        fromUser: map['fromUser'] as bool? ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ??
              (map['time'] as num?)?.toInt() ??
              0,
        ),
        conversationId: map['conversationId'] as String? ?? 'main',
      );
}
