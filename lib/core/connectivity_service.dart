import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Servicio que monitoriza la conexión a internet.
class ConnectivityService {
  static final ValueNotifier<bool> isOnline = ValueNotifier(true);
  static StreamSubscription? _subscription;

  static void initialize() {
    final connectivity = Connectivity();

    // Estado inicial
    connectivity.checkConnectivity().then((results) {
      isOnline.value = !results.contains(ConnectivityResult.none);
    });

    // Cambios en tiempo real
    _subscription = connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      isOnline.value = !results.contains(ConnectivityResult.none);
    });
  }

  static void dispose() {
    _subscription?.cancel();
  }
}

/// Banner que aparece automáticamente cuando se pierde la conexión.
class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.isOnline,
      builder: (context, online, _) {
        return Column(
          children: [
            if (!online)
              Material(
                color: Colors.red.shade700,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.wifi_off, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sin conexión a internet. Algunas funciones pueden no estar disponibles.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
