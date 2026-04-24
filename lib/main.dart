import 'package:flutter/material.dart';
import 'package:raincheck/src/data/preferences_store.dart';
import 'package:raincheck/src/raincheck_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const preferencesStore = SharedPreferencesStore();
  final initialPreferences = await preferencesStore.load();

  runApp(
    RainCheckApp(
      preferencesStore: preferencesStore,
      initialPreferences: initialPreferences,
    ),
  );
}
