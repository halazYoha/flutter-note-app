import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    // Handle app scheme deep links: noteapp://note/<noteId>
    if (uri.scheme == 'noteapp' && uri.host == 'note' && uri.pathSegments.isNotEmpty) {
      final noteId = uri.pathSegments.first;
      _openNote(noteId);
    }
    // Handle Play Store referrer: note_<noteId>
    else if (uri.scheme == 'https' && uri.host == 'play.google.com') {
      final referrer = uri.queryParameters['referrer'];
      if (referrer != null && referrer.startsWith('note_')) {
        final noteId = referrer.substring(5); // Remove 'note_' prefix
        _openNote(noteId);
      }
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
      } else {
        debugPrint('Note not found: $noteId');
        _showErrorSnackBar('Note not found');
      }
    } catch (e) {
      debugPrint('Error opening note from deep link: $e');
      _showErrorSnackBar('Failed to open note');
    }
  }

  void _showErrorSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
