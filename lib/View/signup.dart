import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../routes.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.code,
  });

  final String name;
  final String code;
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;

  final List<CountryDialCode> _countryCodes = const [
    CountryDialCode(name: 'Nepal', code: '+977'),
    CountryDialCode(name: 'India', code: '+91'),
    CountryDialCode(name: 'United States', code: '+1'),
    CountryDialCode(name: 'United Kingdom', code: '+44'),
    CountryDialCode(name: 'Australia', code: '+61'),
    CountryDialCode(name: 'Canada', code: '+1'),
  ];

  late CountryDialCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countryCodes.first;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateNepalNumber(String number) {
    // Accept only 10-digit numbers starting with 97, 98, or 96
    final regEx = RegExp(r'^(98|97|96)\d{8}$');
    return regEx.hasMatch(number);
  }

  Future<void> _sendOtp() async {
    final phone = phoneController.text.trim();

    if (_selectedCountry.code == '+977') {
      // Nepal number validation
      if (!_validateNepalNumber(phone)) {
        _showSnack(
            "Enter a valid 10-digit Nepali number (starts with 97, 98, or 96)");
        return;
      }
    } else {
      // Other countries basic validation
      if (phone.length < 6) {
        _showSnack("Enter a valid phone number");
        return;
      }
    }

    final phoneNumber = _selectedCountry.code + phone;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phoneNumber}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final otp = data['otp'];
        final expiresAt = DateTime.now().add(const Duration(minutes: 2));

        Navigator.of(context).pushReplacementNamed(
          AppRoutes.verify,
          arguments: {
            'phoneNumber': phoneNumber,
            'otp': otp,
            'expiresAt': expiresAt.millisecondsSinceEpoch,
          },
        );
      } else {
        _showSnack(data['message'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showSnack("Error sending OTP: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffd0e8ff), // soft light blue
                Color(0xffe8f3ff),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ------- LOGO CARD -------
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/1.png",
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // -------- TITLE --------
                  const Text(
                    "Verify your number",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),

                  const SizedBox(
                    width: 280,
                    child: Text(
                      "We'll send an OTP to confirm your phone number.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // -------- INPUT CARD --------
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Country / Region",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // COUNTRY DROPDOWN
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xfff7f8ff),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<CountryDialCode>(
                                value: _selectedCountry,
                                isExpanded: true,
                                items: _countryCodes
                                    .map(
                                      (country) => DropdownMenuItem(
                                        value: country,
                                        child: Text(
                                          '${country.name} (${country.code})',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedCountry = value);
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // PHONE INPUT
                        const Text(
                          "Phone Number",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixText: _selectedCountry.code + " ",
                            filled: true,
                            fillColor: const Color(0xfff7f8ff),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            hintText: "98XXXXXXXX",
                          ),
                        ),

                        const SizedBox(height: 26),

                        // SEND BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xffffc9d8), // light pink
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: _isLoading ? null : _sendOtp,
                            child: Text(
                              _isLoading ? "Sending..." : "Send code",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Need help?",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.pink,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
