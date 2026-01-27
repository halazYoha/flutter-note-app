import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'screens/notes_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const firebaseDatabaseUrl = "https://prime-art-eab7d-default-rtdb.firebaseio.com"; // Replace with your DB URL
  final dbService = DatabaseService(baseUrl: firebaseDatabaseUrl);

  runApp(MyApp(dbService: dbService));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  const MyApp({required this.dbService, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NotesListScreen(dbService: dbService,dbServices: dbService,),
    );
  }
}
