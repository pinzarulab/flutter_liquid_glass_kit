import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Switches covered glass surfaces to Flutter rendering during navigation.
///
/// Install a separate instance on each Navigator whose pushes should suppress
/// glass below them. A glass surface also checks observers on ancestor
/// Navigators, so a root dialog can cover glass in a nested Navigator.
class LiquidGlassRouteObserver extends NavigatorObserver {
  final _changes = ValueNotifier(0);
  final List<Route<dynamic>> _routes = [];
  final Map<Route<dynamic>, Set<Route<dynamic>>> _exiting = {};
  bool _notificationScheduled = false;

  bool _covers(Route<dynamic> route) {
    final index = _routes.indexOf(route);
    return (index >= 0 && index < _routes.length - 1) ||
        _exiting.values.any((routes) => routes.contains(route));
  }

  void _notifyChanged() {
    // Declarative Navigator updates can invoke observers during build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_notificationScheduled) return;
      _notificationScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notificationScheduled = false;
        _changes.value++;
      });
    } else {
      _changes.value++;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final index =
        previousRoute == null ? 0 : _routes.indexOf(previousRoute) + 1;
    _routes.insert(index, route);
    _notifyChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final index = _routes.indexOf(route);
    if (index > 0 && route is TransitionRoute<dynamic>) {
      _exiting[route] = _routes.take(index).toSet();
      route.completed.then((_) {
        _exiting.remove(route);
        _notifyChanged();
      });
    }
    _routes.remove(route);
    _notifyChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _notifyChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == null) return;
    final index = _routes.indexOf(oldRoute);
    if (index < 0) return;
    if (newRoute == null) {
      _routes.removeAt(index);
    } else {
      _routes[index] = newRoute;
      for (final routes in _exiting.values) {
        if (routes.remove(oldRoute)) routes.add(newRoute);
      }
    }
    _notifyChanged();
  }
}

/// Internal listener shared by individual surfaces and page-level hosts.
class LiquidGlassRouteVisibility extends StatelessWidget {
  const LiquidGlassRouteVisibility({super.key, required this.builder});

  final Widget Function(BuildContext context, bool visible) builder;

  @override
  Widget build(BuildContext context) {
    final routes = <LiquidGlassRouteObserver, Route<dynamic>>{};
    var route = ModalRoute.of(context);
    while (route != null) {
      final navigator = route.navigator;
      if (navigator == null) break;
      for (final observer
          in navigator.widget.observers.whereType<LiquidGlassRouteObserver>()) {
        routes[observer] = route;
      }
      route = ModalRoute.of(navigator.context);
    }
    return ListenableBuilder(
      listenable:
          Listenable.merge(routes.keys.map((observer) => observer._changes)),
      builder: (context, _) => builder(
        context,
        !routes.entries.any((entry) => entry.key._covers(entry.value)),
      ),
    );
  }
}
