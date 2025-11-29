import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'recipes_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // Ignore "duplicate-app" if it ever happens, but crash for any other error
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
