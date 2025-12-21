import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // ---------- AI Organize ----------
  static Future<Map<String, dynamic>> organizeNote(
      String text, List<Map<String, dynamic>> existing) async {
    final r = await http.post(
      Uri.parse("$baseUrl/api/notes/organize"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"note_text": text, "existing_notes": existing}),
    );

    final json = jsonDecode(r.body);

    if (!json.containsKey("action")) {
      throw Exception("AI returned invalid JSON.\n${json.toString()}");
    }

    return json;
  }

  // ---------- Create or Merge ----------
  static Future<Map<String, dynamic>> createNote(
      String text, Map<String, dynamic> suggestion) async {
    final r = await http.post(
      Uri.parse("$baseUrl/api/notes"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"note_text": text, "ai_suggestion": suggestion}),
    );

    return jsonDecode(r.body);
  }

  // ---------- Read All ----------
  static Future<List<dynamic>> getAllNotes() async {
    final r = await http.get(Uri.parse("$baseUrl/api/notes"));
    return jsonDecode(r.body);
  }

  // ---------- Read One ----------
  static Future<Map<String, dynamic>> getNote(String id) async {
    final r = await http.get(Uri.parse("$baseUrl/api/notes/$id"));
    return jsonDecode(r.body);
  }

  // ---------- Update ----------
  static Future<Map<String, dynamic>> updateNote(
      String id, Map<String, dynamic> data) async {
    final r = await http.put(
      Uri.parse("$baseUrl/api/notes/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(r.body)["note"];
  }

  // ---------- Delete ----------
  static Future<void> deleteNote(String id) async {
    await http.delete(Uri.parse("$baseUrl/api/notes/$id"));
  }
}
