import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Para el Timer

import '../../../presentation/widgets/finai_aurora_background.dart';

const double _horizontalPadding = 24.0;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
        },
        emailRedirectTo: 'io.supabase.finai://login-callback', // para Deep Linking
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '¡Registro exitoso! Revisa tu correo para confirmar la cuenta.'),
            backgroundColor: Colors.green,
          ),
        );
        // Espera un poco antes de volver al login para que el usuario lea el mensaje.
        Timer(const Duration(seconds: 4), () {
          if (mounted) {
            Navigator.of(context).pop(); // Vuelve a la pantalla anterior (Login)
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ocurrió un error inesperado.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error con Google: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error inesperado con Google.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: FinAiAuroraBackground()),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: _horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildUsernameField(),
                        const SizedBox(height: 16),
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 16),
                        _buildConfirmPasswordField(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSocialButtons(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F51B5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sing Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLoginLink(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            text: 'Sing up to Fin',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              fontFamily: 'inter',
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'Ai',
                style: TextStyle(
                  fontFamily: 'inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 255, 38, 172),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Nombre completo',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Tu nombre'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, introduce tu nombre.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Apodo / Username',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextFormField(
          controller: _usernameController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Tu apodo'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, introduce tu apodo o username.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Email',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('example@gmail.com'),
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Por favor, introduce un email válido.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Contraseña',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('********'),
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Repetir contraseña',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('********'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, repite la contraseña.';
            }
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white30)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Otras opciones registro',
              style: TextStyle(color: Colors.white70)),
        ),
        Expanded(child: Divider(color: Colors.white30)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signUpWithGoogle,
        style: _buildOutlinedButtonStyle(),
        child: const Text('Google'),
      ),
    );
  }

  Widget _buildLoginLink() {
    return RichText(
      text: TextSpan(
        text: 'Ya tienes una cuenta? ',
        style: const TextStyle(color: Colors.white70),
        children: [
          TextSpan(
            text: 'Log In',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: false,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0),
      ),
    );
  }

  ButtonStyle _buildOutlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      side: BorderSide(color: Colors.white.withOpacity(0.4)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}