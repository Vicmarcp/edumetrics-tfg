import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/accessibility_service.dart';
import '../core/audit_service.dart';
import '../core/backup_service.dart';
import '../core/demo_data_screen.dart';
import '../core/ui_helpers.dart';
import '../main.dart';
import 'legal_notice_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _userData = doc.data();
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _schoolId => _userData?['schoolId'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _loading
          ? const ListSkeleton(itemCount: 5)
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Cuenta', icon: Icons.person),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.email,
                    label: 'Correo electrónico',
                    value: user?.email ?? 'No disponible',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.verified,
                    label: 'Email verificado',
                    value: user?.emailVerified == true ? 'Sí' : 'No',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.school,
                    label: 'Centro escolar',
                    value: _schoolId.isEmpty ? 'No asignado' : _schoolId,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.badge,
                    label: 'Nombre',
                    value: _userData?['name'] ??
                        user?.displayName ??
                        'No definido',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Apariencia', icon: Icons.palette),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? Colors.amber : Colors.blueGrey,
              ),
              title: const Text('Modo oscuro'),
              subtitle: Text(isDark ? 'Activado' : 'Desactivado'),
              value: isDark,
              onChanged: (value) {
                themeNotifier.value =
                value ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),

          const SizedBox(height: 24),

          _SectionHeader(
              title: 'Accesibilidad', icon: Icons.accessibility_new),
          Card(
            child: Column(
              children: [
                // Sonidos
                ValueListenableBuilder<bool>(
                  valueListenable: AccessibilityService.soundEnabled,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      secondary: Icon(
                        enabled ? Icons.volume_up : Icons.volume_off,
                        color: enabled ? Colors.blue : Colors.grey,
                      ),
                      title: const Text('Sonidos de actividad'),
                      subtitle: Text(enabled
                          ? 'Sonido al acertar y fallar'
                          : 'Sonidos desactivados'),
                      value: enabled,
                      onChanged: (value) {
                        AccessibilityService.soundEnabled.value = value;
                      },
                    );
                  },
                ),
                const Divider(height: 1),

                // Narración por voz
                ValueListenableBuilder<bool>(
                  valueListenable: AccessibilityService.ttsEnabled,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      secondary: Icon(
                        Icons.record_voice_over,
                        color: enabled ? Colors.green : Colors.grey,
                      ),
                      title: const Text('Narración por voz'),
                      subtitle: Text(enabled
                          ? 'Lee las preguntas en voz alta'
                          : 'Narración desactivada'),
                      value: enabled,
                      onChanged: (value) {
                        AccessibilityService.ttsEnabled.value = value;
                        if (value) {
                          AccessibilityService.speak(
                              'Narración activada');
                        }
                      },
                    );
                  },
                ),
                const Divider(height: 1),

                // Fuente dislexia
                ValueListenableBuilder<bool>(
                  valueListenable: AccessibilityService.dyslexicFont,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      secondary: Icon(
                        Icons.font_download,
                        color: enabled ? Colors.purple : Colors.grey,
                      ),
                      title: const Text('Fuente para dislexia'),
                      subtitle: Text(enabled
                          ? 'OpenDyslexic activada'
                          : 'Fuente estándar'),
                      value: enabled,
                      onChanged: (value) {
                        AccessibilityService.dyslexicFont.value = value;
                      },
                    );
                  },
                ),
                const Divider(height: 1),

                // Alto contraste
                ValueListenableBuilder<bool>(
                  valueListenable: AccessibilityService.highContrast,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      secondary: Icon(
                        Icons.contrast,
                        color: enabled ? Colors.amber : Colors.grey,
                      ),
                      title: const Text('Alto contraste'),
                      subtitle: Text(enabled
                          ? 'Bordes gruesos y texto más visible'
                          : 'Contraste estándar'),
                      value: enabled,
                      onChanged: (value) {
                        AccessibilityService.highContrast.value = value;
                      },
                    );
                  },
                ),
                const Divider(height: 1),

                // Modo daltónico
                ValueListenableBuilder<bool>(
                  valueListenable: AccessibilityService.colorblindMode,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      secondary: Icon(
                        Icons.remove_red_eye,
                        color: enabled ? Colors.teal : Colors.grey,
                      ),
                      title: const Text('Modo daltónico'),
                      subtitle: Text(enabled
                          ? 'Colores seguros (azul/naranja)'
                          : 'Colores estándar (verde/rojo)'),
                      value: enabled,
                      onChanged: (value) {
                        AccessibilityService.colorblindMode.value =
                            value;
                      },
                    );
                  },
                ),
                const Divider(height: 1),

                // Tamaño de fuente
                ValueListenableBuilder<double>(
                  valueListenable: AccessibilityService.fontScale,
                  builder: (context, scale, _) {
                    final label = scale < 0.9
                        ? 'Pequeño'
                        : scale > 1.1
                        ? 'Grande'
                        : 'Normal';
                    return ListTile(
                      leading: const Icon(Icons.text_fields),
                      title: const Text('Tamaño de texto'),
                      subtitle: Text('Actual: $label'),
                      trailing: SizedBox(
                        width: 200,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'small',
                                label: Text('A',
                                    style: TextStyle(fontSize: 12))),
                            ButtonSegment(
                                value: 'normal',
                                label: Text('A',
                                    style: TextStyle(fontSize: 16))),
                            ButtonSegment(
                                value: 'large',
                                label: Text('A',
                                    style: TextStyle(fontSize: 20))),
                          ],
                          selected: {
                            AccessibilityService.currentFontSizeLabel
                          },
                          onSelectionChanged: (v) {
                            AccessibilityService.setFontSize(v.first);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Seguridad', icon: Icons.lock),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Cambiar contraseña'),
                  subtitle:
                  const Text('Actualiza tu contraseña actual'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Recuperar contraseña'),
                  subtitle:
                  const Text('Enviar email de restablecimiento'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _sendPasswordResetEmail(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
              title: 'Privacidad y datos', icon: Icons.privacy_tip),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Política de Privacidad'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                  const Icon(Icons.download, color: Colors.blue),
                  title: const Text('Solicitar mis datos'),
                  subtitle:
                  const Text('Información personal (RGPD)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _requestDataExport(context),
                ),
                const Divider(height: 1),
                // Punto 14: Retención de datos
                ListTile(
                  leading: const Icon(Icons.auto_delete,
                      color: Colors.orange),
                  title: const Text('Retención de datos'),
                  subtitle: const Text(
                      'Eliminar resultados antiguos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDataRetentionDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever,
                      color: Colors.red),
                  title: const Text('Eliminar mi cuenta y datos',
                      style: TextStyle(color: Colors.red)),
                  subtitle: const Text(
                      'Acción irreversible — elimina todo'),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.red),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download, color: Colors.blue),
                  title: const Text('Descargar backup del centro'),
                  subtitle: const Text(
                      'Exporta todos los datos en JSON (RGPD Art. 20)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          AlertDialog(
                            title: const Text('Descargar backup'),
                            content: const Text(
                                'Se generará un archivo JSON con todos los alumnos '
                                    'y resultados de tu centro. Custódialo con cuidado: '
                                    'contiene datos personales protegidos por RGPD.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar')),
                              FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Descargar')),
                            ],
                          ),
                    );
                    if (confirm != true || !context.mounted) return;

                    final result = await BackupService.exportFullBackup();
                    if (!context.mounted) return;
                    if (result.startsWith('OK')) {
                      AppSnackbar.success(context, 'Backup descargado');
                    } else {
                      AppSnackbar.error(context, result);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel),
                  title: const Text('Aviso legal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LegalNoticeScreen()),
                      ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Términos de uso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TermsOfUseScreen()),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Sesión', icon: Icons.exit_to_app),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.timer, color: Colors.blue),
                  title: Text('Timeout de sesión'),
                  subtitle: Text(
                      'La sesión se cierra automáticamente tras 8 horas de inactividad'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                  const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar sesión',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text('EduMetrics v1.0.0 — TFG 2025/2026',
                style:
                TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Desarrollo', icon: Icons.code),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science, color: Colors.purple),
              title: const Text('Datos de demo'),
              subtitle: const Text('Generar/eliminar datos para pruebas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DemoDataScreen()),
                  ),
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Acerca de', icon: Icons.info_outline),
          Card(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData
                    ? '${snapshot.data!.version} (build ${snapshot.data!
                    .buildNumber})'
                    : 'Cargando...';
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.numbers),
                      title: const Text('Versión'),
                      subtitle: Text(version),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.school),
                      title: const Text('EduMetrics'),
                      subtitle: const Text(
                          'Sistema de evaluación para Educación Primaria'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Tecnologías'),
                      subtitle: const Text(
                          'Flutter Web · Firebase · Material Design 3'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Punto 14: Diálogo de retención de datos ───
  void _showDataRetentionDialog(BuildContext context) {
    String selectedPeriod = '2_years';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_delete, color: Colors.orange),
              SizedBox(width: 8),
              Text('Retención de datos'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona el periodo de retención. Los resultados '
                    'más antiguos serán eliminados permanentemente.',
              ),
              const SizedBox(height: 8),
              Text(
                'Esta acción cumple con la política de minimización '
                    'de datos del RGPD (Art. 5.1.e).',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selectedPeriod,
                onChanged: (v) =>
                    setDialogState(() => selectedPeriod = v!),
                child: Column(
                  children: const [
                    RadioListTile<String>(
                      title: Text('Más de 6 meses'),
                      value: '6_months',
                    ),
                    RadioListTile<String>(
                      title: Text('Más de 1 año'),
                      value: '1_year',
                    ),
                    RadioListTile<String>(
                      title: Text('Más de 2 años'),
                      value: '2_years',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.pop(context);
                _executeDataRetention(context, selectedPeriod);
              },
              child: const Text('Eliminar datos antiguos'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeDataRetention(
      BuildContext context, String period) async {
    if (_schoolId.isEmpty) return;

    final now = DateTime.now();
    DateTime cutoff;
    switch (period) {
      case '6_months':
        cutoff = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1_year':
        cutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        cutoff = DateTime(now.year - 2, now.month, now.day);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final oldResults = await FirebaseFirestore.instance
          .collection('results')
          .where('schoolId', isEqualTo: _schoolId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      if (oldResults.docs.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          AppSnackbar.info(
            context,
            'No hay resultados anteriores al periodo seleccionado',
          );
        }
        return;
      }

      // Firestore batch limit: 500 operaciones
      const maxBatch = 500;
      var batch = FirebaseFirestore.instance.batch();
      var count = 0;

      for (final doc in oldResults.docs) {
        if (count >= maxBatch) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
        batch.delete(doc.reference);
        count++;
      }
      if (count > 0) await batch.commit();

      // Punto 15: Registrar en auditoría
      await AuditService.log(
        action: 'data_retention_purge',
        targetId: _schoolId,
        details: {
          'period': period,
          'cutoff_date': cutoff.toIso8601String(),
          'results_deleted': oldResults.docs.length,
        },
      );

      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.success(
          context,
          '${oldResults.docs.length} resultados antiguos eliminados',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.error(
          context,
          'Error al obtener los datos. Inténtalo de nuevo.',
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Introduce tu contraseña actual'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Introduce la nueva contraseña';
                    }
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    if (!v.contains(RegExp(r'[A-Z]'))) {
                      return 'Debe contener al menos una mayúscula';
                    }
                    if (!v.contains(RegExp(r'[0-9]'))) {
                      return 'Debe contener al menos un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: Icon(Icons.lock_clock),
                  ),
                  validator: (v) {
                    if (v != newController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final user = _auth.currentUser;
                if (user == null || user.email == null) {
                  if (context.mounted) {
                    AppSnackbar.error(
                      context,
                      'Sesión expirada. Inicia sesión de nuevo.',
                    );
                  }
                  return;
                }
                try {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppSnackbar.success(
                      context,
                      'Contraseña actualizada correctamente',
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  String msg = 'Error al cambiar la contraseña';
                  if (e.code == 'wrong-password') {
                    msg = 'La contraseña actual es incorrecta';
                  } else if (e.code == 'weak-password') {
                    msg = 'La nueva contraseña es demasiado débil';
                  }
                  if (context.mounted) {
                    AppSnackbar.error(context, msg);
                  }
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    final email = _auth.currentUser?.email;
    if (email == null) return;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        AppSnackbar.success(
          context,
          'Email de recuperación enviado a $email',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Error al enviar el email de recuperación');
      }
    }
  }

  Future<void> _requestDataExport(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_schoolId.isEmpty) {
      AppSnackbar.warning(context, 'No tienes un centro escolar asignado');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final studentsSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: _schoolId)
          .get();

      final studentIds = studentsSnap.docs.map((d) => d.id).toList();
      int totalResults = 0;
      if (studentIds.isNotEmpty) {
        const batchSize = 30;
        for (var i = 0; i < studentIds.length; i += batchSize) {
          final batch = studentIds.sublist(i,
              i + batchSize > studentIds.length ? studentIds.length : i + batchSize);
          final resultsSnap = await FirebaseFirestore.instance
              .collection('results')
              .where('schoolId', isEqualTo: _schoolId)
              .where('studentId', whereIn: batch)
              .get();
          totalResults += resultsSnap.size;
        }
      }

      // Punto 15: Log de exportación de datos
      await AuditService.log(
        action: 'export_data',
        targetId: user.uid,
        details: {'students': studentsSnap.size, 'results': totalResults},
      );

      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Tus datos en EduMetrics'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Resumen de datos almacenados:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _DataItem('Email', user.email ?? '-'),
                  _DataItem(
                      'Nombre', userDoc.data()?['name'] ?? 'No definido'),
                  _DataItem('Centro escolar', _schoolId),
                  _DataItem(
                      'Fecha de registro',
                      user.metadata.creationTime
                          ?.toLocal()
                          .toString()
                          .substring(0, 10) ??
                          '-'),
                  _DataItem('Alumnos asociados', '${studentsSnap.size}'),
                  _DataItem('Resultados registrados', '$totalResults'),
                  const SizedBox(height: 16),
                  Text(
                    'Conforme al RGPD, estos son los datos personales '
                        'que EduMetrics almacena vinculados a tu cuenta.',
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.error(
          context,
          'Error al obtener los datos. Inténtalo de nuevo.',
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Eliminar cuenta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta acción es IRREVERSIBLE. Se eliminarán:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('• Tu cuenta de usuario'),
            const Text('• Todos los alumnos asociados'),
            const Text('• Todos los resultados de actividades'),
            const SizedBox(height: 16),
            const Text('Introduce tu contraseña para confirmar:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (passwordController.text.isEmpty) {
                AppSnackbar.error(context, 'Introduce tu contraseña');
                return;
              }

              final user = _auth.currentUser;
              if (user == null || user.email == null) {
                if (context.mounted) {
                  AppSnackbar.error(
                    context,
                    'Sesión expirada. Inicia sesión de nuevo.',
                  );
                }
                return;
              }
              try {
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: passwordController.text,
                );
                await user.reauthenticateWithCredential(credential);

                // Punto 15: Log antes de borrar
                await AuditService.log(
                  action: 'delete_account',
                  targetId: user.uid,
                  details: {'email': user.email, 'schoolId': _schoolId},
                );

                if (_schoolId.isNotEmpty) {
                  final studentsSnap = await FirebaseFirestore.instance
                      .collection('students')
                      .where('schoolId', isEqualTo: _schoolId)
                      .get();

                  // Firestore batch limit: 500 operaciones
                  const maxBatch = 499;
                  var batch = FirebaseFirestore.instance.batch();
                  var count = 0;

                  for (final student in studentsSnap.docs) {
                    final resultsSnap = await FirebaseFirestore.instance
                        .collection('results')
                        .where('schoolId', isEqualTo: _schoolId)
                        .where('studentId', isEqualTo: student.id)
                        .get();
                    for (final result in resultsSnap.docs) {
                      if (count >= maxBatch) {
                        await batch.commit();
                        batch = FirebaseFirestore.instance.batch();
                        count = 0;
                      }
                      batch.delete(result.reference);
                      count++;
                    }
                    if (count >= maxBatch) {
                      await batch.commit();
                      batch = FirebaseFirestore.instance.batch();
                      count = 0;
                    }
                    batch.delete(student.reference);
                    count++;
                  }

                  if (count >= maxBatch) {
                    await batch.commit();
                    batch = FirebaseFirestore.instance.batch();
                    count = 0;
                  }
                  batch.delete(FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid));
                  count++;

                  if (count > 0) await batch.commit();
                }

                await user.delete();

                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                  AppSnackbar.success(
                    context,
                    'Cuenta y datos eliminados correctamente',
                  );
                }
              } on FirebaseAuthException catch (e) {
                String msg = 'Error al eliminar la cuenta';
                if (e.code == 'wrong-password') msg = 'Contraseña incorrecta';
                if (context.mounted) {
                  AppSnackbar.error(context, msg);
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.error(
                    context,
                    'Error al eliminar la cuenta. Inténtalo de nuevo.',
                  );
                }
              }
            },
            child: const Text('Eliminar permanentemente'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content:
        const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.grey[600]),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}

class _DataItem extends StatelessWidget {
  final String label;
  final String value;
  const _DataItem(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 160, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(child: Text(value)),
      ]),
    );
  }
}