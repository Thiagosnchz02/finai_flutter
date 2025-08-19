import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importa todas las pantallas que vamos a usar como rutas
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/update_password_screen.dart'; // <-- Nueva pantalla
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'features/profile/screens/generative_ai_screen.dart';
import 'features/profile/screens/meta_import_screen.dart';
import 'features/profile/screens/ai_avatar_options_screen.dart';
import 'features/profile/screens/image_to_image_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/accounts/screens/accounts_screen.dart';
import 'features/fixed_expenses/screens/fixed_expenses_screen.dart';
import 'features/goals/screens/goals_screen.dart';
import 'features/budgets/screens/budget_screen.dart';
import 'features/reports/screens/reports_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ***** LÓGICA DE CARGA SIMPLIFICADA *****
  // Simplemente llama a load. El paquete maneja los errores si no encuentra el archivo.
  await dotenv.load(fileName: ".env");

  // Ahora, inicializamos Supabase usando las variables cargadas.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // Usamos '!' para asegurar que no son nulas. La app debe fallar si no están.
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await initializeDateFormatting('es_ES', null);
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
        // lo llevamos al dashboard (o perfil para probar), limpiando cualquier pantalla anterior.
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/dashboard', (route) => false); // Redirige a Perfil para probar
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
      
      // --- APLICACIÓN DE TEMAS ---
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // La app cambiará de tema con el sistema operativo

      // Usamos un StreamBuilder para decidir la pantalla inicial de forma reactiva
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          if (snapshot.hasData && snapshot.data?.session != null) {
            // AHORA REDIRIGE AL PERFIL PARA PROBARLO
            return const DashboardScreen(); 
          }

          return const LoginScreen();
        },
      ),

      // Definimos todas las rutas con nombre de la aplicación.
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/update-password': (context) => const UpdatePasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/accounts': (context) => const AccountsScreen(),
        '/avatar/generative': (context) => const GenerativeAiScreen(),
        '/avatar/meta-import': (context) => const MetaImportScreen(),
        '/avatar/ai-options': (context) => const AiAvatarOptionsScreen(),
        '/avatar/image-to-image': (context) => const ImageToImageScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/fixed-expenses': (context) => const FixedExpensesScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/budgets': (context) => const BudgetScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}