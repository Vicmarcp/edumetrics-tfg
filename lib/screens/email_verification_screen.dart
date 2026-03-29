import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Pantalla que bloquea el acceso hasta que el usuario verifique su email.
/// Se muestra automáticamente desde AuthGate si el email no está verificado.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _auth = FirebaseAuth.instance;
  Timer? _checkTimer;
  bool _emailSent = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Comprobar cada 3 segundos si ya verificó
    _checkTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      if (mounted) {
        setState(() => _emailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Email de verificación enviado a ${_auth.currentUser?.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el email de verificación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkVerification() async {
    if (_checking) return;
    _checking = true;

    try {
      await _auth.currentUser?.reload();
      if (_auth.currentUser?.emailVerified == true && mounted) {
        _checkTimer?.cancel();
        // Forzar rebuild del AuthGate
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const _ReloadApp()),
              (route) => false,
        );
      }
    } catch (_) {}

    _checking = false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final email = _auth.currentUser?.email ?? '';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 4,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_unread,
                      size: 80, color: colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Verifica tu email',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Para acceder a EduMetrics necesitas verificar '
                        'tu correo electrónico.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color:
                        colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!_emailSent)
                    FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar email de verificación'),
                      onPressed: _sendVerificationEmail,
                    )
                  else
                    Column(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green, size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          'Email enviado. Revisa tu bandeja de entrada\n'
                              '(y la carpeta de spam).',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _sendVerificationEmail,
                          child: const Text('Reenviar email'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  const Text(
                    'Esta página se actualizará automáticamente\n'
                        'cuando verifiques tu email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      await _auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget temporal para forzar la recarga del AuthGate
class _ReloadApp extends StatelessWidget {
  const _ReloadApp();

  @override
  Widget build(BuildContext context) {
    // Volver al inicio de la app para que AuthGate re-evalúe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _Redirect()),
            (route) => false,
      );
    });
    return const Scaffold(
        body: Center(child: CircularProgressIndicator()));
  }
}

class _Redirect extends StatelessWidget {
  const _Redirect();

  @override
  Widget build(BuildContext context) {
    // Importar desde main.dart no es ideal, así que hacemos signOut+signIn implícito
    // La forma más limpia: volver a la ruta raíz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forzar navegación a raíz — AuthGate detectará el usuario verificado
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });
    return const Scaffold(
        body: Center(child: CircularProgressIndicator()));
  }
}