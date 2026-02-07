# State Notifiers with Flutter Hooks

A Flutter package for managing synchronous, asynchronous, and stream-based state with a clean, consistent API. Built with **flutter_hooks** as the primary consumption method for reactive UI updates.

## Features

- **SyncNotifier**: Manage immediate state changes and local operations
- **AsyncNotifier**: Handle Future-based operations like API calls and database queries
- **StreamNotifier**: Manage real-time data from streams like WebSockets or sensors
- **Built-in state management**: Loading, error, and success states included
- **Hooks-first design**: Optimized for use with `flutter_hooks`
- **Type-safe**: Full support for Dart's type system
- **Zero dependencies**: Only depends on `flutter/foundation` (plus `flutter_hooks` for consumption)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_hooks: ^0.20.0
  state_notifiers: ^1.0.0
```

## Quick Start with Hooks

### 1. SyncNotifier - For Immediate Operations

Use `SyncNotifier` when you need to manage state that changes immediately, like counters, toggles, or local calculations.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';

// Create a counter notifier (typically in a repository or service)
final counterNotifier = SyncNotifier<int, String>(
  () => SyncLoaded(0), // Initial value
);

// In your hook widget
class CounterWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Use useListenable to react to notifier changes
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

### 2. AsyncNotifier - For API Calls & Futures

Use `AsyncNotifier` for operations that take time, like network requests, file I/O, or database queries.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';

// Create an API data notifier (in repository/service)
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

// Refresh data with loading state
userNotifier.reload(); // Shows AsyncLoading then AsyncLoaded/AsyncError
```

### 3. StreamNotifier - For Real-time Data

Use `StreamNotifier` for continuous data streams like WebSocket connections, real-time databases, or sensor data.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';

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

## When to Use Each Notifier

| Notifier Type      | Best For                  | Hook Consumption                      |
| ------------------ | ------------------------- | ------------------------------------- |
| **SyncNotifier**   | Immediate state changes   | `useListenable(syncNotifier).value`   |
| **AsyncNotifier**  | One-time async operations | `useListenable(asyncNotifier).value`  |
| **StreamNotifier** | Continuous data streams   | `useListenable(streamNotifier).value` |

## Hooks Integration Guide

### The `useListenable` Hook

All notifiers extend `ChangeNotifier`, making them compatible with Flutter's `useListenable` hook:

```dart
// Basic usage
final notifier = SyncNotifier<int, String>(() => SyncLoaded(0));
final state = useListenable(notifier).value;

// With pattern matching
return switch (state) {
  SyncLoaded(:final value) => Text('Value: $value'),
  SyncError(:final error) => Text('Error: $error'),
  _ => const CircularProgressIndicator(),
};
```

### Creating Custom Hooks for Notifiers

For better reusability, create custom hooks:

```dart
// Custom hook for async data
AsyncState<User, String> useUser() {
  final notifier = useMemoized(() => AsyncNotifier<User, String>(
    () async {
      final user = await UserRepository().fetchUser();
      return AsyncLoaded(user);
    },
  ));

  // Initial load on first build
  useEffect(() {
    notifier.reload();
    return null;
  }, [notifier]);

  return useListenable(notifier).value;
}

// Usage in widget
class UserProfile extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final userState = useUser();

    return switch (userState) {
      AsyncLoaded(:final value) => UserCard(user: value),
      AsyncLoading() => const LoadingSpinner(),
      AsyncError(:final error) => ErrorText(error: error),
      _ => const SizedBox(),
    };
  }
}
```

## Advanced Hooks Patterns

### 1. Notifier with Auto-dispose

```dart
class CounterPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Creates notifier that auto-disposes when widget is disposed
    final counterNotifier = useMemoized(() => SyncNotifier<int, String>(
      () => SyncLoaded(0),
    ));

    final state = useListenable(counterNotifier).value;

    return Scaffold(
      body: Center(
        child: switch (state) {
          SyncLoaded(:final value) => Text('Count: $value'),
          _ => const CircularProgressIndicator(),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counterNotifier.reload(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 2. Notifier with Dependencies

```dart
class UserPosts extends HookWidget {
  final String userId;

  UserPosts({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Recreates notifier when userId changes
    final postsNotifier = useMemoized(() => AsyncNotifier<List<Post>, String>(
      () async {
        final posts = await PostRepository().fetchPosts(userId);
        return AsyncLoaded(posts);
      },
    ), [userId]);

    // Auto-reload when userId changes
    useEffect(() {
      postsNotifier.reload();
      return null;
    }, [postsNotifier]);

    final state = useListenable(postsNotifier).value;

    return switch (state) {
      AsyncLoaded(:final value) => PostList(posts: value),
      AsyncLoading() => const LoadingIndicator(),
      AsyncError(:final error) => ErrorView(error: error),
      _ => const SizedBox(),
    };
  }
}
```

### 3. Multiple Notifiers in One Widget

```dart
class Dashboard extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final userState = useListenable(userNotifier).value;
    final notificationsState = useListenable(notificationsNotifier).value;
    final settingsState = useListenable(settingsNotifier).value;

    return Column(
      children: [
        // User section
        switch (userState) {
          AsyncLoaded(:final value) => UserHeader(user: value),
          AsyncLoading() => const UserLoadingShimmer(),
          _ => const UserPlaceholder(),
        },

        // Notifications section
        switch (notificationsState) {
          StreamLoaded(:final value) => NotificationBell(count: value),
          _ => const NotificationPlaceholder(),
        },

        // Settings section
        switch (settingsState) {
          SyncLoaded(:final value) => SettingsToggle(value: value),
          _ => const SettingsPlaceholder(),
        },
      ],
    );
  }
}
```

## State Management with Hooks

### Loading States with `useEffect`

```dart
class DataFetcher extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dataNotifier = useMemoized(() => AsyncNotifier<List<String>, String>(
      () => DataService().fetchData(),
    ));

    // Auto-fetch on first build
    useEffect(() {
      dataNotifier.reload();
      return null;
    }, [dataNotifier]);

    final state = useListenable(dataNotifier).value;

    return switch (state) {
      AsyncLoaded(:final value) => DataList(items: value),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => RetryButton(
        onRetry: () => dataNotifier.reload(),
        error: error,
      ),
      _ => const SizedBox(),
    };
  }
}
```

### Error Handling and Retry Logic

```dart
class SafeDataView extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dataNotifier = useMemoized(() => AsyncNotifier<Data, String>(
      () => fetchDataWithRetry(),
    ));

    final state = useListenable(dataNotifier).value;

    // Handle different error scenarios
    return switch (state) {
      AsyncLoaded(:final value) => DataView(data: value),
      AsyncError(:final error) => ErrorScreen(
        error: error,
        onRetry: () => dataNotifier.reload(),
      ),
      AsyncLoading() => const LoadingScreen(),
      _ => const InitialScreen(),
    };
  }
}
```

## Complete Example with Hooks

```dart
import 'package:flutter_hooks/flutter_hooks.dart';

// Notifier definitions (typically in separate files)
final counterNotifier = SyncNotifier<int, String>(() => SyncLoaded(0));
final userNotifier = AsyncNotifier<User, String>(() => api.fetchUser());
final updatesNotifier = StreamNotifier<String, String>(updateStream);

// Main widget using hooks
class Dashboard extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Listen to all notifiers
    final counterState = useListenable(counterNotifier).value;
    final userState = useListenable(userNotifier).value;
    final updatesState = useListenable(updatesNotifier).value;

    // Auto-load user on first build
    useEffect(() {
      userNotifier.reload();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Column(
        children: [
          // Counter section
          switch (counterState) {
            SyncLoaded(:final value) =>
              CounterDisplay(count: value),
            _ => const CounterLoading(),
          },

          const SizedBox(height: 20),

          // User section
          switch (userState) {
            AsyncLoaded(:final value) => UserProfile(user: value),
            AsyncLoading() => const UserLoading(),
            AsyncError(:final error) => UserError(error: error),
            _ => const UserPlaceholder(),
          },

          const SizedBox(height: 20),

          // Updates section
          switch (updatesState) {
            StreamLoaded(:final value) => UpdateFeed(text: value),
            StreamError(:final error) => UpdateError(error: error),
            StreamComplete() => const UpdatesComplete(),
            _ => const UpdatesLoading(),
          },
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => counterNotifier.reload(),
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => userNotifier.reload(),
            tooltip: 'Refresh user',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices with Hooks

### 1. **Memoize Notifier Creation**

```dart
// Good - memoized with dependencies
final notifier = useMemoized(() =>
  AsyncNotifier<Data, String>(() => fetchData(userId)),
  [userId], // Recreate when userId changes
);

// Bad - recreates on every build
final notifier = AsyncNotifier<Data, String>(() => fetchData(userId));
```

### 2. **Use `useEffect` for Side Effects**

```dart
// Load data automatically
useEffect(() {
  notifier.reload();
  return null;
}, [notifier]); // Only reload when notifier changes
```

### 3. **Dispose StreamNotifiers Properly**

```dart
class StreamWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final streamNotifier = useMemoized(() => StreamNotifier<int, String>(
      numberStream.map((n) => StreamLoaded(n)),
    ));

    // Auto-dispose on widget disposal
    useEffect(() => streamNotifier.dispose, []);

    final state = useListenable(streamNotifier).value;
    // ...
  }
}
```

### 4. **Create Custom Hooks for Complex Logic**

```dart
// Custom hook for paginated data
AsyncState<List<Item>, String> usePaginatedItems(int page) {
  final notifier = useMemoized(() => AsyncNotifier<List<Item>, String>(
    () => fetchPage(page),
  ), [page]);

  useEffect(() {
    notifier.reload();
    return null;
  }, [notifier]);

  return useListenable(notifier).value;
}
```

## Common Patterns with Hooks

### Auto-refresh Pattern

```dart
class AutoRefreshWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dataNotifier = useMemoized(() => AsyncNotifier<Data, String>(
      () => fetchData(),
    ));

    final state = useListenable(dataNotifier).value;

    // Auto-refresh every 30 seconds
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        dataNotifier.reload();
      });
      return timer.cancel;
    }, [dataNotifier]);

    return switch (state) {
      AsyncLoaded(:final value) => DataDisplay(data: value),
      AsyncLoading() => const LoadingIndicator(),
      _ => const Placeholder(),
    };
  }
}
```

### Debounced Search Pattern

```dart
class SearchWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final searchQuery = useState('');
    final resultsNotifier = useMemoized(() => AsyncNotifier<List<Result>, String>(
      () => searchItems(searchQuery.value),
    ));

    // Debounce search to avoid too many API calls
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        if (searchQuery.value.isNotEmpty) {
          resultsNotifier.reload();
        }
      });
      return timer.cancel;
    }, [searchQuery.value]);

    final results = useListenable(resultsNotifier).value;

    return Column(
      children: [
        TextField(
          onChanged: (value) => searchQuery.value = value,
        ),
        switch (results) {
          AsyncLoaded(:final value) => SearchResults(items: value),
          AsyncLoading() => const SearchLoading(),
          _ => const SearchEmpty(),
        },
      ],
    );
  }
}
```

## Migration from ValueListenableBuilder

If you're migrating from `ValueListenableBuilder` to hooks:

```dart
// Old way with ValueListenableBuilder
ValueListenableBuilder<AsyncState<User, String>>(
  valueListenable: userNotifier,
  builder: (context, state, child) {
    return switch (state) {
      AsyncLoaded(:final value) => UserCard(user: value),
      // ... other states
    };
  },
);

// New way with hooks
class UserProfile extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = useListenable(userNotifier).value;

    return switch (state) {
      AsyncLoaded(:final value) => UserCard(user: value),
      // ... other states
    };
  }
}
```

## Troubleshooting

### Common Issues

1. **Notifier not updating UI**
   - Ensure you're using `useListenable(notifier).value` not just `notifier.value`
   - Check that `notifyListeners()` is being called in your notifier

2. **Memory leaks with StreamNotifier**
   - Always call `dispose()` on StreamNotifier in `useEffect` cleanup
   - Or wrap in `useMemoized` for auto-disposal

3. **Too many rebuilds**
   - Memoize notifier creation with `useMemoized`
   - Use `useEffect` with proper dependencies

## API Reference

### SyncNotifier

- `SyncNotifier(() => SyncLoaded(value))` - Create with initial operation
- `value` - Get current state
- `reload()` - Re-execute the operation
- **Hook usage**: `useListenable(syncNotifier).value`

### AsyncNotifier

- `AsyncNotifier(() => future)` - Create with async operation
- `value` - Get current state
- `reload(): Future<void>` - Re-execute async operation
- **Hook usage**: `useListenable(asyncNotifier).value`

### StreamNotifier

- `StreamNotifier(stream)` - Create with data stream
- `value` - Get current state
- `reload()` - Restart the stream
- `dispose()` - Cancel subscription
- **Hook usage**: `useListenable(streamNotifier).value` + `useEffect(() => notifier.dispose, [])`

## Need Help?

- **Check hook examples** above for common patterns
- **Ensure notifier creation** is memoized with `useMemoized`
- **Use `useEffect`** for side effects like auto-loading
- **Dispose StreamNotifiers** to prevent memory leaks
- **Pattern match all states** in your UI logic

This package provides a simple yet powerful way to manage state in Flutter applications with hooks. Choose the notifier that matches your data source, consume it with `useListenable`, and build reactive UIs with minimal boilerplate!
