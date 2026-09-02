import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/app/auth_gate.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/auth/auth_state.dart';
import 'package:tabala/src/app_scope.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/localization/app_localization.dart';
import 'package:tabala/src/theme/app_theme_provider.dart';
import 'package:tabala/src/theme/app_themes.dart';
import 'package:tabala/src/theme/theme_signal.dart';

import 'api/overrides.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  // intl needs per-locale symbol tables loaded before DateFormat can render
  // Arabic month and weekday names. Without this the first `DateFormat(...,
  // 'ar')` throws a LocaleDataException - and since nearly every screen
  // formats a date, the Arabic build white-screens on the home page.
  await initializeDateFormatting();

  runApp(
    EasyLocalization(
      supportedLocales: AppLocalization.supportedLocales,
      path: AppLocalization.translationsPath,
      fallbackLocale: AppLocalization.fallbackLocale,
      startLocale: AppLocalization.fallbackLocale,
      child: const TabalahApp(),
    ),
  );
}

class TabalahApp extends StatelessWidget {
  const TabalahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        BlocProvider<AuthCubit>(
          create: (_) {
            final cubit = AuthCubit();
            // Any 401 anywhere in the app (expired or revoked token) drops
            // the user back to the login flow. The backend deletes all of a
            // user's tokens on login and on password reset, so this fires
            // legitimately whenever they sign in elsewhere.
            ApiClient.instance.onUnauthorized = () => cubit.forceLogout();
            return cubit;
          },
        ),
      ],
      child: const _AppShell(),
    );
  }
}

/// Owns theme resolution for the whole app.
///
/// Three things have to happen in a specific order for a theme switch to be
/// correct, and getting the order wrong is what made the previous version
/// only half-repaint:
///
/// 1. **Resolve the real brightness first.** `ThemeMode.system` has to be
///    turned into an actual light/dark answer *before* anything reads it.
///    That answer comes from the platform, which this widget observes
///    directly rather than through MediaQuery - MediaQuery only exists
///    below MaterialApp, and the themes are built above it.
///
/// 2. **Publish it to ThemeSignal before building ThemeData.** AppThemes
///    builds its TextTheme out of AppStyles, and AppStyles asks ThemeSignal
///    which ink to use. Syncing after that point left the AppBar title, and
///    every other themed default, one frame behind - which is exactly the
///    "dark text on a dark bar" in the screenshots.
///
/// 3. **Hand MaterialApp a single resolved theme.** Passing
///    theme + darkTheme + ThemeMode.system means Flutter resolves the mode a
///    second time, internally, and the two answers can disagree. Resolving
///    once here means `Theme.of(context).brightness` below always matches
///    what ThemeSignal says.
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  late Brightness _platformBrightness;

  /// Needed because the route stack has to be unwound from outside any
  /// particular screen - see the BlocListener below.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _platformBrightness = PlatformDispatcher.instance.platformBrightness;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final next = PlatformDispatcher.instance.platformBrightness;
    if (next != _platformBrightness) {
      setState(() => _platformBrightness = next);
    }
  }

  Brightness _resolve(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return _platformBrightness;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, _) {
        final brightness = _resolve(themeProvider.mode);
        final isDark = brightness == Brightness.dark;

        // Step 2: publish before the themes are constructed on the next line.
        ThemeSignal.sync(brightness: brightness, locale: context.locale);

        // The API answers admin-authored catalogue text in whichever
        // language this says, so it has to be current before any screen
        // below fires its first request.
        AppScope.locale = context.locale.languageCode;

        final theme = isDark ? AppThemes.dark() : AppThemes.light();

        _applySystemChrome(isDark);

        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,

          // Step 3: one resolved theme, and a themeMode that cannot
          // re-resolve it differently.
          theme: theme,
          themeMode: ThemeMode.light,

          // The key is the important part here, and it is deliberate.
          //
          // Colours in this app come from static getters (AppColors.x,
          // AppStyles.x) that consult ThemeSignal at build time, rather than
          // from an InheritedWidget. Nothing registers a dependency, so
          // nothing is *obliged* to rebuild when the theme flips - and any
          // subtree that happens not to rebuild keeps painting the old
          // theme's colours. That is how a dark nav bar ends up sitting under
          // a light page in the same frame.
          //
          // Making the widgets non-const (the previous attempt) removes the
          // const short-circuit, but it still relies on every subtree
          // actually rebuilding, and anything held by a builder, an overlay
          // entry, a route below the top one, or a child that rebuilds on its
          // own schedule can still be carrying stale values.
          //
          // Keying the whole tree on brightness removes the entire class of
          // bug instead of narrowing it: on a theme change the old element
          // tree is discarded and rebuilt from scratch, so *every* widget in
          // the app is guaranteed to have been built after the current
          // ThemeSignal value was published. The cost is that screen state is
          // rebuilt on a theme switch - tabs return to the first entry and
          // visible screens refetch. That is a deliberate trade: theme
          // switching is a rare, explicit user action, and a correct repaint
          // is worth more than a preserved scroll offset.
          home: KeyedSubtree(
            // Locale is part of the key for the same reason brightness is,
            // plus one of its own: sport and membership names come from the
            // server already translated, so switching language has to
            // *refetch*, not just re-render. Rebuilding the tree makes every
            // screen reload through the new `X-App-Locale`, which is the
            // difference between an English app and an English app full of
            // Arabic card titles.
            key: ValueKey('$brightness|${context.locale.languageCode}'),
            // Whenever the session starts or ends, unwind to the root route.
            //
            // AuthGate renders the portal at route 0, but the auth screens
            // above it are *pushed* - so signing in swapped what route 0
            // showed while LoginView stayed on top of it, and the user was
            // left looking at the login form over an app they were already
            // signed in to. Refreshing "fixed" it only because a restart has
            // no pushed routes to begin with.
            //
            // This used to be a popUntil inside LoginView's own listener,
            // which made correct navigation depend on one screen surviving
            // and firing at the right moment. Registration went through a
            // different state and logout did no popping at all, so a 401
            // force-logout left screens like checkout or session detail
            // stranded on top of the login form.
            //
            // Doing it here covers every entry and exit once, from outside
            // any screen that might be torn down mid-transition.
            child: BlocListener<AuthCubit, AuthState>(
              listenWhen: (previous, current) =>
                  (current is AuthAuthenticated &&
                      previous is! AuthAuthenticated) ||
                  (current is AuthUnauthenticated &&
                      previous is! AuthUnauthenticated),
              listener: (context, state) {
                // Deferred to after the frame. The state can change while a
                // route is still animating in - verifying a code pushes and
                // authenticates almost together - and popping mid-transition
                // leaves the route that is still arriving on top of the
                // stack. That is the "it worked after I restarted the app"
                // symptom: a restart simply has no stranded routes.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _navigatorKey.currentState?.popUntil((route) => route.isFirst);
                });
              },
              child: AuthGate(),
            ),
          ),
        );
      },
    );
  }

  void _applySystemChrome(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: AppColors.scaffoldcolor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
