import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

  // Punto 8: App Check — verifica que las peticiones vienen de la app legítima
  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider('TU_SITE_KEY_RECAPTCHA'),
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
        return MaterialApp(
          title: 'EduMetrics',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          // Localización español
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
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),

          // Ruta raíz para redirección desde verificación de email
          routes: {'/': (_) => const AuthGate()},
          initialRoute: '/',
        );
      },
    );
  }
}

/// Gestiona sesión, verificación de email y timeout de inactividad.
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

        // No logueado → Login
        if (user == null) {
          return const LoginScreen();
        }

        // Punto 7: Email no verificado → pantalla de verificación
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // Punto 11: Envolver en control de inactividad (8 horas)
        final mode = AppModeProvider.suggestMode(context);
        return InactivityWrapper(
          timeout: const Duration(hours: 8),
          child: HomeScreen(mode: mode),
        );
      },
    );
  }
}