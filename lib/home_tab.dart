import 'package:flutter/material.dart';
import 'api_services.dart';
import 'note_detail_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onSearch;

  const HomeTab({super.key, this.onSearch});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> recentNotes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    try {
      final allNotes = await ApiService.getAllNotes();

      // Sort by created_at descending (newest first)
      allNotes.sort((a, b) {
        DateTime dateA;
        DateTime dateB;
        try {
          dateA = DateTime.parse(a['created_at'] ?? DateTime.now().toString());
        } catch (_) {
          dateA = DateTime.now();
        }
        try {
          dateB = DateTime.parse(b['created_at'] ?? DateTime.now().toString());
        } catch (_) {
          dateB = DateTime.now();
        }
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          recentNotes = allNotes.take(5).toList(); // Take top 5
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        // Silently fail or show small error?
        // For dashboard, maybe just empty state is safer than snackbar spam on init
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const Text(
                    'IntelliNote',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: widget.onSearch,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Good morning, Alex',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              /// Recents Section
              const Text(
                'Recents',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 180,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : recentNotes.isEmpty
                    ? _buildEmptyRecents()
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentNotes.length,
                        itemBuilder: (context, index) {
                          final note = recentNotes[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _buildRecentCard(note),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 32),

              /// AI Insights Section (Still Static/Mock for now as per scope)
              const Text(
                'AI Insights for You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildInsightTile(
                icon: Icons.hub,
                iconColor: const Color(0xFF6C63FF), // Purple
                title: 'New Connections Found',
                subtitle:
                    "Notes on 'Project X' and 'Q3 Goals' seem related. Would you like to link them?",
              ),
              const SizedBox(height: 12),
              _buildInsightTile(
                icon: Icons.summarize,
                iconColor: const Color(0xFF6C63FF).withOpacity(0.8),
                title: 'Weekly Summary Ready',
                subtitle:
                    "Get a summary of your notes on 'Marketing Strategy' from the last 7 days.",
              ),
              const SizedBox(height: 12),
              _buildInsightTile(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF6C63FF),
                title: 'Action Items Detected',
                subtitle:
                    "We found 3 potential tasks in your 'Team Sync' note. Create a to-do list?",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(
          "No recent notes yet. Start writing!",
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildRecentCard(Map<String, dynamic> note) {
    final title = (note['title'] ?? "Untitled").toString();
    final summary = (note['summary'] ?? "No summary found.").toString();
    final tags = (note['tags'] ?? []) as List;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(noteId: note['id']),
          ),
        ).then((_) => _loadRecents()); // Refresh on return
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2025),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                summary,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tags
                    .map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors
                                .purple
                                .shade700, // Match new requested color
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag.toString(),
                            style: const TextStyle(
                              color: Colors.white, // White text for contrast
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2025),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
