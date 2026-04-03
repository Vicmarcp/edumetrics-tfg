import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/accessibility_service.dart';
import 'core/app_mode.dart';
import 'core/inactivity_service.dart';
import 'firebase_options.dart';
import 'screens/email_verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Notifier global para cambiar tema claro/oscuro
final ValueNotifier<ThemeMode> themeNotifier =
ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider(''),
  );

  runApp(const EduMetricsApp());
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
              builder: (context, scale, _) {eturn ValueListenableBuilder<bool>(
                  valueListenable: AccessibilityService.highContrast,
                  builder: (context, highContrast, _) {
                    final fontFamily = dyslexic ? 'OpenDyslexic' : null;

                    rreturn MaterialApp(
                      title: 'EduMetrics',
                      debugShowCheckedModeBanner: false,
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

                      routes: {'/': (_) => const AuthGate()},
                      initialRoute: '/',
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