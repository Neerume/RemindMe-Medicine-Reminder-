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
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());

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
    if (_isFirebaseMode) {
      _currentVerificationId = widget.verificationId;
      _currentResendToken = widget.resendToken;
    } else {
      _currentOtp = widget.otp ?? '';
      _expiresAt = widget.expiresAt ?? DateTime.now();
    }
    for (int i = 0; i < 6; i++) {
      otpControllers[i].addListener(() {
        if (otpControllers[i].text.length == 1 && i < 5) {
          FocusScope.of(context).nextFocus();
        } else if (otpControllers[i].text.isEmpty && i > 0) {
          FocusScope.of(context).previousFocus();
        }
      });
    }
    if (!_isFirebaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOtpHint());
    }
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
    final smsCode = otpControllers.map((c) => c.text).join();
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit code.")),
      );
      return;
    }

    if (_isFirebaseMode) {
      if (_currentVerificationId == null ||
          _currentVerificationId!.isEmpty) {
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
      for (final controller in otpControllers) {
        controller.clear();
      }
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
    for (var controller in otpControllers) {
      controller.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Image.asset(
                "assets/1.png",
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                _isFirebaseMode
                    ? "Check your SMS inbox"
                    : "Verifying your number",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      controller: otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black54)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              InkWell(
                onTap: _resendCode,
                child: Text(
                  _isFirebaseMode ? "Resend SMS" : "Resend demo code",
                  style: const TextStyle(
                      fontSize: 17,
                      color: Colors.blue,
                      decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 180,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF9FA0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _verifyOtp,
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
