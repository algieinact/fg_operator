import 'dart:io';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/user_manager.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/NetworkDebugScreen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize services with error handling
    try {
      await ApiService.init();
      await UserManager.init();

      // Debug token status at startup
      print('Main: Checking token status at startup...');
      await ApiService.refreshTokenFromStorage();
      print(
        'Main: Token at startup: ${ApiService.getCurrentToken()?.substring(0, 10) ?? "null"}...',
      );
    } catch (e) {
      print('Main: Error initializing services: $e');
      // Continue anyway, services will be initialized when needed
    }

    runApp(const MyApp());
  } catch (e) {
    print('Main: Critical error during app initialization: $e');
    // Show error screen or fallback
    runApp(const ErrorApp());
  }
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
        '/network-debug': (context) => const NetworkDebugScreen(),
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

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error - Warehouse Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const ErrorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Aplikasi Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Terjadi kesalahan saat memulai aplikasi. Silakan restart aplikasi atau hubungi administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  exit(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Restart Aplikasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
