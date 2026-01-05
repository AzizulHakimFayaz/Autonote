import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'add_note_dialoge.dart'; // Retaining for reference, though parent handles FAB currently.
import 'api_services.dart';
import 'note_detail_screen.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  List<dynamic> notes = [];
  List<dynamic> filteredNotes = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => isLoading = true);
    try {
      final fetchedNotes = await ApiService.getAllNotes();
      if (mounted) {
        setState(() {
          notes = fetchedNotes;
          filteredNotes = fetchedNotes;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        // Using context safely
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
      }
    }
  }

  void _filterNotes(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredNotes = notes;
      } else {
        filteredNotes = notes.where((note) {
          final title = (note['title'] ?? "").toString().toLowerCase();
          final summary = (note['summary'] ?? "").toString().toLowerCase();
          final tags = ((note['tags'] ?? []) as List).join(' ').toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) ||
              summary.contains(searchLower) ||
              tags.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteNote(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteNote(noteId);
        _loadNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed Scaffold, returning Container/SafeArea directly
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Ensure matches theme
      child: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Notes',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access and manage all your intelligent notes',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search notes, tags, or content...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterNotes('');
                          },
                        )
                      : null,
                ),
                onChanged: _filterNotes,
              ),
            ),

            const SizedBox(height: 24),

            /// COUNT & REFRESH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Notes (${filteredNotes.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _loadNotes,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// NOTES LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNotes.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return _buildNoteCard(note);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No notes yet' : 'No notes found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap the + button to create your first note'
                : 'Try a different search query',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// ---------- NOTE CARD (With new Dark Theme) ----------
  Widget _buildNoteCard(Map<String, dynamic> note) {
    final title = (note['title'] ?? "Untitled").toString();
    final summary = (note['summary'] ?? "No summary").toString();
    final tags = (note['tags'] ?? []) as List;
    final content = (note['content'] ?? []) as List;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
        (note['created_at'] ?? DateTime.now().toString()),
      );
    } catch (_) {
      createdAt = DateTime.now();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E2025), // Explicit dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(noteId: note['id']),
            ),
          );
          if (result == true) _loadNotes();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    color: const Color(0xFF2A2D35),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteNote(note['id']);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                summary,
                style: TextStyle(color: Colors.grey.shade400, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.take(4).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9FA8DA),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.notes, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${content.length} ${content.length == 1 ? 'entry' : 'entries'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
