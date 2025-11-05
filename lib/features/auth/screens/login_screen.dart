import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/presentation/widgets/finai_aurora_background.dart';
import 'package:finai_flutter/core/services/biometric_auth_service.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';


// Importamos nuestro nuevo widget reutilizable desde la carpeta de widgets compartidos

// Es una buena práctica definir las constantes de la UI.
const double _horizontalPadding = 24.0;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _localAuth = LocalAuthentication();
  final _biometricService = BiometricAuthService();

  bool _isLoading = false;
  bool _isBiometricAvailable = false;


  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _checkExistingSession();
  }
  
  /// Verifica si ya existe una sesión activa y redirige al dashboard si es así.
  Future<void> _checkExistingSession() async {
    final currentSession = _supabase.auth.currentSession;
    final currentUser = _supabase.auth.currentUser;
    
    print('🔍 [LOGIN] Verificando sesión existente...');
    print('  - currentSession: ${currentSession != null ? "EXISTE" : "NULL"}');
    print('  - currentUser: ${currentUser != null ? currentUser.email : "NULL"}');
    
    if (currentSession != null && mounted) {
      // Si hay sesión activa, verificar si tiene biometría habilitada
      final isBiometricEnabled = await _biometricService.isBiometricEnabledInDB();
      
      print('  - Biometría habilitada en BD: $isBiometricEnabled');
      
      if (isBiometricEnabled) {
        // Si tiene biometría habilitada, requerir autenticación biométrica
        // El usuario verá la pantalla de login con el botón de huella
        print('  ✅ Usuario debe autenticarse con huella');
        return;
      } else {
        // Si no tiene biometría, ir directamente al dashboard
        print('  ➡️ Redirigiendo a dashboard (sin biometría)');
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      print('  ❌ No hay sesión activa');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Revisa si el dispositivo soporta autenticación biométrica.
  Future<void> _checkBiometricSupport() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = canCheckBiometrics && isDeviceSupported;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
    }
  }

  /// Intenta autenticar al usuario usando biometría.
  Future<void> _authenticateWithBiometrics() async {
    if (!_isBiometricAvailable) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 [BIOMETRIC] Iniciando autenticación biométrica...');
      
      // Verificar si tiene habilitada la biometría en la BD
      // Primero intentamos obtener el user actual (puede estar en sesión o recuperado)
      final currentUser = _supabase.auth.currentUser;
      final currentSession = _supabase.auth.currentSession;
      
      print('  - currentUser: ${currentUser != null ? currentUser.email : "NULL"}');
      print('  - currentSession: ${currentSession != null ? "EXISTE" : "NULL"}');
      
      if (currentUser == null) {
        // No hay usuario, necesita login con email/password
        print('  ❌ No hay usuario - requiere login con email/password');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Primero debes iniciar sesión con tu email y contraseña',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Verificar si tiene habilitada la biometría en la BD
      final isBiometricEnabled = await _biometricService.isBiometricEnabledInDB();
      
      print('  - Biometría habilitada en BD: $isBiometricEnabled');
      
      if (!isBiometricEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Para usar esta función, habilítala en Configuración → Seguridad',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Solicitar autenticación biométrica
      print('  🔓 Solicitando huella...');
      final authenticated = await _biometricService.authenticateWithBiometrics();
      
      print('  - Autenticado: $authenticated');
      
      if (authenticated && mounted) {
        print('  ✅ Autenticación exitosa - navegando a dashboard');
        // Navegar al dashboard - la sesión ya está activa
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Maneja el inicio de sesión con Email y Contraseña.
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Supabase persiste la sesión automáticamente
      // No necesitamos navegar aquí. El listener en main.dart lo hará.
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

  /// Inicia el flujo de autenticación con Google.
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // redirectTo: 'io.supabase.finai://login-callback/', // DEEP LINK - Ver explicación
      );
      // La navegación la gestionará el AuthState listener
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
    resizeToAvoidBottomInset: true,
    body: Stack(
      alignment: Alignment.center,
      children: [
        // 1) Fondo 100% código (nítido, sin banding)
        const Positioned.fill(child: FinAiAuroraBackground()),

        // 2) Contenido con scroll
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).padding.top - 
                             MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            _buildPasswordHeader(),
                            const SizedBox(height: 8),
                            _buildPasswordField(),
                            const SizedBox(height: 24),
                            _buildSignInButton(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isBiometricAvailable) ...[
                        _buildBiometricButton(),
                        const SizedBox(height: 24),
                      ],
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildSocialButtons(),
                      const SizedBox(height: 40),
                      _buildSignUpButton(),
                      const SizedBox(height: 40),
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
      Image.asset('assets/images/Isotipo.png', height: 130),
      const SizedBox(height: 24),
      RichText(
        textAlign: TextAlign.center, // Asegura que el texto esté centrado
        text: TextSpan(
          text: 'Log in to Fin',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300, // Hace la fuente más fina (Light/Thin)
            color: Colors.white,
            fontFamily: 'inter', // Puedes cambiar 'Roboto' por tu fuente elegante si la tienes
          ),
          children: <TextSpan>[
            TextSpan(
              text: 'Ai',
              style: TextStyle(
                fontFamily: 'inter',
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 255, 38, 172), // Un fucsia vibrante
                // Si tienes una fuente específica para el brillo, aplícala aquí también
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildPasswordHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Contraseña',
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/forgot-password');
          },
          child: const Text(
            'Olvidaste tu contraseña?',
            style: TextStyle(color: Colors.white70),
          ),
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
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: _buildInputDecoration('********'),
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres.';
        }
        return null;
      },
    );
  }

  Widget _buildSignInButton() {
  return SizedBox(
    width: double.infinity,
    // Usamos ClipRRect para que el efecto de desenfoque respete los bordes redondeados.
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        // Este es el filtro que crea el efecto "frosty" o de cristal esmerilado.
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: InkWell(
          // Usamos InkWell para la respuesta táctil (onTap) y el efecto ripple.
          onTap: _isLoading ? null : _signIn,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Un color de fondo muy sutil y un borde para definir la forma.
              color: const Color.fromARGB(255, 255, 0, 234).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Color.fromARGB(255, 255, 0, 234),
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
                    'Log In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBiometricButton() {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: InkWell(
            onTap: _isLoading ? null : _authenticateWithBiometrics,
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Iniciar sesión con huella',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white30)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Otras opciones de log in',
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
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: _buildOutlinedButtonStyle(),
        child: const Text('Google'),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return RichText(
      text: TextSpan(
        text: 'No tienes una cuenta? ',
        style: const TextStyle(color: Colors.white70),
        children: [
          TextSpan(
            text: 'Registrate',
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.of(context).pushNamed('/register');
              },
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
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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