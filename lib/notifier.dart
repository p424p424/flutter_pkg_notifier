/// State management notifiers for synchronous, asynchronous, and stream operations.
///
/// This library provides a set of notifier classes that manage different types of
/// state operations with a consistent API pattern. Each notifier extends
/// `ChangeNotifier` and can be used with Flutter's `ValueListenableBuilder` or
/// `ListenableBuilder` for reactive UI updates.
///
/// # Usage Examples
///
/// ```dart
/// // Create a synchronous notifier
/// final syncCounter = SyncNotifier<int, String>(() => SyncLoaded(42));
///
/// // Create an asynchronous notifier
/// final asyncData = AsyncNotifier<List<String>, String>(
///   () => api.fetchData(),
/// );
///
/// // Create a stream notifier
/// final streamUpdates = StreamNotifier<int, String>(
///   someStream.map((data) => StreamLoaded(data)),
/// );
/// ```
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

class Notifier<T> extends ChangeNotifier {
  Notifier(this._state);

  T _state;

  T get state => _state;

  set state(T newState) {
    _state = newState;
    notifyListeners();
  }
}

/// A notifier for synchronous operations that immediately produce a value.
///
/// Use `SyncNotifier` when you have a synchronous operation that returns
/// immediately and you want to wrap its result in a reactive state container.
/// This is useful for simple state that doesn't require loading states or
/// asynchronous operations, such as:
/// - Local calculations
/// - In-memory state transformations
/// - Simple value holders that need reactive updates
///
/// The notifier works by executing the provided synchronous operation when
/// created and whenever `reload()` is called, then notifying listeners of
/// the new state.
///
/// ## Example
///
/// ```dart
/// class CounterRepository {
///   int _count = 0;
///
///   SyncState<int, String> getCount() {
///     return SyncLoaded(_count++);
///   }
/// }
///
/// final counterNotifier = SyncNotifier<int, String>(
///   () => CounterRepository().getCount(),
/// );
///
/// // In a widget:
/// ValueListenableBuilder<SyncState<int, String>>(
///   valueListenable: counterNotifier,
///   builder: (context, state, child) {
///     return switch (state) {
///       SyncLoaded(:final value) => Text('Count: $value'),
///       SyncError(:final error) => Text('Error: $error'),
///       SyncUnloaded() => const CircularProgressIndicator(),
///     };
///   },
/// );
///
/// // To update the value:
/// counterNotifier.reload();
/// ```
class SyncNotifier<T, E> extends ChangeNotifier {
  /// Creates a synchronous notifier that executes the given operation.
  ///
  /// The [operation] is a synchronous function that returns a `SyncState`.
  /// It will be executed immediately upon creation and whenever `reload()` is called.
  ///
  /// ```dart
  /// final notifier = SyncNotifier<int, String>(
  ///   () => SyncLoaded(42),
  /// );
  /// ```
  SyncNotifier(this._operation) {
    reload();
  }

  final SyncState<T, E> Function() _operation;
  late SyncState<T, E> _value;

  /// The current state of the synchronous operation.
  ///
  /// This value will be updated whenever `reload()` is called.
  /// Listeners are notified when the value changes.
  SyncState<T, E> get value => _value;

  /// Reloads the value by executing the operation again.
  ///
  /// This method:
  /// 1. Executes the synchronous operation
  /// 2. Updates the current value
  /// 3. Notifies all listeners of the change
  ///
  /// ```dart
  /// // Reload the current value
  /// syncNotifier.reload();
  /// ```
  void reload() {
    _value = _operation();
    notifyListeners();
  }
}

/// A notifier for asynchronous operations that return a `Future`.
///
/// Use `AsyncNotifier` when you need to handle operations that complete
/// at a future time, such as:
/// - Network requests
/// - Database queries
/// - File I/O operations
/// - Any operation that returns a `Future`
///
/// The notifier automatically manages loading states and error handling.
/// When `reload()` is called, it sets the state to `AsyncLoading`, executes
/// the future, and updates to either `AsyncLoaded` or `AsyncError` when complete.
///
/// ## Example
///
/// ```dart
/// class UserRepository {
///   Future<AsyncState<User, String>> fetchUser() async {
///     try {
///       final response = await http.get(Uri.parse('/api/user'));
///       final user = User.fromJson(response.body);
///       return AsyncLoaded(user);
///     } catch (e) {
///       return AsyncError('Failed to fetch user');
///     }
///   }
/// }
///
/// final userNotifier = AsyncNotifier<User, String>(
///   () => UserRepository().fetchUser(),
/// );
///
/// // In a widget:
/// ValueListenableBuilder<AsyncState<User, String>>(
///   valueListenable: userNotifier,
///   builder: (context, state, child) {
///     return switch (state) {
///       AsyncLoaded(:final value) => Text('User: ${value.name}'),
///       AsyncError(:final error) => Text('Error: $error'),
///       AsyncLoading() => const CircularProgressIndicator(),
///       AsyncUnloaded() => const Text('Not loaded yet'),
///     };
///   },
/// );
///
/// // To refresh the data:
/// await userNotifier.reload();
/// ```
class AsyncNotifier<T, E> extends ChangeNotifier {
  /// Creates an asynchronous notifier that executes the given future.
  ///
  /// The [future] is a function that returns a `Future<AsyncState<T, E>>`.
  /// It will be executed immediately upon creation and whenever `reload()` is called.
  ///
  /// ```dart
  /// final notifier = AsyncNotifier<List<String>, String>(
  ///   () => api.fetchItems(),
  /// );
  /// ```
  AsyncNotifier(this.future) {
    reload();
  }

  /// The function that returns the future to be executed.
  ///
  /// This function is called whenever `reload()` is invoked.
  final Future<AsyncState<T, E>> Function() future;

  AsyncState<T, E> _value = AsyncUnloaded<T, E>();

  /// The current state of the asynchronous operation.
  ///
  /// This will be one of:
  /// - `AsyncUnloaded` - Initial state before any operation
  /// - `AsyncLoading` - Operation is in progress
  /// - `AsyncLoaded` - Operation completed successfully with value
  /// - `AsyncError` - Operation failed with error
  ///
  /// Listeners are notified whenever the state changes.
  AsyncState<T, E> get value => _value;

  /// Reloads the value by executing the future again.
  ///
  /// This method:
  /// 1. Sets state to `AsyncLoading`
  /// 2. Notifies listeners
  /// 3. Awaits the future
  /// 4. Updates to the result state (loaded or error)
  /// 5. Notifies listeners again
  ///
  /// Returns a `Future` that completes when the operation finishes.
  ///
  /// ```dart
  /// // Refresh the data
  /// await asyncNotifier.reload();
  ///
  /// // Or without awaiting if you don't need to wait
  /// asyncNotifier.reload();
  /// ```
  Future<void> reload() async {
    _value = AsyncLoading<T, E>();
    notifyListeners();
    final r = await future();
    _value = r;
    notifyListeners();
  }
}

/// A notifier for stream operations that emit values over time.
///
/// Use `StreamNotifier` when you need to handle continuous data streams, such as:
/// - WebSocket connections
/// - Real-time database updates
/// - Sensor data streams
/// - Any continuous data source that implements `Stream`
///
/// The notifier manages the stream subscription, automatically updating state
/// for each emitted value, handling errors, and managing completion states.
///
/// ## Example
///
/// ```dart
/// class ChatService {
///   Stream<StreamState<Message, String>> get messages {
///     return webSocketStream.map((data) => StreamLoaded(Message.fromJson(data)));
///   }
/// }
///
/// final chatNotifier = StreamNotifier<Message, String>(
///   ChatService().messages,
/// );
///
/// // In a widget:
/// ValueListenableBuilder<StreamState<Message, String>>(
///   valueListenable: chatNotifier,
///   builder: (context, state, child) {
///     return switch (state) {
///       StreamLoaded(:final value) => Text('Message: ${value.text}'),
///       StreamError(:final error) => Text('Error: $error'),
///       StreamLoading() => const CircularProgressIndicator(),
///       StreamComplete(:final lastValue) => Text('Last value: $lastValue'),
///       StreamUnloaded() => const Text('Not connected'),
///     };
///   },
/// );
///
/// // To reconnect or restart the stream:
/// chatNotifier.reload();
/// ```
class StreamNotifier<T, E> extends ChangeNotifier {
  /// Creates a stream notifier that listens to the given stream.
  ///
  /// The [stream] is a `Stream<StreamState<T, E>>` that will be listened to
  /// immediately upon creation. The notifier will update its state for each
  /// emitted value, error, or completion event.
  ///
  /// ```dart
  /// final notifier = StreamNotifier<int, String>(
  ///   someNumberStream.map((n) => StreamLoaded(n)),
  /// );
  /// ```
  StreamNotifier(this.stream) {
    _listen();
  }

  /// The stream to listen to for state updates.
  final Stream<StreamState<T, E>> stream;

  StreamSubscription<StreamState<T, E>>? _subscription;
  StreamState<T, E> _value = StreamUnloaded<T, E>();

  /// The current state of the stream operation.
  ///
  /// This will be one of:
  /// - `StreamUnloaded` - Initial state before listening
  /// - `StreamLoading` - Stream is being set up
  /// - `StreamLoaded` - A value was emitted by the stream
  /// - `StreamError` - The stream emitted an error
  /// - `StreamComplete` - The stream completed
  ///
  /// Listeners are notified whenever the state changes.
  StreamState<T, E> get value => _value;

  void _listen() {
    _subscription?.cancel();
    _value = StreamUnloaded<T, E>();
    notifyListeners();

    _subscription = stream.listen(
      (state) {
        _value = state;
        notifyListeners();
      },
      onError: (error, stackTrace) {
        _value = StreamError<T, E>(error, stackTrace: stackTrace);
        notifyListeners();
      },
      onDone: () {
        final lastValue = _value is StreamLoaded<T, E>
            ? (_value as StreamLoaded<T, E>).value
            : null;
        _value = StreamComplete<T, E>(lastValue: lastValue);
        notifyListeners();
      },
      cancelOnError:
          false, // Let onError handle errors instead of stopping the subscription
    );
  }

  /// Restarts listening to the stream from the beginning.
  ///
  /// This method:
  /// 1. Cancels any existing subscription
  /// 2. Resets the state to `StreamUnloaded`
  /// 3. Notifies listeners
  /// 4. Starts a new subscription to the stream
  ///
  /// Use this to reconnect or restart the stream connection.
  ///
  /// ```dart
  /// // Restart the stream connection
  /// streamNotifier.reload();
  /// ```
  void reload() {
    _listen();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Base sealed class for synchronous operation states.
///
/// Used as the state type for `SyncNotifier`. Subclasses represent the
/// possible states of a synchronous operation.
sealed class SyncState<T, E> {}

/// Initial state for a synchronous operation.
///
/// Represents that the synchronous operation has not been executed yet.
///
/// ```dart
/// final state = SyncUnloaded<int, String>();
/// ```
class SyncUnloaded<T, E> extends SyncState<T, E> {
  /// Creates an unloaded state.
  SyncUnloaded();
}

/// Success state for a synchronous operation.
///
/// Contains the successfully computed value from the operation.
///
/// ```dart
/// final state = SyncLoaded<int, String>(42);
/// ```
class SyncLoaded<T, E> extends SyncState<T, E> {
  /// Creates a loaded state with the given value.
  SyncLoaded(this.value);

  /// The successfully computed value.
  final T value;
}

/// Error state for a synchronous operation.
///
/// Contains the error that occurred during the operation.
///
/// ```dart
/// final state = SyncError<int, String>('Calculation failed');
/// ```
class SyncError<T, E> extends SyncState<T, E> {
  /// Creates an error state with the given error.
  SyncError(this.error);

  /// The error that occurred.
  final E error;
}

/// Base sealed class for asynchronous operation states.
///
/// Used as the state type for `AsyncNotifier`. Subclasses represent the
/// possible states of an asynchronous operation.
sealed class AsyncState<T, E> {}

/// Initial state for an asynchronous operation.
///
/// Represents that the asynchronous operation has not been executed yet.
///
/// ```dart
/// final state = AsyncUnloaded<int, String>();
/// ```
class AsyncUnloaded<T, E> extends AsyncState<T, E> {
  /// Creates an unloaded state.
  AsyncUnloaded();
}

/// Success state for an asynchronous operation.
///
/// Contains the successfully loaded value from the operation.
///
/// ```dart
/// final state = AsyncLoaded<int, String>(42);
/// ```
class AsyncLoaded<T, E> extends AsyncState<T, E> {
  /// Creates a loaded state with the given value.
  AsyncLoaded(this.value);

  /// The successfully loaded value.
  final T value;
}

/// Loading state for an asynchronous operation.
///
/// Represents that the asynchronous operation is currently in progress.
///
/// ```dart
/// final state = AsyncLoading<int, String>();
/// ```
class AsyncLoading<T, E> extends AsyncState<T, E> {
  /// Creates a loading state.
  AsyncLoading();
}

/// Error state for an asynchronous operation.
///
/// Contains the error that occurred during the asynchronous operation.
///
/// ```dart
/// final state = AsyncError<int, String>('Network error');
/// ```
class AsyncError<T, E> extends AsyncState<T, E> {
  /// Creates an error state with the given error.
  AsyncError(this.error);

  /// The error that occurred.
  final E error;
}

/// Base sealed class for stream operation states.
///
/// Used as the state type for `StreamNotifier`. Subclasses represent the
/// possible states of a stream operation.
sealed class StreamState<T, E> {}

/// Initial state for a stream operation.
///
/// Represents that the stream has not been listened to yet.
///
/// ```dart
/// final state = StreamUnloaded<int, String>();
/// ```
class StreamUnloaded<T, E> extends StreamState<T, E> {
  /// Creates an unloaded state.
  StreamUnloaded();
}

/// Loading state for a stream operation.
///
/// Represents that the stream connection is being established.
///
/// ```dart
/// final state = StreamLoading<int, String>();
/// ```
class StreamLoading<T, E> extends StreamState<T, E> {
  /// Creates a loading state.
  StreamLoading();
}

/// Value state for a stream operation.
///
/// Contains a value emitted by the stream.
///
/// ```dart
/// final state = StreamLoaded<int, String>(42);
/// ```
class StreamLoaded<T, E> extends StreamState<T, E> {
  /// Creates a loaded state with the given value.
  StreamLoaded(this.value);

  /// The value emitted by the stream.
  final T value;
}

/// Error state for a stream operation.
///
/// Contains an error emitted by the stream.
///
/// ```dart
/// final state = StreamError<int, String>(
///   'Connection lost',
///   stackTrace: StackTrace.current,
/// );
/// ```
class StreamError<T, E> extends StreamState<T, E> {
  /// Creates an error state with the given error and stack trace.
  StreamError(this.error, {required this.stackTrace});

  /// The stack trace associated with the error.
  final StackTrace stackTrace;

  /// The error that occurred.
  final E error;
}

/// Completion state for a stream operation.
///
/// Represents that the stream has completed. May contain the last value
/// emitted before completion.
///
/// ```dart
/// final state = StreamComplete<int, String>(lastValue: 42);
/// ```
class StreamComplete<T, E> extends StreamState<T, E> {
  /// Creates a completion state with an optional last value.
  StreamComplete({this.lastValue});

  /// The last value emitted by the stream before completion, if any.
  final T? lastValue;
}
