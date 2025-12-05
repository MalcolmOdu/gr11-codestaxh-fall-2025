import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/snippet.dart';
import '../widgets/glass_card.dart';

// Statistics dashboard showing snippet metrics
class SnippetStatistics extends ConsumerWidget {
  final List<Snippet> snippets;
  final String? userId; // so we can filter with user if provided

  const SnippetStatistics({
    super.key,
    required this.snippets,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter snippets if userId provided
    final userSnippets = userId != null
        ? snippets.where((s) => s.authorId == userId).toList()
        : snippets;

    final totalSnippets = userSnippets.length;
    final languageMap = <String, int>{};
    final tagMap = <String, int>{};

    for (final snippet in userSnippets) {
      // Count languages
      languageMap[snippet.language] = (languageMap[snippet.language] ?? 0) + 1;

      // Count tags
      for (final tag in snippet.tags) {
        tagMap[tag] = (tagMap[tag] ?? 0) + 1;
      }
    }

    // Get top 3 languages and tags
    final topLanguages = languageMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3Languages = topLanguages.take(3).toList();

    final topTags = tagMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3Tags = topTags.take(3).toList();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Main stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: languageMap.length.toString(),
                    label: 'Languages',
                    icon: Icons.language,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),


            if (top3Languages.isNotEmpty) ...[
              Text(
                'Top Languages',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...top3Languages.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProgressBar(
                  label: entry.key,
                  value: entry.value,
                  max: totalSnippets,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Top tags
            if (top3Tags.isNotEmpty) ...[
              Text(
                'Popular Tags',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: top3Tags.map((entry) => Chip(
                  label: Text('${entry.key} (${entry.value})'),
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Individual stat card
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Progress bar for language distribution
class _ProgressBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = max > 0 ? (value / max * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$value ($percentage%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / max,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}


class RecentActivity extends ConsumerWidget {
  final List<Snippet> snippets;
  final int maxItems;

  const RecentActivity({
    super.key,
    required this.snippets,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort by date and take most recent
    final recentSnippets = [...snippets]
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final displaySnippets = recentSnippets.take(maxItems).toList();

    if (displaySnippets.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...displaySnippets.map((snippet) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecentItem(snippet: snippet),
            )),
          ],
        ),
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final Snippet snippet;

  const _RecentItem({required this.snippet});

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snippet.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    snippet.language,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    ' • ${_timeAgo(snippet.dateAdded)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}