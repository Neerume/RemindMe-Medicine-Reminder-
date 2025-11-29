import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for input formatters
import 'package:http/http.dart' as http;
import '../Controller/auth_Controller.dart';
import '../config/api.dart';
import '../routes.dart';

import '../services/user_data_service.dart';

class VerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String otp; // initial OTP from server
  final int expiresAt;

  const VerificationPage({
    super.key,
    required this.phoneNumber,
    required this.otp,
    required this.expiresAt,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  // We use a list of controllers and focus nodes for the 6 boxes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  late String _currentOtp;
  late DateTime _expiresAt;
  bool _hasShownOtp = false;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.otp;
    _expiresAt = DateTime.fromMillisecondsSinceEpoch(widget.expiresAt);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOtpHint());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _isOtpExpired => DateTime.now().isAfter(_expiresAt);

  void _showOtpHint() {
    if (_hasShownOtp || !mounted) return;
    _hasShownOtp = true;
    _showSnack('Demo OTP for ${widget.phoneNumber}: $_currentOtp');
  }

  // Helper to get the full OTP string from the 6 boxes
  String _getOtpFromBoxes() {
    return _controllers.map((e) => e.text).join();
  }

  // -------------------- VERIFY OTP --------------------
  Future<void> _verifyOtp() async {
    final otpInput = _getOtpFromBoxes();

    if (otpInput.length != 6) {
      _showSnack("Please enter the full 6-digit OTP");
      return;
    }

    if (_isOtpExpired) {
      _showSnack("OTP expired. Please request again.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": widget.phoneNumber,
          "otp": otpInput,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await _login(widget.phoneNumber, otpInput);
      } else {
        _showSnack(data['error'] ?? "Invalid OTP");
      }
    } catch (e) {
      _showSnack("Error verifying OTP: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------- RESEND OTP --------------------
  Future<void> _resendOtp() async {
    if (_isResending) return;
    setState(() => _isResending = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": widget.phoneNumber}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _currentOtp = data['otp'];
        _expiresAt = DateTime.now().add(const Duration(minutes: 2));

        // Clear all boxes
        for (var controller in _controllers) {
          controller.clear();
        }
        // Focus the first box
        _focusNodes[0].requestFocus();

        _showOtpHint();
      } else {
        _showSnack(data['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      _showSnack("Error resending OTP: $e");
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // -------------------- LOGIN AFTER OTP --------------------
  Future<void> _login(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phoneNumber,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        // REMOVED CAREGIVER SYNC / USERID LOGIC AS REQUESTED
        await UserDataService.saveToken(data['token']);

        // Only saving basic phone/username now
        await UserDataService.saveUserData(
          phone: phoneNumber,
          username: data['username'] ?? '',
        );

        if (!mounted) return;

        _showSnack("Login successful!");
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.name,
          arguments: phoneNumber,
        );
      } else {
        if (!mounted) return;
        _showSnack(data['error'] ?? "Login failed");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Login error: $e");
    }
  }

  void _navigateBackToSignup() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: _navigateBackToSignup,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth > 600;
            final double horizontalPadding = isTablet ? 56 : 24;
            final double maxContentWidth =
                isTablet ? 520 : constraints.maxWidth;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        "assets/1.png",
                        height: isTablet ? 200 : 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Verifying your number",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 21,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.phoneNumber,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),

                      // --- NEW REAL INPUT BOXES ---
                      _buildRealOtpRow(),

                      const SizedBox(height: 10),
                      const Text(
                        'Tap to enter the 6-digit code',
                        style: TextStyle(fontSize: 13, color: Colors.black45),
                      ),

                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: Text(
                          _isResending ? "Resending..." : "Resend OTP",
                          style: const TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF9FA0),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: _isLoading ? null : _verifyOtp,
                          child: Text(_isLoading ? "Verifying..." : "Continue",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET FOR 6 SEPARATE BOXES ---
  Widget _buildRealOtpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1, // Only 1 digit per box
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // Input Formatters to ensure only numbers
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: "", // Hide the "0/1" counter
              filled: true,
              fillColor: const Color(0xffF5F5F7),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black87, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                // If typed a digit, move to next box
                if (index < 5) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                } else {
                  // If last box, close keyboard
                  FocusScope.of(context).unfocus();
                  _verifyOtp(); // Auto-submit when last digit entered (Optional)
                }
              } else {
                // Logic for backspace (moves to previous box)
                // Note: Standard onChanged doesn't catch backspace on empty field easily,
                // but this works if they clear the digit.
                if (index > 0) {
                  FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                }
              }
            },
            // Handle deleting (backspace) when field is empty
            onEditingComplete: () {
              if (_controllers[index].text.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }
            },
          ),
        );
      }),
    );
  }
}
