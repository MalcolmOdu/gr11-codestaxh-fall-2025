import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'models/snippet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codestaxh/controllers/snippet_controller.dart';
import 'package:codestaxh/controllers/snippet_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(SnippetAdapter());
  await Hive.openBox<Snippet>('snippets');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodestaXh',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {

  @override
  Widget build(BuildContext context) {

    final snippets =  ref.watch(snippetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CodestaXh - Set up Complete'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Riverpod State Management Ready',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Snippets in state: ${snippets.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: () {
                  final controller = SnippetController(ref);

                  controller.addSnippet(
                    title: 'Test Snippet ${snippets.length + 1}',
                    code: 'print("Hello World!")',
                    language: 'Python',
                    tags: ['test', 'snippet'],
                    author: 'Vincent Kennedy'
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Snippet Added')),
                  );
                },
              icon: const Icon(Icons.add),
              label: const Text('Add Snippet'),
            ),
          ],
        ),
      ),
    );
  }
}
