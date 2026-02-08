# State Notifiers

A Flutter package for managing synchronous, asynchronous, and stream-based state with a clean, consistent API. Built with **flutter_hooks** as the primary consumption method for reactive UI updates.

## Features

- **Notifier<T>**: Base class for any reactive value container
- **SyncNotifier**: Manage immediate state changes and local operations
- **AsyncNotifier**: Handle Future-based operations like API calls and database queries
- **StreamNotifier**: Manage real-time data from streams like WebSockets or sensors
- **Built-in state management**: Loading, error, and success states included
- **Hooks-first design**: Optimized for use with `flutter_hooks`
- **Type-safe**: Full support for Dart's type system

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_hooks: ^0.20.0
  notifier: ^1.0.0
```

## Quick Start

### 1. Base Notifier - For Any Reactive Value

The base `Notifier<T>` class works like `ValueNotifier` but with `ChangeNotifier` API, perfect for simple reactive values.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:notifier/notifier.dart';

// Create a simple notifier for any value
final counterNotifier = Notifier<int>(0);

// In your hook widget
class CounterWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useListenable(counterNotifier).value;

    return Text('Count: $count');
  }
}

// Update the value
counterNotifier.value = 42; // Automatically notifies listeners
```

### 2. AsyncNotifier - For Theme Management (Complete Example)

Here's a complete example showing how to use `AsyncState` with a custom notifier for theme management:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:notifier/notifier.dart';

// Define error types for type safety
enum ThemeModeNotifierError { noError, error }

// Create a custom notifier that extends Notifier with AsyncState
class ThemeModeNotifier
    extends Notifier<AsyncState<ThemeMode, ThemeModeNotifierError>> {
  ThemeModeNotifier(super.value);

  Future<void> changeThemeMode(ThemeMode mode) async {
    // Simulate async operation (optional delay)
    // await Future.delayed(const Duration(seconds: 1));
    value = AsyncLoaded(mode);
  }
}

// Create a global instance
final themeMode = ThemeModeNotifier(AsyncUnloaded());

void main() {
  runApp(const MainApp());
}

class MainApp extends HookWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModeListenable = useListenable(themeMode);

    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: switch (themeModeListenable.value) {
        AsyncLoaded(:final value) => value,
        _ => ThemeMode.light, // Default fallback
      },
      home: const HomeView(),
    );
  }
}

class HomeView extends HookWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
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
      body: const Center(
        child: Text('Hello World'),
      ),
    );
  }
}
```

### 3. SyncNotifier - For Immediate Operations

Use `SyncNotifier` when you need to manage state that changes immediately.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:notifier/notifier.dart';

// Define error type
enum CounterError { noError, error }

// Create a counter notifier
final counterNotifier = SyncNotifier<int, CounterError>(
  () => SyncLoaded(0), // Initial value
);

// In your hook widget
class CounterWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = useListenable(counterNotifier).value;

    return switch (state) {
      SyncLoaded(:final value) => Text('Count: $value'),
      SyncError(:final error) => Text('Error: $error'),
      _ => const CircularProgressIndicator(),
    };
  }
}

// Update the value
counterNotifier.value = SyncLoaded(42);
// Or reload with a new operation
counterNotifier.reload();
```

### 4. AsyncNotifier - For API Calls

Use `AsyncNotifier` for operations that take time, like network requests.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:notifier/notifier.dart';

// Create an API data notifier
final userNotifier = AsyncNotifier<User, String>(
  () async {
    try {
      final user = await api.fetchUser();
      return AsyncLoaded(user);
    } catch (e) {
      return AsyncError('Failed to load user');
    }
  },
);

// In your hook widget
class UserProfile extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = useListenable(userNotifier).value;

    return switch (state) {
      AsyncLoaded(:final value) => UserCard(user: value),
      AsyncError(:final error) => ErrorMessage(error: error),
      AsyncLoading() => const LoadingSpinner(),
      _ => const PlaceholderWidget(),
    };
  }
}

// Refresh data
userNotifier.reload();
```

### 5. StreamNotifier - For Real-time Data

Use `StreamNotifier` for continuous data streams.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:notifier/notifier.dart';

// Create a chat stream notifier
final chatNotifier = StreamNotifier<Message, String>(
  webSocketStream.map((data) => StreamLoaded(Message.fromJson(data))),
);

// In your hook widget
class ChatView extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = useListenable(chatNotifier).value;

    return switch (state) {
      StreamLoaded(:final value) => ChatBubble(message: value),
      StreamError(:final error) => Text('Connection error: $error'),
      StreamComplete() => const Text('Chat ended'),
      _ => const ConnectionIndicator(),
    };
  }
}

// Reconnect stream
chatNotifier.reload();
```

## Key Patterns from Examples

### Pattern 1: Custom Notifier with AsyncState

Extend `Notifier<AsyncState<T, E>>` when you need custom methods:

```dart
enum UserError { notFound, networkError }

class UserNotifier extends Notifier<AsyncState<User, UserError>> {
  UserNotifier(super.value);

  Future<void> login(String email, String password) async {
    value = AsyncLoading();
    try {
      final user = await authService.login(email, password);
      value = AsyncLoaded(user);
    } catch (e) {
      value = AsyncError(UserError.networkError);
    }
  }

  void logout() {
    value = AsyncUnloaded();
  }
}

// Usage
final userNotifier = UserNotifier(AsyncUnloaded());
final userState = useListenable(userNotifier).value;

return switch (userState) {
  AsyncLoaded(:final value) => UserProfile(user: value),
  AsyncLoading() => const LoadingIndicator(),
  AsyncError(:final error) => ErrorView(error: error),
  _ => const LoginButton(),
};
```

### Pattern 2: Using Enums for Error Types

For better type safety, use enums instead of strings:

```dart
enum ThemeError { failedToChange, invalidMode }
enum CounterError { overflow, underflow }
enum ApiError { network, server, validation }

// Usage in notifier
final themeNotifier = Notifier<AsyncState<ThemeMode, ThemeError>>(AsyncUnloaded());
```

### Pattern 3: Global vs Local Notifiers

**Global** (app-wide state):

```dart
// In a shared file (e.g., notifiers/theme_notifier.dart)
final themeMode = ThemeModeNotifier(AsyncUnloaded());

// Use anywhere in app
themeMode.changeThemeMode(ThemeMode.dark);
```

**Local** (widget-specific state):

```dart
class CounterPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counterNotifier = useMemoized(() =>
      SyncNotifier<int, CounterError>(() => SyncLoaded(0)),
    );

    final state = useListenable(counterNotifier).value;
    // ...
  }
}
```

## When to Use Each Pattern

| Pattern                | Use When                             | Example                                      |
| ---------------------- | ------------------------------------ | -------------------------------------------- |
| **Extend Notifier<T>** | Need custom methods or complex logic | `ThemeModeNotifier` with `changeThemeMode()` |
| **Use SyncNotifier**   | Immediate synchronous operations     | Counter, toggle, form validation             |
| **Use AsyncNotifier**  | One-time async operations            | API calls, file I/O, database queries        |
| **Use StreamNotifier** | Continuous data streams              | WebSockets, real-time updates                |

## Complete Combined Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:notifier/notifier.dart';

// Error enums
enum AppError { network, validation, unknown }
enum ThemeError { failedToChange }

// Theme notifier (extending base Notifier)
class ThemeNotifier extends Notifier<AsyncState<ThemeMode, ThemeError>> {
  ThemeNotifier(super.value);

  Future<void> toggleTheme() async {
    final current = value;
    if (current is AsyncLoaded<ThemeMode, ThemeError>) {
      final newMode = current.value == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
      value = AsyncLoaded(newMode);
    }
  }
}

// Global notifiers
final themeNotifier = ThemeNotifier(AsyncLoaded(ThemeMode.light));
final counterNotifier = SyncNotifier<int, AppError>(() => SyncLoaded(0));

void main() {
  runApp(const MyApp());
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = useListenable(themeNotifier).value;

    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: switch (themeState) {
        AsyncLoaded(:final value) => value,
        _ => ThemeMode.light,
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final counterState = useListenable(counterNotifier).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('State Notifiers Demo'),
        actions: [
          IconButton(
            onPressed: () => themeNotifier.toggleTheme(),
            icon: const Icon(Icons.color_lens),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            switch (counterState) {
              SyncLoaded(:final value) =>
                Text('Count: $value', style: Theme.of(context).textTheme.headlineLarge),
              SyncError(:final error) =>
                Text('Error: ${error.name}', style: const TextStyle(color: Colors.red)),
              _ => const CircularProgressIndicator(),
            },

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final current = counterState;
                if (current is SyncLoaded<int, AppError>) {
                  counterNotifier.value = SyncLoaded(current.value + 1);
                }
              },
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## State Management Patterns

### Loading States Pattern

```dart
class DataFetcher extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dataNotifier = useMemoized(() => AsyncNotifier<List<String>, String>(
      () async {
        await Future.delayed(const Duration(seconds: 2)); // Simulate loading
        return AsyncLoaded(['Item 1', 'Item 2', 'Item 3']);
      },
    ));

    useEffect(() {
      dataNotifier.reload();
      return null;
    }, [dataNotifier]);

    final state = useListenable(dataNotifier).value;

    return switch (state) {
      AsyncLoaded(:final value) => ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) => ListTile(title: Text(value[index])),
        ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => Center(child: Text('Error: $error')),
      _ => const SizedBox(),
    };
  }
}
```

### Error Handling Pattern

```dart
enum DataError { network, parsing, unknown }

class SafeDataView extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dataNotifier = useMemoized(() => AsyncNotifier<Data, DataError>(
      () async {
        try {
          final response = await http.get(Uri.parse('https://api.example.com/data'));
          final data = Data.fromJson(response.body);
          return AsyncLoaded(data);
        } on SocketException {
          return AsyncError(DataError.network);
        } on FormatException {
          return AsyncError(DataError.parsing);
        } catch (e) {
          return AsyncError(DataError.unknown);
        }
      },
    ));

    final state = useListenable(dataNotifier).value;

    return switch (state) {
      AsyncLoaded(:final value) => DataView(data: value),
      AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => dataNotifier.reload(),
        ),
      AsyncLoading() => const LoadingView(),
      _ => const InitialView(),
    };
  }
}
```

## API Reference

### Notifier<T>

- Base class extending `ChangeNotifier`
- `T get value` / `set value(T value)` - Reactive value with automatic listener notification
- Extend this for custom notifiers with additional methods

### SyncNotifier<T, E>

- `SyncNotifier(() => SyncLoaded(value))` - Create with initial operation
- `value: SyncState<T, E>` - Get current state
- `reload()` - Re-execute the synchronous operation

### AsyncNotifier<T, E>

- `AsyncNotifier(() => future)` - Create with async operation
- `value: AsyncState<T, E>` - Get current state
- `reload(): Future<void>` - Re-execute async operation

### StreamNotifier<T, E>

- `StreamNotifier(stream)` - Create with data stream
- `value: StreamState<T, E>` - Get current state
- `reload()` - Restart the stream
- `dispose()` - Cancel subscription (call in State.dispose)

### State Classes

- **AsyncState**: `AsyncUnloaded`, `AsyncLoading`, `AsyncLoaded`, `AsyncError`
- **SyncState**: `SyncUnloaded`, `SyncLoaded`, `SyncError`
- **StreamState**: `StreamUnloaded`, `StreamLoading`, `StreamLoaded`, `StreamError`, `StreamComplete`

## Best Practices

1. **Use enums for errors** for better type safety (as shown in the examples)
2. **Extend `Notifier<T>`** when you need custom methods like `changeThemeMode()`
3. **Global instances are fine** for app-wide state like theme
4. **Always use `useListenable()`** with hooks for reactive updates
5. **Pattern match all states** in switch expressions
6. **Memoize notifier creation** with `useMemoized` for local notifiers
7. **Dispose StreamNotifiers** in `useEffect` cleanup

## Troubleshooting

**Notifier not updating UI?**

- Ensure you're using `useListenable(notifier).value` not just `notifier.value`
- Check that `notifyListeners()` is being called when value changes

**Too many rebuilds?**

- Memoize notifier creation with `useMemoized`
- Use `useEffect` with proper dependencies

**Memory leaks with StreamNotifier?**

- Always call `dispose()` on StreamNotifier in `useEffect` cleanup
- Or wrap in `useMemoized` for auto-disposal

## Need Help?

- **Check the theme mode example** for the exact pattern from your code
- **Extend `Notifier<T>`** when you need custom methods
- **Use enums for errors** for better type safety
- **Global instances are fine** for app-wide state like theme
- **Always use `useListenable()`** with hooks for reactive updates

This package provides a simple yet powerful way to manage state in Flutter applications with hooks. Choose the pattern that matches your use case and build reactive UIs with minimal boilerplate!
