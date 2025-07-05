/// PhoneVerificationPage for the Saath app
///
/// This file handles phone number verification, OTP input, and related logic for user authentication.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For InternetAddress and SocketException
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:client/main.dart'; // Import HomePage
import 'config/api_config.dart'; // Import ApiConfig
import 'welcome_pages.dart'; // Import Welcome and WelcomeBack pages
import 'user_details_form_page.dart';
import 'app_footer.dart'; // For TextInputFormatter

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
  
  // Country code related state
  final _countryCodeController = TextEditingController(text: '+91');
  
  // Get the full phone number with country code
  String get _fullPhoneNumber => '${_countryCodeController.text.trim()}${_phoneController.text.trim()}';

  // Handle OTP input changes
  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    
    // Auto-submit when all digits are entered
    if (index == 5 && value.isNotEmpty) {
      _verifyOtp();
    }
  }

  // Verify OTP
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
        Uri.parse('${ApiConfig.baseUrl}/api/verify-otp'),
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
        final data = jsonDecode(response.body);
        final status = data['registrationStatus'];
        if (status == 'newly_registered') {
          // Pass phone number to UserDetailsFormPage for auto-population
          String? phone = _verificationPhoneNumber;
          if (phone != null && phone.startsWith('+91')) {
            phone = phone.substring(3); // Remove country code for display
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserDetailsFormPage(phone: phone)),
          );
        } else if (status == 'already_registered') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WelcomeBackPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unknown registration status')),
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
  
  // Build country code input field
  Widget _buildCountryCodeInput() {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: _countryCodeController,
        keyboardType: TextInputType.phone,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: '+91',
          hintStyle: TextStyle(color: Colors.grey[500]),
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
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          isDense: true,
        ),
        onChanged: (value) {
          final newValue = value.replaceAll(RegExp(r'[^0-9+]'), '');
          if (newValue != value) {
            _countryCodeController.value = TextEditingValue(
              text: newValue,
              selection: TextSelection.collapsed(offset: newValue.length),
            );
          }
          // Re-validate phone number when country code changes
          _validatePhone(_phoneController.text);
        },
      ),
    );
  }

  // Build phone input field with country code
  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your phone number',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Country code input
            _buildCountryCodeInput(),
            const SizedBox(width: 10),
            // Phone number input
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone number',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
                onChanged: _validatePhone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15), // Reasonable max length for phone numbers
                ],
              ),
            ),
          ],
        ),
      ],
    );
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
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 1,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
    _countryCodeController.dispose();
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
      _verificationPhoneNumber = '${_countryCodeController.text}$digits';
      // More flexible validation - at least 7 digits, max 15
      _isPhoneValid = digits.length >= 7 && digits.length <= 15;
      print('Phone validation: ${_countryCodeController.text}$digits (${digits.length} digits) - Valid: $_isPhoneValid');
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
      _verificationPhoneNumber = _fullPhoneNumber;
      // Clear previous OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
    });

    try {
      // 1. Test network connectivity
      debugPrint('\n[1/4] Testing network connectivity...');
      final result = await InternetAddress.lookup(ApiConfig.networkCheckIp);
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'No internet connection';
      }
      debugPrint('✓ Network connectivity OK');

      // 2. Prepare request
      final url = Uri.parse('${ApiConfig.baseUrl}/api/otp');
      final requestBody = {'phone': _verificationPhoneNumber};
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
        // Show OTP in alert if present
        if (responseData['otp'] != null && mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Your OTP'),
              content: Text('OTP: \\${responseData['otp']}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
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
    // Main page structure for phone verification
    // Main page structure for phone verification
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      // The main body of the page
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
                // Phone input with country code selector
                _buildPhoneInput(),
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
