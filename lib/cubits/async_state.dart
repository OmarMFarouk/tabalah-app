import 'package:equatable/equatable.dart';

/// One state shape for every "fetch something and show it" cubit.
///
/// The original code declared four hand-written classes per feature
/// (Initial / Loading / Loaded / Error), which is a lot of surface area for
/// no variation. This collapses them into a single sealed-ish family with a
/// typed payload, so a view can write:
///
/// ```dart
/// AsyncStateView(
///   isLoading: state.isBusy,
///   errorMessage: state.error,
///   child: state.hasData ? _content(state.data!) : const SizedBox(),
/// )
/// ```
///
/// [isRefreshing] matters for pull-to-refresh: on a refresh the previous
/// data stays in [data] while the request is in flight, so the list does not
/// blink out to a spinner underneath the user's finger.
class AsyncState<T> extends Equatable {
  final T? data;
  final String? error;
  final bool isLoading;
  final bool isRefreshing;

  const AsyncState._({
    this.data,
    this.error,
    this.isLoading = false,
    this.isRefreshing = false,
  });

  const AsyncState.idle() : this._();

  const AsyncState.loading() : this._(isLoading: true);

  const AsyncState.refreshing(T? previous)
      : this._(data: previous, isRefreshing: true);

  const AsyncState.ready(T value) : this._(data: value);

  const AsyncState.failed(String message, {T? previous})
      : this._(data: previous, error: message);

  bool get hasData => data != null;

  bool get hasError => error != null;

  /// True when a spinner should replace the content entirely - i.e. a first
  /// load, not a refresh over existing data.
  bool get isBusy => isLoading && !hasData;

  AsyncState<T> toRefreshing() => AsyncState.refreshing(data);

  @override
  List<Object?> get props => [data, error, isLoading, isRefreshing];
}
