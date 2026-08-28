import 'package:core_navigation/core_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';

/// What draws one destination, given the path segments it was reached with.
///
/// Not a `WidgetBuilder`, because half the screens in this product need a
/// value out of the URL: which thread, which parcel, which kind of document.
/// A `Map<String, String>` rather than `GoRouterState`, so that a test can
/// call a builder without a router — and so the type does not name the router
/// library this app happens to use.
typedef ScreenBuilder =
    Widget Function(BuildContext context, Map<String, String> parameters);

/// Turns the route modules a set of features published into one router.
///
/// This is the assembly §5's scenario 5 describes at the route level: each
/// presentation package declares `RouteDefinition`s and knows nothing about
/// routers; the app collects them and builds one. `app_courier` and
/// `app_dispatcher` include different modules and neither feature notices.
///
/// It lives in the app rather than in `core_navigation` because `go_router` is
/// a choice, and a choice made in `core_navigation` would be a choice made for
/// every app forever.
final class PeykRouter {
  /// Builds a router over [modules].
  ///
  /// [screens] maps a route name to what draws it. Kept separate from the
  /// definitions on purpose: a `RouteDefinition` is pure Dart and cannot carry
  /// a widget, which is exactly what lets a presentation package declare where
  /// it can be reached without depending on a router library.
  PeykRouter({
    required List<RouteModule> modules,
    required Map<String, ScreenBuilder> screens,
    required SessionReader sessions,
    required PermissionChecker permissions,
    required String signInRoute,
    required String homeRoute,
  }) : this._(
         definitions: _collect(modules),
         screens: screens,
         sessions: sessions,
         permissions: permissions,
         signInRoute: signInRoute,
         homeRoute: homeRoute,
       );

  /// The real constructor.
  ///
  /// It exists so that `_collect` can run before the fields are assigned —
  /// a redirecting generative constructor is the only place a computed value
  /// and initializing formals can both be used.
  const PeykRouter._({
    required Map<String, RouteDefinition> definitions,
    required Map<String, ScreenBuilder> screens,
    required SessionReader sessions,
    required PermissionChecker permissions,
    required String signInRoute,
    required String homeRoute,
  }) : _definitions = definitions,
       _screens = screens,
       _sessions = sessions,
       _permissions = permissions,
       _signInRoute = signInRoute,
       _homeRoute = homeRoute;
  // The private constructor's parameters are named without the leading
  // underscore so that the redirecting constructor above can pass them by
  // name; `prefer_initializing_formals` wants `this._sessions` instead, which
  // would make the call site read `_sessions: sessions`. Naming a private
  // field in a public constructor call is worse than the lint.
  // ignore_for_file: prefer_initializing_formals

  final Map<String, RouteDefinition> _definitions;
  final Map<String, ScreenBuilder> _screens;
  final SessionReader _sessions;
  final PermissionChecker _permissions;
  final String _signInRoute;
  final String _homeRoute;

  /// Every destination this app assembled, by name.
  Map<String, RouteDefinition> get definitions =>
      Map.unmodifiable(_definitions);

  /// The names this app has no screen for.
  ///
  /// A route declared by a module the app included and never given a builder
  /// is a route that resolves to a blank page. The container test asserts this
  /// is empty, which is the cheapest possible catch for "we added a screen to
  /// a feature and forgot to mount it".
  Set<String> get unmounted =>
      _definitions.keys.toSet().difference(_screens.keys.toSet());

  /// Where [name] should send somebody, or null when they may go there.
  ///
  /// Public and pure so that the guard can be tested without a router: the
  /// interesting cases are "no session" and "no permission", and neither needs
  /// a widget tree to be wrong in.
  String? redirectFor(String name) {
    final definition = _definitions[name];
    if (definition == null) {
      return null;
    }

    final session = _sessions.current;
    if (definition.requiresSession && session == null) {
      return _definitions[_signInRoute]?.path;
    }
    // Somebody signed in who lands on sign-in goes home instead, or they are
    // stuck on a screen whose only action they have already taken.
    if (!definition.requiresSession && session != null) {
      return _definitions[_homeRoute]?.path;
    }

    final required = definition.requiredPermission;
    if (required == null) {
      return null;
    }
    // Scenario 6 at the route level: the definition names a permission as a
    // string because core_navigation may not see identity_api, and the app is
    // where the string meets the port.
    final permission = Permission.values
        .where((it) => it.name == required)
        .firstOrNull;
    assert(
      permission != null,
      'Route "$name" requires "$required", which is not a Permission. '
      'A route guarding on a permission nobody grants is a route nobody '
      'reaches.',
    );
    if (permission == null || _permissions.can(permission)) {
      return null;
    }
    return _definitions[_homeRoute]?.path;
  }

  /// The router itself.
  GoRouter build() => GoRouter(
    initialLocation: _definitions[_homeRoute]?.path ?? '/',
    routes: [
      for (final definition in _definitions.values)
        GoRoute(
          name: definition.name,
          path: definition.path,
          builder: (context, state) =>
              _screens[definition.name]?.call(
                context,
                state.pathParameters,
              ) ??
              const SizedBox.shrink(),
          redirect: (context, state) => redirectFor(definition.name),
        ),
    ],
  );

  /// Collects every module's definitions, refusing a collision.
  ///
  /// Two modules declaring the same route name is a wiring mistake that
  /// otherwise shows up as one feature's screen appearing under another
  /// feature's URL. The assertion names both modules, because the fix is to
  /// rename one and you have to know which two.
  static Map<String, RouteDefinition> _collect(List<RouteModule> modules) {
    final byName = <String, RouteDefinition>{};
    final owners = <String, String>{};

    for (final module in modules) {
      for (final definition in module.routes) {
        assert(
          !byName.containsKey(definition.name),
          'Route "${definition.name}" is declared by both '
          '"${owners[definition.name]}" and "${module.moduleName}".',
        );
        byName[definition.name] = definition;
        owners[definition.name] = module.moduleName;
      }
    }
    return byName;
  }
}
