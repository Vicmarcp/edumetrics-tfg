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
    // Escuchar cambios de tema, fuente y tamaño
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AccessibilityService.dyslexicFont,
          builder: (context, dyslexic, _) {
            return ValueListenableBuilder<double>(
              valueListenable: AccessibilityService.fontScale,
              builder: (context, scale, _) {
                final fontFamily =
                dyslexic ? 'OpenDyslexic' : null;

                return MaterialApp(
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

                  theme: ThemeData(
                    colorSchemeSeed: Colors.deepPurple,
                    useMaterial3: true,
                    brightness: Brightness.light,
                    fontFamily: fontFamily,
                  ),
                  darkTheme: ThemeData(
                    colorSchemeSeed: Colors.deepPurple,
                    useMaterial3: true,
                    brightness: Brightness.dark,
                    fontFamily: fontFamily,
                  ),

                  builder: (context, child) {
                    // Aplicar escala de fuente global
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