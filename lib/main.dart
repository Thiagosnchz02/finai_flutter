import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa todas las pantallas que vamos a usar como rutas
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/update_password_screen.dart'; // <-- Nueva pantalla
import 'features/dashboard/screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://exwdzrnguktrpmwgvioo.supabase.co', // REEMPLAZA CON TU URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4d2R6cm5ndWt0cnBtd2d2aW9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwMDgzNzcsImV4cCI6MjA1ODU4NDM3N30.y0spDaSiheZYsnwLxTnE5V_m4jxnC3h8KNW-U4vgR2M', // REEMPLAZA CON TU ANON KEY
  );

  runApp(const MyApp());
}

// Widget de "Splash Screen" para mostrar mientras se verifica el estado de sesión
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0d1137),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

// GlobalKey para poder navegar desde fuera del árbol de widgets (desde el listener)
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      // Lógica de navegación basada en el evento de autenticación
      if (event == AuthChangeEvent.passwordRecovery) {
        // El usuario ha hecho clic en el enlace de recuperación de contraseña.
        // Lo llevamos a la pantalla para que cree una nueva contraseña.
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/update-password', (route) => false);
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        // Si el usuario inicia sesión (ya sea por confirmación de email, Google, etc.)
        // lo llevamos al dashboard, limpiando cualquier pantalla anterior.
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/dashboard', (route) => false);
      } else if (event == AuthChangeEvent.signedOut) {
        // Si el usuario cierra sesión, lo llevamos al login.
         _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // Asignamos la GlobalKey al Navigator
      title: 'FinAi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0d1137),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3F51B5),
          secondary: Color(0xFF6A1B9A),
          error: Colors.redAccent,
        ),
      ),
      // La ruta inicial se decide en base a si hay una sesión guardada al arrancar.
      initialRoute: Supabase.instance.client.auth.currentSession == null
          ? '/login'
          : '/dashboard',
      
      // Definimos todas las rutas con nombre de la aplicación.
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/update-password': (context) => const UpdatePasswordScreen(), // <-- Nueva ruta
        '/dashboard': (context) => const DashboardScreen(),
      },
      // Usamos un builder para mostrar la Splash Screen al principio
      builder: (context, child) {
        return FutureBuilder(
          // Esperamos a que Supabase recupere la sesión inicial
          future: Supabase.instance.client.auth.onAuthStateChange.first,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            // Una vez que el estado inicial se ha resuelto, mostramos la app.
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}