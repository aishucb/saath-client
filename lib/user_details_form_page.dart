/// UserDetailsFormPage for the Saath app
///
/// This file contains the form for users to enter or update their personal details after registration.
import 'package:flutter/material.dart';
import 'welcome_pages.dart';
import 'app_footer.dart';

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Send data to backend or proceed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details submitted!')),
      );
      // Navigate to WelcomeBackPage after submission
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => WelcomeBackPage()),
        );
      });
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
                onPressed: _submit,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
