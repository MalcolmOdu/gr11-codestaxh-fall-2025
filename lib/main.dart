import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/snippet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);


  if(!kIsWeb){
    await Hive.initFlutter();
    Hive.registerAdapter(SnippetAdapter());
    await Hive.openBox<Snippet>('snippets');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CodeStaxh',
      debugShowCheckedModeBanner: false,

      routerConfig: appRouter,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}