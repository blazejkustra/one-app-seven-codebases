/// A single markdown note.
class Note {
  const Note({
    required this.id,
    required this.body,
    required this.starred,
    required this.updatedAt,
  });

  final String id;
  final String body;
  final bool starred;
  final DateTime updatedAt;

  Note copyWith({String? body, bool? starred, DateTime? updatedAt}) => Note(
    id: id,
    body: body ?? this.body,
    starred: starred ?? this.starred,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'body': body,
    'starred': starred ? 1 : 0,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  static Note fromRow(Map<String, Object?> row) => Note(
    id: row['id']! as String,
    body: row['body']! as String,
    starred: (row['starred']! as int) == 1,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
  );
}

enum SortOrder { updated, title }

/// Theme preference (iteration 5).
enum Appearance { system, light, dark }
