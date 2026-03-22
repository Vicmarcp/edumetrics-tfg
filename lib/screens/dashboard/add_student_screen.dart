import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedClass;
  int? _selectedAvatarId;
  bool _isLoading = false;
  bool _consentChecked = false;

  final List<String> _classes = [
    '1ºA', '1ºB', '1ºC',
    '2ºA', '2ºB', '2ºC',
  ];

  /// Solo letras (incluye acentos/ñ), espacios y guiones
  static final _nameRegex = RegExp(r"^[a-zA-ZÀ-ÿñÑ\s\-']+$");

  /// Sanitiza el nombre: trim, colapsar espacios múltiples
  String _sanitizeName(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_consentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Debes confirmar que se dispone del consentimiento parental'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final name = _sanitizeName(_nameController.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor introduce el nombre del alumno')),
      );
      return;
    }

    if (name.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El nombre no puede superar los 50 caracteres')),
      );
      return;
    }

    if (!_nameRegex.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'El nombre solo puede contener letras, espacios y guiones'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una clase')),
      );
      return;
    }

    if (_selectedAvatarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un avatar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión no válida. Inicia sesión de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final schoolId = userDoc.data()?['schoolId'] as String?;

      if (schoolId == null || schoolId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Tu cuenta no tiene un centro asignado. Contacta con el administrador.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('students').add({
        'name': name,
        'className': _selectedClass,
        'schoolId': schoolId,
        'avatarId': _selectedAvatarId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alumno creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear alumno: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Alumno')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del alumno',
                  hintText: 'Ej: Carlos García',
                  prefixIcon: const Icon(Icons.person),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r"[a-zA-ZÀ-ÿñÑ\s\-']")),
                ],
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedClass,
                decoration: InputDecoration(
                  labelText: 'Clase',
                  prefixIcon: const Icon(Icons.class_),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _classes.map((className) {
                  return DropdownMenuItem(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedClass = value),
              ),
              const SizedBox(height: 32),

              Text('Selecciona un avatar',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  final avatarId = index + 1;
                  final isSelected = _selectedAvatarId == avatarId;
                  final avatarPath =
                      'assets/avatars/avatar_${avatarId.toString().padLeft(2, '0')}.png';

                  return GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => setState(() => _selectedAvatarId = avatarId),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            : Theme.of(context).colorScheme.surface,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                avatarPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person,
                                      size: 40, color: Colors.grey.shade400);
                                },
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                  Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              CheckboxListTile(
                value: _consentChecked,
                onChanged: _isLoading
                    ? null
                    : (value) =>
                    setState(() => _consentChecked = value ?? false),
                title: const Text(
                  'Confirmo que el centro dispone del consentimiento de los '
                      'padres/tutores legales para el tratamiento de datos de '
                      'este alumno (Art. 7 LOPDGDD).',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveStudent,
                  child: _isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar Alumno'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}