import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codestaxh/controllers/snippet_controller.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../../controllers/team_notifier.dart';
import '../../views/web/team_management_view.dart';
import '../../views/shared/profile_view.dart';
import '../../widgets/notification_bell.dart';

class SnippetEditorView extends ConsumerStatefulWidget {
  //if editing existing snippet, pass ID
  final String? id;
  const SnippetEditorView({super.key, this.id});

  @override
  ConsumerState<SnippetEditorView> createState() => _SnippetEditorViewState();
}

class _SnippetEditorViewState extends ConsumerState<SnippetEditorView> {
  //Text Controller to store what thr user types
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedTeamId;
  String _selectedLanguage = 'Python';

  //list of available languages
  final List<String> _languages = [
    'Python',
    'Java',
    'JavaScript',
    'Dart',
    'C++',
    'Go',
    'Rust',
    'C#',
    'Ruby',
    'Kotlin',
    'SQL',
    'HTML',
    'CSS',
    'PHP',
    'Swift',
    'TypeScript',
  ];
  final List<String> _tags = [];
  bool _isSaving = false; //loading state for save button

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'New Snippet' : 'Edit Snippet'),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8,),
          
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: 'Manage Teams',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeamManagementView(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileView(),
                ),
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                //Title
                _buildTitleField(),
                const SizedBox(height: 24),
                //code editor
                _buildCodeEditor(),
                const SizedBox(height: 24),
                //language selector
                _buildLanguageSelector(),
                const SizedBox(height: 24),
                //tags selector
                _buildTagsSelector(),
                const SizedBox(height: 24),

                //Team Selector
                Consumer(
                  builder: (context, ref, _) {
                    final teams = ref.watch(teamProvider);
                    if (teams.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share with Team (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          initialValue: _selectedTeamId,
                          decoration: const InputDecoration(
                            labelText: 'Team',
                            hintText: 'Select a team to share with',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Personal (Not Shared)'),
                            ),
                            ...teams.map((team) {
                              return DropdownMenuItem<String>(
                                value: team.id,
                                child: Text(team.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTeamId = value;
                            });
                          },
                        )
                      ]
                    );
                  }
                ),

                //buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'e.g., "BFS algorithm"',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _buildCodeEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Code',
            hintText: 'Paste or Write your code here...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 15,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          //for autodetect
          onChanged: (value) {
            setState(() {});
          },
        ),

        //Preview with syntax highlighting
        if (_codeController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: HighlightView(
              _codeController.text,
              language: _selectedLanguage.toLowerCase(),
              theme: githubTheme,
              padding: const EdgeInsets.all(8),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              items: _languages.map((language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),);
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _autoDetectLanguage,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Auto Detect'),
          )
        ]
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        //To display existing tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) =>
                Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                )),

            //Button to add tag
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add tag'),
              onPressed: _showAddTagDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),

        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveSnippet,
          icon: _isSaving ?
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.save),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _autoDetectLanguage() {
    final code = _codeController.text.toLowerCase();

    String detectedLanguage = 'Python';

    if (code.contains('def') || code.contains('import') ||
        code.contains('print(')) {
      detectedLanguage = 'Python';
    }
    else if (code.contains('function') || code.contains('const') ||
        code.contains('let')) {
      detectedLanguage = 'JavaScript';
    }
    else if (code.contains('class') && code.contains('void ') &&
        code.contains('{') || code.contains('System.out.print ')) {
      detectedLanguage = 'Java';
    }
    else if (code.contains('widget ') || code.contains('stateless') ||
        code.contains('stateful')) {
      detectedLanguage = 'Dart';
    }
    else if (code.contains('<?php')) {
      detectedLanguage = 'PHP';
    }
    else if (code.contains('select ') || code.contains('from ') ||
        code.contains('where ')) {
      detectedLanguage = 'SQL';
    }
    else if (code.contains('<html') || code.contains('<div')) {
      detectedLanguage = 'HTML';
    }
    else if (code.contains('fn') || code.contains('impl ')) {
      detectedLanguage = 'Rust';
    }
    else if (code.contains('func') && code.contains('package ')) {
      detectedLanguage = 'Go';
    }
    else if (code.contains('fun ') && code.contains('val ') ||
        code.contains('var ')) {
      detectedLanguage = 'Kotlin';
    }
    else if (code.contains('#include') || code.contains('std::') ||
        code.contains('cout')) {
      detectedLanguage = 'C++';
    }
    else if (code.contains('using namespace') ||
        code.contains('using system') && code.contains('public class')) {
      detectedLanguage = 'C#';
    }
    else
    if (code.contains('import foundation') || code.contains('import UIKit')) {
      detectedLanguage = 'Swift';
    }
    else if (code.contains('def ') && code.contains('end') &&
        code.contains('class')) {
      detectedLanguage = 'Ruby';
    }
    else if (code.contains('<style>') || code.contains('</style>')) {
      detectedLanguage = 'CSS';
    }
    else if (code.contains(': string') || code.contains(': number') ||
        code.contains(': boolean') && code.contains('let ') ||
        code.contains('const ')) {
      detectedLanguage = 'TypeScript';
    }
    setState(() {
      _selectedLanguage = detectedLanguage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detected language: $_selectedLanguage'),
      ),
    );
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(
            controller: _tagController,
            decoration: const InputDecoration(
              hintText: 'Enter tag name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              _addTag();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addTag();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }


  Future<void> _saveSnippet() async {
    final title = _titleController.text.trim();
    final code = _codeController.text.trim();

    if (title.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and code.')),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isSaving = true;
    });

    //snippet using SnippetController
    final controller = SnippetController(ref);


    try {
      await controller.addSnippet(
        title: title,
        code: code,
        language: _selectedLanguage,
        tags: _tags,
        teamId: _selectedTeamId,
        authorId: FirebaseAuth.instance.currentUser!.uid
      );

      if (mounted) { // Check if widget still exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(
            _selectedTeamId != null
                ? 'Snippet saved and shared with team "'
                : 'Snippet saved!',
          ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving snippet: $e')),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}