import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';

import 'backend/api/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FlutterFlowTheme.initialize();

  final authState = AuthState();
  await authState.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: authState),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = ThemeMode.light;
        FlutterFlowTheme.saveThemeMode(ThemeMode.light);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ForCivil Builder',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      locale: const Locale('es'),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF333333),
          primary: const Color(0xFF333333),
          onPrimary: const Color(0xFFFDFDFD),
          secondary: const Color(0xFF5BC3D5),
          onSecondary: const Color(0xFF1E1E1E),
          background: const Color(0xFFFFFFFF),
          onBackground: const Color(0xFF1E1E1E),
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF1E1E1E),
          error: const Color(0xFFE85C4A),
          onError: const Color(0xFFFDFDFD),
          brightness: Brightness.light,
        ),
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF333333),
          primary: const Color(0xFFFDFDFD),
          onPrimary: const Color(0xFF1E1E1E),
          secondary: const Color(0xFF5BC3D5),
          onSecondary: const Color(0xFF1E1E1E),
          background: const Color(0xFF1E1E1E),
          onBackground: const Color(0xFFFDFDFD),
          surface: const Color(0xFF27272A),
          onSurface: const Color(0xFFF4F4F5),
          error: const Color(0xFFE85C4A),
          onError: const Color(0xFFFDFDFD),
          brightness: Brightness.dark,
        ),
        useMaterial3: false,
      ),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
