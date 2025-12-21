import 'package:flutter/material.dart';
import 'api_services.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Map<String, dynamic>? note;
  bool isLoading = true;
  bool isEditing = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final List<TextEditingController> _tagControllers = [];

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() => isLoading = true);

    try {
      final fetchedNote = await ApiService.getNote(widget.noteId);

      // SAFETY: fallback defaults
      fetchedNote["title"] ??= "Untitled Note";
      fetchedNote["summary"] ??= "No summary available.";
      fetchedNote["tags"] ??= [];
      fetchedNote["content"] ??= [];
      fetchedNote["created_at"] ??= "";
      fetchedNote["updated_at"] ??= "";

      setState(() {
        note = fetchedNote;
        isLoading = false;
      });
    } catch (e) {
      isLoading = false;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading note: $e")));
      }
      setState(() {});
    }
  }

  void _startEditing() {
    if (note == null) return;

    _titleController.text = (note!['title'] ?? "Untitled").toString();
    _summaryController.text = (note!['summary'] ?? "").toString();

    _tagControllers.clear();
    for (var tag in (note!['tags'] ?? [])) {
      _tagControllers.add(TextEditingController(text: tag.toString()));
    }

    setState(() => isEditing = true);
  }

  Future<void> _saveChanges() async {
    if (note == null) return;

    final tags = _tagControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    try {
      await ApiService.updateNote(widget.noteId, {
        'title': _titleController.text.isEmpty
            ? "Untitled Note"
            : _titleController.text,
        'summary': _summaryController.text,
        'tags': tags,
      });

      await _loadNote();
      setState(() => isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating note: $e')));
      }
    }
  }

  void _cancelEditing() {
    setState(() => isEditing = false);
    _titleController.clear();
    _summaryController.clear();
    for (var c in _tagControllers) {
      c.dispose();
    }
    _tagControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          if (!isEditing && !isLoading)
            IconButton(icon: const Icon(Icons.edit), onPressed: _startEditing),
          if (isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEditing,
            ),
            IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : note == null
          ? const Center(child: Text("Note not found"))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final safeNote = note!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---------- TITLE ----------
          if (isEditing)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            )
          else
            Text(
              safeNote['title'] ?? "Untitled Note",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

          const SizedBox(height: 24),

          /// ---------- SUMMARY ----------
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize, color: Colors.indigo.shade600),
                      const SizedBox(width: 8),
                      Text(
                        "Summary",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isEditing
                      ? TextField(
                          controller: _summaryController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Text(
                          safeNote['summary'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// ---------- TAGS ----------
          Row(
            children: [
              Icon(Icons.label, color: Colors.purple.shade600),
              const SizedBox(width: 8),
              const Text(
                'Tags',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isEditing ? _buildEditTags() : _buildTagChips(),

          const SizedBox(height: 24),

          /// ---------- CONTENT ----------
          Row(
            children: [
              Icon(Icons.notes, color: Colors.indigo.shade600),
              const SizedBox(width: 8),
              const Text(
                "Content Entries",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildContentCards(),

          const SizedBox(height: 24),

          /// ---------- METADATA ----------
          _buildMetadataCard(),
        ],
      ),
    );
  }

  Widget _buildEditTags() {
    return Column(
      children: [
        ...List.generate(_tagControllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagControllers[i],
                    decoration: InputDecoration(
                      labelText: "Tag ${i + 1}",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () {
                    setState(() {
                      _tagControllers[i].dispose();
                      _tagControllers.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          );
        }),

        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Tag"),
          onPressed: () {
            setState(() {
              _tagControllers.add(TextEditingController());
            });
          },
        ),
      ],
    );
  }

  Widget _buildTagChips() {
    final tags = (note!['tags'] ?? []) as List;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Chip(
          label: Text(
            tag.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple.shade700,
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  List<Widget> _buildContentCards() {
    final contentList = (note!['content'] ?? []) as List;

    return contentList.map((content) {
      final text = content['text'] ?? "";
      final dateStr = content['added_at'] ?? "";

      DateTime dt;
      try {
        dt = DateTime.parse(dateStr);
      } catch (_) {
        dt = DateTime.now();
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMetadataCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  "Metadata",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildMetadataRow(
              'Created',
              _safeFormatDate(note!['created_at'] ?? ""),
            ),
            _buildMetadataRow(
              'Updated',
              _safeFormatDate(note!['updated_at'] ?? ""),
            ),
            _buildMetadataRow('Entries', "${(note!['content'] ?? []).length}"),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          Text(value, style: TextStyle(color: Colors.blue.shade900)),
        ],
      ),
    );
  }

  String _safeFormatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "Unknown";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    for (var c in _tagControllers) {
      c.dispose();
    }
    super.dispose();
  }
}















































































