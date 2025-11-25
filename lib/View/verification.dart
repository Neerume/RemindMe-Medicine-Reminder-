import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:otp/otp.dart';
import '../routes.dart';

enum VerificationMode { firebase, demo }

class VerificationPage extends StatefulWidget {
  final VerificationMode mode;
  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final String? otp;
  final DateTime? expiresAt;
  final Duration validity;

  const VerificationPage({
    super.key,
    required this.mode,
    required this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.otp,
    this.expiresAt,
    this.validity = const Duration(minutes: 2),
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _otpInputController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentVerificationId;
  int? _currentResendToken;
  bool _isDialogVisible = false;

  late String _currentOtp;
  late DateTime _expiresAt;
  bool _hasShownOtp = false;

  bool get _isFirebaseMode => widget.mode == VerificationMode.firebase;

  @override
  void initState() {
    super.initState();
    _otpInputController.addListener(_handleOtpInputChange);
    if (_isFirebaseMode) {
      _currentVerificationId = widget.verificationId;
      _currentResendToken = widget.resendToken;
    } else {
      _currentOtp = widget.otp ?? '';
      _expiresAt = widget.expiresAt ?? DateTime.now();
    }
    if (!_isFirebaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOtpHint());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _handleOtpInputChange() {
    if (!mounted) return;
    final digitsOnly = _otpInputController.text.replaceAll(RegExp(r'\D'), '');
    String sanitized = digitsOnly;
    if (digitsOnly.length > 6) {
      sanitized = digitsOnly.substring(0, 6);
    }
    if (sanitized != _otpInputController.text) {
      _otpInputController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
      return;
    }
    setState(() {});
  }

  void _navigateBackToSignup() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  void _showOtpHint() {
    if (_hasShownOtp || !mounted) return;
    _hasShownOtp = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo OTP for ${widget.phoneNumber}: $_currentOtp'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void showLoadingDialog(BuildContext context,
      {String message = "Verifying..."}) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _isDialogVisible = false;
    });
  }

  void hideLoadingDialog(BuildContext context) {
    if (_isDialogVisible) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogVisible = false;
    }
  }

  bool get _isOtpExpired =>
      !_isFirebaseMode && DateTime.now().isAfter(_expiresAt);

  Future<void> _verifyOtp() async {
    final smsCode = _otpInputController.text;
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit code.")),
      );
      return;
    }

    if (_isFirebaseMode) {
      if (_currentVerificationId == null || _currentVerificationId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "No verification ID available. Please resend the code.")),
        );
        return;
      }
      showLoadingDialog(context);
      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: _currentVerificationId!,
          smsCode: smsCode,
        );
        await _auth.signInWithCredential(credential);
        if (!mounted) return;
        hideLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully verified!")),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.name);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        hideLoadingDialog(context);
        String message = "Verification failed: ${e.message}";
        if (e.code == 'invalid-verification-code') {
          message = "The entered verification code is invalid.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }

    if (_isOtpExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP expired. Please resend.")),
      );
      return;
    }
    if (smsCode != _currentOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect OTP. Please try again.")),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.name);
  }

  Future<void> _resendCode() async {
    if (_isFirebaseMode) {
      showLoadingDialog(context, message: "Resending code...");
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: _currentResendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          hideLoadingDialog(context);
          await _auth.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.name);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          hideLoadingDialog(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Resend failed: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          hideLoadingDialog(context);
          setState(() {
            _currentVerificationId = verificationId;
            _currentResendToken = resendToken;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New code sent!")),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _currentVerificationId = verificationId;
          });
          hideLoadingDialog(context);
        },
        timeout: const Duration(seconds: 60),
      );
      return;
    }

    final now = DateTime.now();
    final newOtp = OTP.generateTOTPCodeString(
      widget.phoneNumber,
      now.millisecondsSinceEpoch,
      length: 6,
      interval: widget.validity.inSeconds,
      algorithm: Algorithm.SHA1,
    );
    setState(() {
      _currentOtp = newOtp;
      _expiresAt = now.add(widget.validity);
      _hasShownOtp = false;
      _otpInputController.clear();
      _otpFocusNode.requestFocus();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New demo OTP: $_currentOtp'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  void dispose() {
    _otpInputController.removeListener(_handleOtpInputChange);
    _otpInputController.dispose();
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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
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
                        _isFirebaseMode
                            ? "Check your SMS inbox"
                            : "Verifying your number",
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
                          fontSize: 16,
                          color: Colors.black54,
                        ),
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
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 0,
                        child: TextField(
                          controller: _otpInputController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _resendCode,
                        child: Text(
                          _isFirebaseMode ? "Resend SMS" : "Resend demo code",
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
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
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _verifyOtp,
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    final text = _otpInputController.text;

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
              border: Border.all(
                color: index == text.length
                    ? Colors.black87
                    : Colors.black26,
                width: index == text.length ? 1.5 : 1,
              ),
            ),
            child: Text(
              char,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
}
