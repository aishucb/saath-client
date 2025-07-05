/// LoginSignupPage for the Saath app
///
/// This file handles user login and signup screens, including UI and logic for authentication.
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'phone_verification_page.dart';
import 'config/api_config.dart';
import 'welcome_pages.dart';
import 'user_details_form_page.dart';
import 'main.dart';

// Replace with your actual client_id for web or custom flows if needed
// const String googleClientId = '390094822294-dgoanud3udf4iasgm81g38qjho8n82eg.apps.googleusercontent.com';

const String googleWebClientId = '390094822294-ttrgva5frj01e9c6i79f37lnleo188fl.apps.googleusercontent.com';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
    'openid', // Request idToken
  ],
  clientId: googleWebClientId, // Use web client ID for idToken
);


// This page handles user login and signup
class LoginSignupPage extends StatelessWidget {
  const LoginSignupPage({super.key});

  @override
  // Builds the login/signup UI
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 32),
                  // Logo (reuse the circles from splash)
                  SizedBox(
                    width: 60,
                    height: 40,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD16C7A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          top: 4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5B6DC1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 26,
                          top: 10,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 18),
                  const Text(
                    'Sign up or log in to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF888888),
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PhoneVerificationPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C7CFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue with Phone',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or continue with',
                          style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                        ),
                      ),
                      const Expanded(
                        child: Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Google button
                  InkWell(
                    onTap: () async {
                      debugPrint('Google sign-in button tapped');
                      try {
                        // Always sign out before a new sign in to get a fresh idToken
                        await _googleSignIn.signOut();
                        debugPrint('Calling _googleSignIn.signIn()...');
                        final account = await _googleSignIn.signIn();
                        debugPrint('Account result: ' + (account?.toString() ?? 'null'));
                        if (account == null) {
                          debugPrint('Google sign-in cancelled by user');
                          return;
                        }
                        debugPrint('Getting authentication...');
                        final auth = await account.authentication;
                        debugPrint('Auth result: ' + auth.toString());
                        final idToken = auth.idToken;
                        debugPrint('idToken: ' + (idToken ?? 'null'));
                        if (idToken == null) throw Exception('No idToken received');
                        debugPrint('Google sign-in success with idToken!');
                        // Show loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signing in...'), duration: Duration(milliseconds: 800)),
                        );
                        debugPrint('Google sign-in success with idToken!');
                        debugPrint('idToken being sent to backend: $idToken');
                        // Send the idToken to backend for verification
                        final response = await http.post(
                          Uri.parse(ApiConfig.baseUrl + '/auth/google-signin'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'idToken': idToken}),
                        );
                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          debugPrint('Backend auth success: [1m${jsonEncode(data)}');
                          final status = data['registrationStatus'] ?? '';
                          final userName = data['user']['name'] ?? data['user']['email'] ?? 'user';
                          if (status == 'newly_registered') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Welcome, $userName! Registration successful.')),
                            );
                            Future.delayed(const Duration(milliseconds: 800), () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => UserDetailsFormPage(
                                    name: data['user']['name'],
                                    email: data['user']['email'],
                                  ),
                                ),
                              );
                            });
                          } else if (status == 'already_registered') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Welcome back, $userName!')),
                            );
                            Future.delayed(const Duration(milliseconds: 800), () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => WelcomeBackPage()),
                              );
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Welcome, $userName!')),
                            );
                          }
                          // TODO: Save user session or navigate as needed
                        } else {
                          final error = jsonDecode(response.body)['error'] ?? 'Sign-in failed';
                          debugPrint('Backend auth error: $error');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Auth failed: $error')),
                          );
                        }
                      } catch (error, stack) {
                        debugPrint('Google sign-in failed: $error\n$stack');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google sign-in failed: $error')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFFE0E0E0)),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
