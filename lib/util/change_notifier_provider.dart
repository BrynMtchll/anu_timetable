import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// extension for [ChangeNotifierProxyProvider7] copy pasted from source.

// ignore: public_member_api_docs
typedef ProxyProviderBuilder7<T, T2, T3, T4, T5, T6, T7, R> = R Function(
  BuildContext context,
  T value,
  T2 value2,
  T3 value3,
  T4 value4,
  T5 value5,
  T6 value6,
  T7 value7,
  R? previous,
);

/// {@macro provider.listenableproxyprovider}
class ListenableProxyProvider7<T, T2, T3, T4, T5, T6, T7, R extends Listenable?>
    extends ListenableProxyProvider0<R> {
  /// Initializes [key] for subclasses.
  ListenableProxyProvider7({
    Key? key,
    Create<R>? create,
    required ProxyProviderBuilder7<T, T2, T3, T4, T5, T6, T7, R> update,
    Dispose<R>? dispose,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          lazy: lazy,
          builder: builder,
          update: (context, previous) => update(
            context,
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            Provider.of(context),
            previous,
          ),
          dispose: dispose,
          child: child,
        );
}

class _ChangeNotifierProvider<T extends ChangeNotifier?>
    extends ListenableProvider<T> {
  /// Creates a [ChangeNotifier] using `create` and automatically
  /// disposes it when [_ChangeNotifierProvider] is removed from the widget tree.
  ///
  /// `create` must not be `null`.
  _ChangeNotifierProvider({
    Key? key,
    required Create<T> create,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          dispose: _dispose,
          lazy: lazy,
          builder: builder,
          child: child,
        );

  /// Provides an existing [ChangeNotifier].
  _ChangeNotifierProvider.value({
    Key? key,
    required T value,
    TransitionBuilder? builder,
    Widget? child,
  }) : super.value(
          key: key,
          builder: builder,
          value: value,
          child: child,
        );

  static void _dispose(BuildContext context, ChangeNotifier? notifier) {
    notifier?.dispose();
  }
}

/// {@macro provider.changenotifierproxyprovider}
class ChangeNotifierProxyProvider7<T, T2, T3, T4, T5, T6, T7,
        R extends ChangeNotifier?>
    extends ListenableProxyProvider7<T, T2, T3, T4, T5, T6, T7, R> {
  /// Initializes [key] for subclasses.
  ChangeNotifierProxyProvider7({
    Key? key,
    required Create<R> create,
    required ProxyProviderBuilder7<T, T2, T3, T4, T5, T6, T7, R> update,
    bool? lazy,
    TransitionBuilder? builder,
    Widget? child,
  }) : super(
          key: key,
          create: create,
          update: update,
          dispose: _ChangeNotifierProvider._dispose,
          lazy: lazy,
          builder: builder,
          child: child,
        );
}