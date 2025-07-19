/// UserDetailsFormPage for the Saath app
///
/// This file contains the form for users to enter or update their personal details after registration.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'welcome_pages.dart';
import 'app_footer.dart';
import 'config/api_config.dart';

class UserDetailsFormPage extends StatefulWidget {
  final String? email;
  final String? name;
  final String? phone;
  const UserDetailsFormPage({Key? key, this.email, this.name, this.phone}) : super(key: key);

  @override
  State<UserDetailsFormPage> createState() => _UserDetailsFormPageState();
}

class _UserDetailsFormPageState extends State<UserDetailsFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _phoneController = TextEditingController(text: widget.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String normalizePhone(String phone) {
        final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length == 10) {
          return '91$digits';
        }
        return digits;
      }

      try {
        // Send data to backend
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/customer'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _nameController.text,
            'phone': normalizePhone(_phoneController.text),
            'email': _emailController.text,
          }),
        ).timeout(Duration(seconds: 10));

        print('Customer API response status: ${response.statusCode}');
        print('Customer API response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userId = data['id']; // This is the MongoDB _id
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );

          // Navigate to WelcomeBackPage with the user ID
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => WelcomeBackPage(
                userName: _nameController.text,
                userAge: 25, // Default age
                profilePicture: null, // Will be set when user uploads photo
                matchesCount: 0, // New user starts with 0 matches
                sparksLeft: 5, // Default sparks for new user
                isBoosted: false, // New user is not boosted
                currentUserId: userId, // Pass the MongoDB _id
              ),
            ),
          );
        } else {
          final error = jsonDecode(response.body)['error'] ?? 'Failed to update profile';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main page structure for user details form
    return Scaffold(
      // The bottom navigation bar footer for main pages
      bottomNavigationBar: AppFooter(
        currentIndex: 0, // Set the correct index for this page if needed
        onTap: (index) {
          if (index == 0) {
Navigator.pushReplacementNamed(context, '/welcome');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/events');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/forum');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/wellness');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/chat');
          }
        },
      ),
      // The top bar of the page
      appBar: AppBar(title: Text('Complete Your Profile')),
      // The main body of the page
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.length < 8 ? 'Enter a valid phone number' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Saving...'),
                      ],
                    )
                  : Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
