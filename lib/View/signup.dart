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

  Future<void> _sendOtp() async {
    final phoneNumber = _selectedCountry.code + phoneController.text.trim();

    if (phoneController.text.trim().isEmpty || phoneController.text.trim().length < 6) {
      _showSnack("Enter a valid phone number");
      return;
    }

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
        print("Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth > 650;
            final double horizontalPadding = isTablet ? 64 : 20;
            final BoxDecoration background = const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xfffdf2f4), Color(0xfff0f4ff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            );

            return Container(
              decoration: background,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Image.asset(
                            "assets/1.png",
                            height: isTablet ? 200 : 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Verify your number",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "We'll send an OTP to confirm your phone number.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(isTablet ? 32 : 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 30,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Country / Region",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xfff7f8ff),
                                ),
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
                                          style:
                                          const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedCountry = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: "Phone Number",
                                  prefixText: _selectedCountry.code,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xfff7f8ff),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff111827),
                                    foregroundColor: Colors.white,
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
                        const SizedBox(height: 26),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Need help?",
                            style: TextStyle(
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
