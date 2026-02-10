import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/telegram_provider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'services/deep_link_service.dart';
import 'screens/notes_list_screen.dart';

// Global navigator key for deep link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const firebaseDatabaseUrl = "https://prime-art-eab7d-default-rtdb.firebaseio.com"; // Replace with your DB URL
  final dbService = DatabaseService(baseUrl: firebaseDatabaseUrl);

  // Initialize deep link handling
  final deepLinkService = DeepLinkService(
    navigatorKey: navigatorKey,
    dbService: dbService,
  );
  deepLinkService.init();

  runApp(MyApp(dbService: dbService));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  const MyApp({required this.dbService, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TelegramProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'GH-Note App',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: NotesListScreen(dbServices: dbService),
          );
        },
      ),
    );
  }
}
