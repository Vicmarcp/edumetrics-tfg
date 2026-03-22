import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';

/// Controla la inactividad del usuario y cierra sesión automáticamente
/// tras un periodo configurable. Diseñado para pizarras compartidas
/// donde varios profesores usan el mismo dispositivo.
class InactivityWrapper extends StatefulWidget {
  final Widget child;

  /// Tiempo máximo de inactividad antes de cerrar sesión.
  /// Por defecto: 8 horas (jornada escolar).
  final Duration timeout;

  const InactivityWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(hours: 8),
  });

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Cuando la app vuelve al primer plano, comprueba si expiró
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExpired();
    }
  }

  void _resetTimer() {
    _lastActivity = DateTime.now();
    _timer?.cancel();
    _timer = Timer(widget.timeout, _onTimeout);
  }

  void _checkExpired() {
    final elapsed = DateTime.now().difference(_lastActivity);
    if (elapsed >= widget.timeout) {
      _onTimeout();
    }
  }

  Future<void> _onTimeout() async {
    _timer?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Ya no está logueado

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Sesión cerrada por inactividad. Inicia sesión de nuevo.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}