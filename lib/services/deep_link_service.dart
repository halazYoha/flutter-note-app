import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../screens/create_note_screen.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey;
  final DatabaseService dbService;

  DeepLinkService({
    required this.navigatorKey,
    required this.dbService,
  });

  /// Initialize deep link handling — call once from main()
  Future<void> init() async {
    // Handle link that launched the app (cold start)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle links while app is running (warm start)
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Expected format: noteapp://note/<noteId>
    if (uri.scheme == 'noteapp' && uri.host == 'note' && uri.pathSegments.isNotEmpty) {
      final noteId = uri.pathSegments.first;
      _openNote(noteId);
    }
  }

  Future<void> _openNote(String noteId) async {
    try {
      final note = await dbService.getNoteById(noteId);
      if (note != null) {
        // Wait for navigator to be ready
        await Future.delayed(const Duration(milliseconds: 500));
        
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => CreateNoteScreen(
                dbService: dbService,
                note: note,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening note from deep link: $e');
    }
  }
}
