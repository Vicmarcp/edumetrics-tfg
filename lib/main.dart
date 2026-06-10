import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/accessibility_service.dart';
import 'core/analytics_service.dart';
import 'core/app_mode.dart';
import 'core/connectivity_service.dart';
import 'core/inactivity_service.dart';
import 'core/posthog_service.dart';
import 'firebase_options.dart';
import 'screens/email_verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Notifier global para cambiar tema claro/oscuro
final ValueNotifier<ThemeMode> themeNotifier =
ValueNotifier(ThemeMode.light);

/// DSN público de Sentry. Es semi-público por diseño (solo permite escribir
/// eventos, no leerlos). Aceptable en el repo; en el futuro lo moveremos a
/// variable de entorno cuando configuremos secrets en CI.
const _sentryDsn =
    'https://85409b0fd84fd620c74d8b8e15432d9a@o4511438008287232.ingest.de.sentry.io/4511438017724496';

Future<void> main() async {
  await SentryFlutter.init(
        (options) {
      options.dsn = _sentryDsn;

      // Sentry separa issues por entorno: 'production' en release,
      // 'development' en debug local. Así no se mezclan errores reales
      // con bugs de desarrollo.
      options.environment = kReleaseMode ? 'production' : 'development';

      // Captura el 10% de las transacciones de performance (no errores).
      // Cuidamos la cuota del plan gratuito.
      options.tracesSampleRate = 0.1;

      // En debug imprime logs internos de Sentry en consola; en release no.
      options.debug = kDebugMode;
      // Release tracking: cada build se etiqueta con su SHA de Git.
      // Esto permite saber en qué deploy exacto apareció cada error
      // y ver el diff con la versión anterior cuando se rompe algo.
      const release = String.fromEnvironment('SENTRY_RELEASE');
      if (release.isNotEmpty) {
        options.release = 'edumetrics@$release';
      }
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      try {
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider(
              '6Ld53JMsAAAAALhBVb4aPtHr01xeBxjqFmbmnI4M'),
        );
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        ConnectivityService.initialize();
      } catch (e, stack) {
        // Antes era `catch (_) {}` y se perdía el error en silencio.
        // Ahora lo mandamos a Sentry para poder diagnosticarlo si ocurre.
        await Sentry.captureException(e, stackTrace: stack);
      }

      runApp(const EduMetricsApp());
    },
  );
}

class EduMetricsApp extends StatelessWidget {
  const EduMetricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AccessibilityService.dyslexicFont,
          builder: (context, dyslexic, _) {
            return ValueListenableBuilder<double>(
              valueListenable: AccessibilityService.fontScale,
              builder: (context, scale, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: AccessibilityService.highContrast,
                  builder: (context, highContrast, _) {
                    final fontFamily = dyslexic ? 'OpenDyslexic' : null;

                    return MaterialApp(
                      title: 'EduMetrics',
                      debugShowCheckedModeBanner: false,
                      navigatorObservers: [AnalyticsService.observer],
                      themeMode: currentMode,
                      locale: const Locale('es', 'ES'),
                      supportedLocales: const [Locale('es', 'ES')],
                      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      theme: _buildTheme(
                        Brightness.light,
                        fontFamily,
                        highContrast,
                      ),
                      darkTheme: _buildTheme(
                        Brightness.dark,
                        fontFamily,
                        highContrast,
                      ),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(scale),
                          ),
                          child: child!,
                        );
                      },
                      initialRoute: '/',
                      routes: {
                        '/': (_) => const ConnectivityBanner(child: AuthGate()),
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness, String? fontFamily,
      bool highContrast) {
    final base = ThemeData(
      colorSchemeSeed: Colors.deepPurple,
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
    );

    if (!highContrast) return base;

    // Alto contraste: bordes gruesos, textos más pesados
    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: brightness == Brightness.light
                ? Colors.black54
                : Colors.white54,
            width: 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          side: BorderSide(
            color: brightness == Brightness.light
                ? Colors.black45
                : Colors.white54,
            width: 2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            width: 3,
            color: brightness == Brightness.light
                ? Colors.black45
                : Colors.white54,
          ),
        ),
      ),
      textTheme: base.textTheme,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Sincroniza Sentry y PostHog con el estado de autenticación.
        if (user != null) {
          Sentry.configureScope((scope) {
            scope.setUser(SentryUser(
              id: user.uid,
              // email: user.email, // RGPD: no enviamos email
            ));
          });
          PosthogService.identify(user.uid);
        } else {
          Sentry.configureScope((scope) => scope.setUser(null));
          PosthogService.reset();
        }

        if (user == null) {
          return const LoginScreen();
        }

        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        final mode = AppModeProvider.suggestMode(context);
        return InactivityWrapper(
          timeout: const Duration(hours: 8),
          child: HomeScreen(mode: mode),
        );
      },
    );
  }
}