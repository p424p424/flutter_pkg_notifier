import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:notifier/notifier.dart';

void main() async {
  runApp(const MainApp());
}

class ThemeModeNotifier
    extends Notifier<AsyncState<ThemeMode, ThemeModeNotifierError>> {
  ThemeModeNotifier(super.value);

  Future<void> changeThemeMode(ThemeMode mode) async {
    // await Future.delayed(const Duration(seconds: 1));
    value = AsyncLoaded(mode);
  }
}

enum ThemeModeNotifierError { noError, error }

final themeMode = ThemeModeNotifier(AsyncUnloaded());

enum CounterError { noError, error }

class MainApp extends HookWidget {
  const MainApp({super.key});

  // In MainApp, change the switch statement to check for AsyncLoaded instead of SyncLoaded
  @override
  Widget build(BuildContext context) {
    final themeModeListenable = useListenable(themeMode);
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: switch (themeModeListenable.value) {
        AsyncLoaded(:final value) => value,
        _ => ThemeMode.light,
      },
      home: HomeView(),
    );
  }
}

class HomeView extends HookWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Counter'),
        actions: [
          IconButton(
            onPressed: () async {
              await themeMode.changeThemeMode(ThemeMode.dark);
            },
            icon: const Icon(Icons.dark_mode),
          ),
          IconButton(
            onPressed: () async {
              await themeMode.changeThemeMode(ThemeMode.light);
            },
            icon: const Icon(Icons.light_mode),
          ),
        ],
      ),
    );
  }
}
