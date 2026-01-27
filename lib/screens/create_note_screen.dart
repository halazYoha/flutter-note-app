import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class CreateNoteScreen extends StatefulWidget {
  final DatabaseService dbService;
  final Note? note;

  const CreateNoteScreen({
    super.key,
    required this.dbService,
    this.note,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  final tagController = TextEditingController();

  Color selectedColor = const Color(0xFF4CAF50);
  List<String> tags = [];

  final List<Color> noteColors = const [
    Color(0xFF4CAF50), // green
    Color(0xFF2196F3), // blue
    Color(0xFFFF9800), // orange
    Color(0xFFF44336), // red
    Color(0xFF9C27B0), // purple
    Color(0xFF00BCD4), // cyan
    Color(0xFFFFC107), // amber
    Color(0xFF795548), // brown
    Color(0xFF607D8B), // blue grey
    Color(0xFF3F51B5), // indigo
  ];

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      titleController = TextEditingController(text: widget.note!.title);
      contentController = TextEditingController(text: widget.note!.content);
      selectedColor = Color(widget.note!.color);
      tags = List.from(widget.note!.tags);
    } else {
      titleController = TextEditingController();
      contentController = TextEditingController();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    tagController.dispose();
    super.dispose();
  }

  Future<void> saveNote() async {
    if (titleController.text.trim().isEmpty &&
        contentController.text.trim().isEmpty) {
      return;
    }

    setState(() => isSaving = true);

    final newNote = Note(
      id: widget.note?.id ?? '',
      title: titleController.text.trim().isEmpty
          ? "Title"
          : titleController.text.trim(),
      content: contentController.text.trim(),
      color: selectedColor.value,
      tags: tags,
      pinned: widget.note?.pinned ?? false,
    );

    if (widget.note != null) {
      await widget.dbService.updateNote(newNote);
    } else {
      await widget.dbService.addNote(newNote);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  void addTag() {
    final tag = tagController.text.trim();
    if (tag.isNotEmpty && !tags.contains(tag)) {
      setState(() {
        tags.add(tag);
        tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F9),

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text("New Note"),
        actions: [
          TextButton.icon(
            onPressed: null,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text("Export as PDF"),
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITLE
            TextField(
              controller: titleController,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Title",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Created just now",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // CONTENT
            TextField(
              controller: contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Start typing your Notes...",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 28),

            // NOTE COLOR PICKER
            const Text(
              "Note Color",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: noteColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final color = noteColors[index];
                  final isSelected = selectedColor == color;

                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(width: 4, color: Colors.grey)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // TAGS
            Row(
              children: const [
                Text(
                  "Tags",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 6),
                Icon(Icons.sell_outlined, size: 18),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagController,
                    decoration: InputDecoration(
                      hintText: "Add a tag...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: addTag,
                    child: const Icon(Icons.check),
                  ),
                ),
              ],
            ),

            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => tags.remove(tag));
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A5AE0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        "Save Note",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
