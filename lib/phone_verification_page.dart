import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For InternetAddress and SocketException
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:client/main.dart'; // Import HomePage

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isPhoneValid = false;
  bool _isLoading = false;
  String? _verificationPhoneNumber;

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    
    // Auto-submit when all digits are entered
    if (index == 5 && value.isNotEmpty) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) return;
    
    if (_verificationPhoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please request an OTP first')),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('[DEBUG] Verifying OTP: $otp for phone: $_verificationPhoneNumber');
      
      final response = await http.post(
        Uri.parse('http://192.168.1.2:5000/api/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone': _verificationPhoneNumber,
          'otp': otp,
        }),
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        // OTP verified successfully
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Verification failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      print('[ERROR] OTP verification failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to verify OTP. Please try again.')),
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
  
  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.text,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 1,
            textInputAction: TextInputAction.next,
            onChanged: (value) => _onOtpChanged(value, index),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              isDense: true,
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _validatePhone(String value) {
    setState(() {
      // Remove all non-digit characters and check length
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      _isPhoneValid = digits.length == 10;
      print('Phone validation: $digits (${digits.length} digits) - Valid: $_isPhoneValid');
    });
  }

  Future<void> _sendOtp(String phoneNumber) async {
    // Close keyboard if open
    FocusScope.of(context).unfocus();
    
    debugPrint('_sendOtp method called with: $phoneNumber');
    // Clear previous logs
    debugPrint('\n' * 5);
    debugPrint('=== STARTING NEW OTP REQUEST ===');
    debugPrint('Phone: $phoneNumber');
    
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _verificationPhoneNumber = '+91$phoneNumber';
      // Clear previous OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
    });

    try {
      // 1. Test network connectivity
      debugPrint('\n[1/4] Testing network connectivity...');
      final result = await InternetAddress.lookup('192.168.1.2');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'No internet connection';
      }
      debugPrint('✓ Network connectivity OK');

      // 2. Prepare request
      final url = Uri.parse('http://192.168.1.2:5000/api/otp');
      final requestBody = {'phone': '+91$phoneNumber'};
      final requestBodyJson = jsonEncode(requestBody);
      
      debugPrint('\n[2/4] Request details:');
      debugPrint('URL: ${url.toString()}');
      debugPrint('Method: POST');
      debugPrint('Headers: {Content-Type: application/json, Accept: application/json}');
      debugPrint('Body: $requestBodyJson');

      // 3. Send request
      debugPrint('\n[3/4] Sending request...');
      final stopwatch = Stopwatch()..start();
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBodyJson,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('✗ Request timed out after 10 seconds');
          return http.Response(
            jsonEncode({'error': 'Connection timeout'}),
            408,
            headers: {'Content-Type': 'application/json'},
          );
        },
      ).catchError((error) {
        debugPrint('✗ Request failed: ${error.toString()}');
        if (error is SocketException) {
          debugPrint('SocketException details:');
          debugPrint('- Message: ${error.message}');
          debugPrint('- Address: ${error.address}');
          debugPrint('- Port: ${error.port}');
          debugPrint('- OS Error: ${error.osError}');
        }
        throw error;
      });
      
      stopwatch.stop();
      
      // 4. Log response
      debugPrint('\n[4/4] Response received in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Headers:');
      response.headers.forEach((key, value) => debugPrint('  $key: $value'));
      debugPrint('Body:');
      debugPrint(response.body);
      
      try {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Parsed JSON:');
        jsonResponse.forEach((key, value) => debugPrint('  $key: $value'));
      } catch (e) {
        debugPrint('Failed to parse JSON: $e');
      }

      if (response.statusCode == 200) {
        // Success - OTP sent
        final responseData = jsonDecode(response.body);
        print('OTP sent successfully');
        // Focus on first OTP field after sending OTP
        if (_focusNodes.isNotEmpty) {
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        }
      } else {
        // Error handling
        print('Failed to send OTP: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } catch (e) {
      print('[ERROR] Exception in _sendOtp: $e');
      print('[ERROR] Stack trace: ${e is Error ? e.stackTrace : ''}');
      
      if (e is SocketException) {
        print('[ERROR] SocketException details:');
        print('- Message: ${e.message}');
        print('- Address: ${e.address}');
        print('- Port: ${e.port}');
        print('- OS Error: ${e.osError}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      print('[DEBUG] Cleaning up...');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(0),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 16),
                // Title
                const Center(
                  child: Text(
                    'Phone Verification',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Enter phone label
                const Text(
                  'Enter your phone number',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                // Phone input
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: const Text(
                        '+91',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: _validatePhone,
                        maxLength: 15, // Allow for formatting
                        decoration: InputDecoration(
                          hintText: '123-456-7890',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          counterText: '', // Hide character counter
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Send code button (disabled style)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPhoneValid ? () {
                      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      print('Sending code to: +91$phoneNumber');
                      _sendOtp(phoneNumber);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPhoneValid ? const Color(0xFF4169E1) : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Send Code',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                // Enter code label
                const Text(
                  'Enter the code sent to your phone',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                // OTP boxes
                _buildOtpInput(),
                const SizedBox(height: 24),
                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                // Resend code
                const Center(
                  child: Text(
                    'Resend code in --:--',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                // Auto detect info
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'We\'ll automatically detect your verification code',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
