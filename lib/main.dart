import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/user_manager.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/scan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await ApiService.init();
  await UserManager.init();

  // Debug token status at startup
  print('Main: Checking token status at startup...');
  await ApiService.refreshTokenFromStorage();
  print(
    'Main: Token at startup: ${ApiService.getCurrentToken()?.substring(0, 10) ?? "null"}...',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warehouse Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main-menu': (context) => const MainMenuScreen(),
        '/scan': (context) => const ScanScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add a small delay for splash screen effect
    await Future.delayed(const Duration(seconds: 1));

    if (UserManager.isLoggedIn) {
      // Try to refresh user data to verify token is still valid
      final user = await UserManager.refreshUser();

      if (user != null && mounted) {
        // Token is valid, go to main menu
        Navigator.of(context).pushReplacementNamed('/main-menu');
      } else if (mounted) {
        // Token is invalid, go to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else if (mounted) {
      // Not logged in, go to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/sanoh-logo.png',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
