import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showAppAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AboutDialogWidget(),
  );
}

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ),

                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '</>',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CODE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'STAXH',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),


                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),


                Text(
                  'Stash your code, retrieve it anywhere',  //our tagline
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  'A cross-platform code snippet manager built with Flutter. '
                      'Save, organize, and share your code snippets across web and mobile devices with real-time synchronization.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                const Divider(),

                const SizedBox(height: 16),


                _buildSectionTitle(context, 'Features'),
                const SizedBox(height: 12),

                _buildFeatureItem(
                  context,
                  Icons.code,
                  'Syntax Highlighting',
                  '15+ programming languages',
                ),
                _buildFeatureItem(
                  context,
                  Icons.search,
                  'Smart Search',
                  'Find snippets instantly',
                ),
                _buildFeatureItem(
                  context,
                  Icons.cloud_sync,
                  'Real-time Sync',
                  'Access from anywhere',
                ),
                _buildFeatureItem(
                  context,
                  Icons.groups,
                  'Team Collaboration',
                  'Share with your team',
                ),
                _buildFeatureItem(
                  context,
                  Icons.auto_awesome,
                  'AI-Powered',
                  'Auto-tagging & brief description',
                ),
                _buildFeatureItem(
                  context,
                  Icons.extension,
                  'Browser Extension',
                  'Save from Stack Overflow',
                ),

                const SizedBox(height: 24),

                const Divider(),

                const SizedBox(height: 16),

                _buildSectionTitle(context, 'Built With'),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTechChip(context, 'Flutter', Icons.flutter_dash),
                    _buildTechChip(context, 'Firebase', Icons.cloud),
                    _buildTechChip(context, 'Riverpod', Icons.settings),
                  ],
                ),

                const SizedBox(height: 24),

                const Divider(),

                const SizedBox(height: 16),


                _buildSectionTitle(context, 'Team'),
                const SizedBox(height: 12),

                Text(
                  'Developed by MUN CS Students\n'
                      'Software Dev. For Mobile Devices Project 2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _launchURL('https://github.com/MalcolmOdu/gr11-codestaxh-fall-2025'),
                      icon: const Icon(Icons.code),
                      label: const Text('GitHub'),
                    ),

                    const SizedBox(width: 12),

                    OutlinedButton.icon(
                      onPressed: () => _showFeedbackDialog(context),
                      icon: const Icon(Icons.feedback),
                      label: const Text('Feedback'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Copyright
                Text(
                  '© 2025 CodeStaxh. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(BuildContext context, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
      side: BorderSide(
        color: colorScheme.primary.withValues(alpha: 0.3),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'We\'d love to hear your thoughts!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                hintText: 'Your feedback...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Will Implement feedback submission later, thank you for now
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}