/// Main entry point for the Saath app
///
/// This file initializes the app, sets up providers, and contains the HomePage and app state logic.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'package:intl/intl.dart';
import 'login_signup_page.dart';
import 'app_footer.dart';
import 'welcome_pages.dart';
import 'forum_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
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
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginSignupPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Time display (top center)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Text(
              '9:41 AM',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with two overlapping circles
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pink circle (top left)
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF6B8B), Color(0xFFFF8E53)],
                            ),
                          ),
                        ),
                      ),
                      // Blue circle (bottom right)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                            ),
                          ),
                        ),
                      ),
                      // White highlight on pink circle
                      Positioned(
                        top: 50,
                        left: 50,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 18),
                
                // App name in cursive font
                Text(
                  'Saaath...',
                  style: TextStyle(
                    fontFamily: 'DancingScript',
                    fontSize: 38,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                
                const SizedBox(height: 18),
                
                // Main text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Connect with people who matter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppState with ChangeNotifier {
  String _message = 'Loading...';
  bool _isLoading = true;
  String _error = '';

  String get message => _message;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchMessage() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Add a timeout to the request
      final response = await http.get(
        Uri.parse(ApiConfig.homeEndpoint),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _message = data['message'] ?? 'No message received';
      } else {
        _error = 'Server error: ${response.statusCode}\n${response.body}';
      }
    } on http.ClientException catch (e) {
      _error = 'Network error: ${e.message}';
    } on FormatException catch (e) {
      _error = 'Data format error: $e';
    } on TimeoutException {
      _error = 'Connection timeout. Please check if the server is running and accessible.';
    } catch (e) {
      _error = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saath App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginSignupPage(),
        '/welcome': (context) => const WelcomePage(),
        '/forum': (context) => const ForumPage(),
        // Add other routes here as needed
      },
      onGenerateRoute: (settings) {
        // Handle any undefined routes
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
// Welcome page is now the main landing page after login
// See welcome_pages.dart for the implementation
