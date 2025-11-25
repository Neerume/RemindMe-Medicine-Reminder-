import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _isOtpExpired => DateTime.now().isAfter(_expiresAt);

  void _showOtpHint() {
    if (_hasShownOtp || !mounted) return;
    _hasShownOtp = true;
    _showSnack('Demo OTP for ${widget.phoneNumber}: $_currentOtp');
  }

  // -------------------- VERIFY OTP --------------------
  Future<void> _verifyOtp() async {
    final otpInput = _otpController.text.trim();
    if (otpInput.length != 6) {
      _showSnack("Enter 6-digit OTP");
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
      setState(() => _isLoading = false);
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
        _otpController.clear();
        _showOtpHint();
      } else {
        _showSnack(data['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      _showSnack("Error resending OTP: $e");
    } finally {
      setState(() => _isResending = false);
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
        await UserDataService.saveToken(data['token']);
        await UserDataService.saveUserData(
          phone: phoneNumber,
          username: data['username'] ?? '',
        );

        _showSnack("Login successful!");
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.name,
          arguments: phoneNumber,
        );
      } else {
        _showSnack(data['error'] ?? "Login failed");
      }
    } catch (e) {
      _showSnack("Login error: $e");
    }
  }


  void _navigateBackToSignup() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
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
            final double maxContentWidth = isTablet ? 520 : constraints.maxWidth;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
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
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => _otpFocusNode.requestFocus(),
                        child: Column(
                          children: [
                            _buildOtpRow(maxContentWidth),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to enter the 6-digit code',
                              style: TextStyle(fontSize: 13, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: Text(
                          _isResending ? "Resending..." : "Resend OTP",
                          style: const TextStyle(fontSize: 16, decoration: TextDecoration.underline),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: _isLoading ? null : _verifyOtp,
                          child: Text(_isLoading ? "Verifying..." : "Continue", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildOtpRow(double contentWidth) {
    final double spacing = 12;
    final double availableWidth = contentWidth - spacing * 5;
    final double fieldWidth = (availableWidth / 6).clamp(44, 64);
    final text = _otpController.text;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: 12,
      children: List.generate(6, (index) {
        final char = index < text.length ? text[index] : '';
        return SizedBox(
          width: fieldWidth,
          child: Container(
            height: fieldWidth + 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xffF5F5F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: index == text.length ? Colors.black87 : Colors.black26, width: index == text.length ? 1.5 : 1),
            ),
            child: Text(char, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        );
      }),
    );
  }
}
