import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../screens/notes_list_screen.dart';

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
      _navigateToNotesList();
    }
    // Handle Play Store referrer: note_<noteId>
    else if (uri.scheme == 'https' && uri.host == 'play.google.com') {
      final referrer = uri.queryParameters['referrer'];
      if (referrer != null && referrer.startsWith('note_')) {
        _navigateToNotesList();
      }
    }
  }

  /// Navigate to the Notes List screen when a deep link is received
  Future<void> _navigateToNotesList() async {
    try {
      // Wait for navigator to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        // Pop all routes and go to root (Notes List Screen)
        navigator.popUntil((route) => route.isFirst);

        // Show a snackbar to indicate the app was opened from a shared link
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opened from a shared note link'),
              backgroundColor: Color(0xFF6A5AE0),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      _showErrorSnackBar('Failed to open the app from link');
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
