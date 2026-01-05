import 'package:flutter/material.dart';
import 'api_services.dart';

class AddNoteDialog extends StatefulWidget {
  final List<dynamic> existingNotes;

  const AddNoteDialog({super.key, required this.existingNotes});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool isAnalyzing = false;
  bool isCreating = false;
  Map<String, dynamic>? aiSuggestion;

  Future<void> _analyzeNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      isAnalyzing = true;
      aiSuggestion = null;
    });

    try {
      // SAFETY: sanitize existing notes before sending to backend
      final existingNotesMaps = widget.existingNotes.map((note) {
        return {
          "title": (note['title'] ?? "").toString(),
          "summary": (note['summary'] ?? "").toString(),
        };
      }).toList();

      final suggestion = await ApiService.organizeNote(text, existingNotesMaps);

      // SAFETY: force required fields
      aiSuggestion = {
        "action": suggestion["action"] ?? "create",
        "title": suggestion["title"] ?? "New Note",
        "merge_with": suggestion["merge_with"],
        "summary": suggestion["summary"] ?? text,
        "tags": (suggestion["tags"] ?? []).cast<String>(),
        "reasoning":
            suggestion["reasoning"] ?? "AI could not generate reasoning.",
      };

      setState(() => isAnalyzing = false);
    } catch (e) {
      setState(() => isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("AI Error: $e")));
      }
    }
  }

  Future<void> _confirmSuggestion(bool approve) async {
    if (!approve || aiSuggestion == null) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => isCreating = true);

    try {
      await ApiService.createNote(_noteController.text, aiSuggestion!);
      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aiSuggestion!['action'] == 'merge'
                ? 'Note merged successfully'
                : 'Note created successfully',
          ),
        ),
      );
    } catch (e) {
      setState(() => isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving note: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// TOP BAR
            Row(
              children: [
                Icon(Icons.note_add, color: Colors.indigo.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Create New Note',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// INPUT FIELD (before AI)
            if (aiSuggestion == null) ...[
              TextField(
                controller: _noteController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      'Type your note here...\n\nAI will automatically organize it for you.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isAnalyzing ? null : _analyzeNote,
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(isAnalyzing ? 'Analyzing...' : 'Organize with AI'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            /// AI RESULT DISPLAY
            if (aiSuggestion != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.purple.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.indigo.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'AI Suggestion',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    _buildInfoRow(
                      'Action',
                      aiSuggestion!['action'] == 'merge'
                          ? '🔗 Merge with existing note'
                          : '✨ Create new note',
                    ),
                    _buildInfoRow('Title', aiSuggestion!['title']),
                    if (aiSuggestion!['merge_with'] != null)
                      _buildInfoRow(
                        'Merge with',
                        aiSuggestion!['merge_with'] ?? "Unknown",
                      ),
                    _buildInfoRow('Summary', aiSuggestion!['summary']),

                    const SizedBox(height: 8),
                    const Text(
                      'Tags:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E64), // Dark Indigo
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (aiSuggestion!['tags'] as List).map((tag) {
                        return Chip(
                          label: Text(
                            tag.toString(),
                            style: TextStyle(color: Colors.indigo.shade900),
                          ),
                          backgroundColor: Colors.indigo.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiSuggestion!['reasoning'],
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isCreating
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isCreating
                          ? null
                          : () => _confirmSuggestion(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.indigo.shade900)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
