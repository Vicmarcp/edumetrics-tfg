import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  // Estos nos permiten leer lo que el usuario escribe
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Key para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Estados de la interfaz
  bool _isLoading = false;           // ¿Está procesando el login?
  bool _obscurePassword = true;       // ¿Ocultar contraseña?
  String _emailError = '';            // Mensaje de error del email
  String _passwordError = '';         // Mensaje de error de contraseña

  @override
  void dispose() {
    // Liberar recursos cuando se destruye el widget
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // VALIDACIÓN EN TIEMPO REAL DEL EMAIL (Pregunta 4)
  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'El email no puede estar vacío';
      } else if (!value.contains('@') || !value.contains('.')) {
        _emailError = 'Formato de email inválido';
      } else {
        _emailError = '';
      }
    });
  }

  // VALIDACIÓN EN TIEMPO REAL DE CONTRASEÑA (Pregunta 4)
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'La contraseña no puede estar vacía';
      } else if (value.length < 6) {
        _passwordError = 'La contraseña debe tener al menos 6 caracteres';
      } else {
        _passwordError = '';
      }
    });
  }

  // FUNCIÓN DE LOGIN PRINCIPAL
  Future<void> _handleLogin() async {
    // Validar antes de intentar login (Pregunta 4)
    if (_emailError.isNotEmpty || _passwordError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor corrige los errores')),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    // ESTADO DE CARGA (Pregunta 2)
    // Deshabilitamos el botón cambiando _isLoading a true
    setState(() {
      _isLoading = true;
    });

    try {
      // Intentar login con Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // LOGIN EXITOSO - Navegar a home (Pregunta 3)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      // LOGIN FALLIDO - Mostrar error específico
      String errorMessage = 'Error al iniciar sesión';

      if (e.code == 'user-not-found') {
        errorMessage = 'No existe una cuenta con este email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email inválido';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Credenciales inválidas. Verifica tu email y contraseña';
      }

      if (mounted) {
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '¿Olvidaste tu contraseña?',
              textColor: Colors.white,
              onPressed: _showPasswordRecovery,
            ),
          ),
        );
      }

    } finally {
      // Rehabilitar el botón
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // RECUPERACIÓN DE CONTRASEÑA
  void _showPasswordRecovery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: const Text(
          'Se enviará un email de recuperación a tu correo electrónico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_emailController.text.isEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Introduce tu email primero'),
                  ),
                );
                return;
              }

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: _emailController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email de recuperación enviado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo o título
                    Icon(
                      Icons.school,
                      size: 64,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'EduMetrics',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistema de Evaluación Interactiva',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CAMPO EMAIL CON VALIDACIÓN EN TIEMPO REAL
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'profesor@ejemplo.com',
                        prefixIcon: const Icon(Icons.email),
                        errorText: _emailError.isEmpty ? null : _emailError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: _validateEmail,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // CAMPO CONTRASEÑA CON TOGGLE DE VISIBILIDAD (Pregunta 1)
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        errorText: _passwordError.isEmpty ? null : _passwordError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // ICONO DEL OJO (Pregunta 1)
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      onChanged: _validatePassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),

                    // BOTÓN DE LOGIN CON ESTADO DE CARGA (Pregunta 2)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Iniciando sesión...'),
                          ],
                        )
                            : const Text(
                          'Iniciar sesión',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // LINK DE RECUPERACIÓN DE CONTRASEÑA
                    TextButton(
                      onPressed: _isLoading ? null : _showPasswordRecovery,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}