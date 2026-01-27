import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../widgets/note_card.dart';
import 'create_note_screen.dart';

class NotesListScreen extends StatefulWidget {
  final DatabaseService dbServices;

  const NotesListScreen({
    super.key,
    required this.dbServices, required DatabaseService dbService,
  });

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> allNotes = [];
  List<Note> filteredNotes = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final fetchedNotes = await widget.dbServices.getNotes();
    // Sort: Pinned notes first
    fetchedNotes.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return 0; // maintain original order otherwise (creation time usually)
    });
    
    setState(() {
      allNotes = fetchedNotes;
      filteredNotes = fetchedNotes;
      isLoading = false;
    });
  }

  void showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("Halaz Notes"),
        content: Text(
          "• Create notes using +\n"
          "• Long press to delete or pin\n"
          "• Tap to edit\n\n"
          "Creator: Halaz",
        ),
      ),
    );
  }

  // ---------------- SEARCH ----------------
  void searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredNotes = allNotes.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.content.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F9),
      body: CustomScrollView(
        slivers: [
          buildSliverAppBar(),
          buildSearchBarSliver(),
          buildBodySliver(),
        ],
      ),
      floatingActionButton: buildFABs(),
    );
  }

  // ---------------- APP BAR ----------------
  SliverAppBar buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: showInfoDialog,
        ),
        IconButton(
          icon: const Icon(Icons.nightlight_round),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "Teshiet Notes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9D8DF1), Color(0xFFB39DDB)],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget buildSearchBarSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: searchController,
          onChanged: searchNotes,
          decoration: InputDecoration(
            hintText: "Search notes...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- BODY SLIVER ----------------
  Widget buildBodySliver() {
    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredNotes.isEmpty) {
      return SliverFillRemaining(
        child: buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = filteredNotes[index];
            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateNoteScreen(
                      dbService: widget.dbServices,
                      note: note,
                    ),
                  ),
                );
                fetchNotes();
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Note Options", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          "Choose an action for this note",
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PIN ACTION
                        ListTile(
                          leading: const Icon(Icons.push_pin, color: Colors.blue),
                          title: Text(note.pinned ? "Unpin Notes" : "Pin Notes"),
                          onTap: () async {
                            Navigator.pop(context);
                            final updatedNote = Note(
                              id: note.id,
                              title: note.title,
                              content: note.content,
                              color: note.color,
                              tags: note.tags,
                              pinned: !note.pinned,
                            );
                            await widget.dbServices.updateNote(updatedNote);
                            fetchNotes();
                          },
                        ),
                        // EXPORT PDF
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                          title: const Text("Export as PDF"),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Export to PDF feature coming soon!")),
                            );
                          },
                        ),
                        // DELETE ACTION
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text("Delete Note"),
                          onTap: () async {
                            Navigator.pop(context);
                            await widget.dbServices.deleteNote(note.id);
                            fetchNotes();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: NoteCard(note: note),
            );
          },
          childCount: filteredNotes.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3 / 4,
        ),
      ),
    );
  }

  // ---------------- EMPTY STATE ----------------
  Widget buildEmptyState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.note_add_outlined, size: 80, color: Colors.grey),
        SizedBox(height: 20),
        Text(
          "Until now there is no notes/documents",
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          "To create notes click the + button",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // ---------------- FLOATING ACTION BUTTON ----------------
  Widget buildFABs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "info",
          child: const Icon(Icons.info_outline),
          onPressed: showInfoDialog,
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: "add",
          child: const Icon(Icons.add),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CreateNoteScreen(dbService: widget.dbServices),
              ),
            );
            fetchNotes();
          },
        ),
      ],
    );
  }
}
