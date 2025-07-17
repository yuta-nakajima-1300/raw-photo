import 'package:uuid/uuid.dart';

class EditSession {
  String? id;
  String imageId;
  String sessionName;
  DateTime createdAt;
  DateTime lastModified;
  bool isActive;

  EditSession({
    this.id,
    required this.imageId,
    required this.sessionName,
    required this.createdAt,
    required this.lastModified,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_id': imageId,
      'session_name': sessionName,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory EditSession.fromMap(Map<String, dynamic> map) {
    return EditSession(
      id: map['id'],
      imageId: map['image_id'],
      sessionName: map['session_name'],
      createdAt: DateTime.parse(map['created_at']),
      lastModified: DateTime.parse(map['last_modified']),
      isActive: map['is_active'] == 1,
    );
  }

  EditSession copyWith({
    String? id,
    String? imageId,
    String? sessionName,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isActive,
  }) {
    return EditSession(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      sessionName: sessionName ?? this.sessionName,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedDuration {
    final duration = lastModified.difference(createdAt);
    if (duration.inDays > 0) {
      return '${duration.inDays}日間';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分間';
    } else {
      return '${duration.inSeconds}秒間';
    }
  }
}