class Note {
  String id; 
  String title;
  String content;
  int color;
  List<String> tags;
  bool pinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.color = 0xFFFFFFFF,
    this.tags = const [],
    this.pinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'color': color,
      'tags': tags,
      'pinned': pinned,
    };
  }

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      color: map['color'] ?? 0xFFFFFFFF,
      tags: List<String>.from(map['tags'] ?? []),
      pinned: map['pinned'] ?? false,
    );
  }
}
