import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/note.dart';

class DatabaseService {
  final String baseUrl;

  DatabaseService({required this.baseUrl});

  
  Future<void> addNote(Note note) async {
    final url = Uri.parse('$baseUrl/notes.json');
    final res = await http.post(url, body: jsonEncode(note.toMap()));
    if (res.statusCode != 200) {
      throw Exception('Failed to add note');
    } else {
      await sendTelegramNotification(note);
    }
  }

  Future<void> sendTelegramNotification(Note note) async {
    String serverUrl;
    if (kIsWeb) {
      // For Web, use localhost
      serverUrl = 'http://localhost:3000/notify';
    } else {
      // For Android Emulator, use 10.0.2.2
      // If you are on a physical device, you need your computer's LAN IP (e.g., 192.168.1.x)
      serverUrl = 'http://10.0.2.2:3000/notify';
    }

    final url = Uri.parse(serverUrl);
    
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': note.title,
          'content': note.content,
        }),
      );
      print("Notification sent to backend");
    } catch (e) {
      print("Failed to send notification to backend: $e");
    }
  }


  Future<List<Note>> getNotes() async {
    final url = Uri.parse('$baseUrl/notes.json');
    final res = await http.get(url);
    if (res.statusCode == 200 && res.body != 'null') {
      Map<String, dynamic> data = jsonDecode(res.body);
      List<Note> notes = [];
      data.forEach((key, value) {
        notes.add(Note.fromMap(key, value));
      });
      return notes;
    }
    return [];
  }

  
  Future<void> deleteNote(String noteId) async {
    final url = Uri.parse('$baseUrl/notes/$noteId.json');
    await http.delete(url);
  }

  
  Future<void> updateNote(Note note) async {
    final url = Uri.parse('$baseUrl/notes/${note.id}.json');
    await http.put(url, body: jsonEncode(note.toMap()));
  }
}
