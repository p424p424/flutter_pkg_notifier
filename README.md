# State Notifiers

A Flutter package for managing synchronous, asynchronous, and stream-based state with a clean, consistent API. Perfect for reactive UI updates with minimal boilerplate.

## Features

- **SyncNotifier**: Manage immediate state changes and local operations
- **AsyncNotifier**: Handle Future-based operations like API calls and database queries
- **StreamNotifier**: Manage real-time data from streams like WebSockets or sensors
- **Built-in state management**: Loading, error, and success states included
- **Flutter-first**: Works seamlessly with `ValueListenableBuilder` and `ListenableBuilder`
- **Type-safe**: Full support for Dart's type system
- **Zero dependencies**: Only depends on `flutter/foundation`

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  state_notifiers: ^1.0.0
```

## Quick Start

### SyncNotifier - For Immediate Operations

Use `SyncNotifier` when you need to manage state that changes immediately, like counters, toggles, or local calculations.

```dart
// Create a counter notifier
final counterNotifier = SyncNotifier<int, String>(
  () => SyncLoaded(0), // Initial value
);

// In your widget
ValueListenableBuilder<SyncState<int, String>>(
  valueListenable: counterNotifier,
  builder: (context, state, child) {
    return switch (state) {
      SyncLoaded(:final value) => Text('Count: $value'),
      SyncError(:final error) => Text('Error: $error'),
      _ => const CircularProgressIndicator(),
    };
  },
);

// Update the value
counterNotifier.value = SyncLoaded(42);
// Or reload with a new operation
counterNotifier.reload();
```

### AsyncNotifier - For API Calls & Futures

Use `AsyncNotifier` for operations that take time, like network requests, file I/O, or database queries.

```dart
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

// In your widget
ValueListenableBuilder<AsyncState<User, String>>(
  valueListenable: userNotifier,
  builder: (context, state, child) {
    return switch (state) {
      AsyncLoaded(:final value) => UserProfile(user: value),
      AsyncError(:final error) => ErrorMessage(error: error),
      AsyncLoading() => const LoadingSpinner(),
      _ => const PlaceholderWidget(),
    };
  },
);

// Refresh data
await userNotifier.reload();
```

### StreamNotifier - For Real-time Data

Use `StreamNotifier` for continuous data streams like WebSocket connections, real-time databases, or sensor data.

```dart
// Create a chat stream notifier
final chatNotifier = StreamNotifier<Message, String>(
  webSocketStream.map((data) => StreamLoaded(Message.fromJson(data))),
);

// In your widget
ValueListenableBuilder<StreamState<Message, String>>(
  valueListenable: chatNotifier,
  builder: (context, state, child) {
    return switch (state) {
      StreamLoaded(:final value) => ChatBubble(message: value),
      StreamError(:final error) => Text('Connection error: $error'),
      StreamComplete() => const Text('Chat ended'),
      _ => const ConnectionIndicator(),
    };
  },
);

// Reconnect stream
chatNotifier.reload();
```

## When to Use Each Notifier

| Notifier Type      | Best For                  | Example Use Cases                                  |
| ------------------ | ------------------------- | -------------------------------------------------- |
| **SyncNotifier**   | Immediate state changes   | Counters, toggles, form fields, local calculations |
| **AsyncNotifier**  | One-time async operations | API calls, database queries, file operations       |
| **StreamNotifier** | Continuous data streams   | WebSockets, real-time updates, sensor data         |

## State Types Explained

Each notifier uses specific state classes to represent different phases:

### SyncNotifier States

- `SyncUnloaded()` - Initial state
- `SyncLoaded(value)` - Successful operation with data
- `SyncError(error)` - Operation failed

### AsyncNotifier States

- `AsyncUnloaded()` - Not started yet
- `AsyncLoading()` - Operation in progress
- `AsyncLoaded(value)` - Success with data
- `AsyncError(error)` - Operation failed

### StreamNotifier States

- `StreamUnloaded()` - Not connected
- `StreamLoading()` - Connecting
- `StreamLoaded(value)` - New data arrived
- `StreamError(error)` - Stream error
- `StreamComplete()` - Stream ended

## Advanced Usage

### Creating Custom Operations

```dart
// Custom async operation with error handling
final dataNotifier = AsyncNotifier<List<Item>, String>(
  () async {
    try {
      final items = await repository.fetchItems();
      if (items.isEmpty) {
        return AsyncError('No items found');
      }
      return AsyncLoaded(items);
    } catch (e) {
      return AsyncError('Network error: $e');
    }
  },
);
```

### Combining with Flutter's Provider

```dart
// Wrap in a Provider for easy access
ChangeNotifierProvider(
  create: (context) => AsyncNotifier<User, String>(
    () => UserRepository().fetchUser(),
  ),
  child: Consumer<AsyncNotifier<User, String>>(
    builder: (context, notifier, child) {
      final state = notifier.value;
      // Build UI based on state
    },
  ),
);
```

### Handling Stream Errors

```dart
// Stream with error handling
final sensorNotifier = StreamNotifier<double, String>(
  sensorStream.map((value) => StreamLoaded(value)).handleError((error) {
    return StreamError('Sensor error: $error');
  }),
);
```

## Common Patterns

### Loading States

All notifiers automatically manage loading states. `AsyncNotifier` shows `AsyncLoading()` during operations, and you can manually set `StreamLoading()` for streams.

### Error Recovery

Use `reload()` to retry failed operations:

```dart
// Retry on error
if (notifier.value is AsyncError) {
  await notifier.reload();
}
```

### State Transitions

States follow predictable patterns:

- **Sync**: Unloaded → Loaded/Error
- **Async**: Unloaded → Loading → Loaded/Error
- **Stream**: Unloaded → Loading → Loaded → Complete/Error

## Complete Example

Here's a complete Flutter widget using all three notifiers:

```dart
class Dashboard extends StatelessWidget {
  final counterNotifier = SyncNotifier<int, String>(() => SyncLoaded(0));
  final userNotifier = AsyncNotifier<User, String>(() => api.fetchUser());
  final updatesNotifier = StreamNotifier<String, String>(updateStream);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Counter (Sync)
          ValueListenableBuilder<SyncState<int, String>>(
            valueListenable: counterNotifier,
            builder: (context, state, _) {
              return switch (state) {
                SyncLoaded(:final value) => Text('Counter: $value'),
                _ => const CircularProgressIndicator(),
              };
            },
          ),

          // User data (Async)
          ValueListenableBuilder<AsyncState<User, String>>(
            valueListenable: userNotifier,
            builder: (context, state, _) {
              return switch (state) {
                AsyncLoaded(:final value) => UserCard(user: value),
                AsyncError(:final error) => Text('Error: $error'),
                AsyncLoading() => const LoadingSpinner(),
                _ => const SizedBox(),
              };
            },
          ),

          // Real-time updates (Stream)
          ValueListenableBuilder<StreamState<String, String>>(
            valueListenable: updatesNotifier,
            builder: (context, state, _) {
              return switch (state) {
                StreamLoaded(:final value) => UpdateMessage(text: value),
                StreamError(:final error) => Text('Update error: $error'),
                _ => const SizedBox(),
              };
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counterNotifier.reload(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

## Best Practices

1. **Choose the right notifier** for your use case (see table above)
2. **Always handle all states** in your UI builders
3. **Use `reload()`** for refreshing data
4. **Dispose StreamNotifier** when done to prevent memory leaks
5. **Keep operations focused** - one notifier per logical data type

## API Reference

### SyncNotifier

- `SyncNotifier(() => SyncLoaded(value))` - Create with initial operation
- `value` - Get current state
- `reload()` - Re-execute the operation

### AsyncNotifier

- `AsyncNotifier(() => future)` - Create with async operation
- `value` - Get current state
- `reload(): Future<void>` - Re-execute async operation

### StreamNotifier

- `StreamNotifier(stream)` - Create with data stream
- `value` - Get current state
- `reload()` - Restart the stream
- `dispose()` - Cancel subscription (call in State.dispose)

## Need Help?

- **Check the examples** above for common patterns
- **Look at the state classes** to understand available states
- **Use `reload()`** to refresh or retry operations
- **Remember to dispose** `StreamNotifier` in StatefulWidgets

This package provides a simple yet powerful way to manage state in Flutter applications. Choose the notifier that matches your data source, handle the states in your UI, and let the notifier manage the rest!
