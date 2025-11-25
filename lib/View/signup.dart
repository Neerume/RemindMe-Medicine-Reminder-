import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:otp/otp.dart';
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
    this.requiresBillingPlan = false,
  });

  final String name;
  final String code;
  final bool requiresBillingPlan;
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Duration _otpValidity = Duration(minutes: 2);

  final List<CountryDialCode> _countryCodes = const [
    CountryDialCode(name: 'Nepal', code: '+977'),
    CountryDialCode(name: 'India', code: '+91'),
    CountryDialCode(name: 'United States', code: '+1'),
    CountryDialCode(name: 'United Kingdom', code: '+44'),
    CountryDialCode(name: 'Australia', code: '+61'),
    CountryDialCode(name: 'Canada', code: '+1'),
  ];

  late CountryDialCode _selectedCountry;
  bool _isDialogVisible = false;
  @override
  void initState() {
    super.initState();
    _selectedCountry = _countryCodes.first;
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void showLoadingDialog(BuildContext context,
      {String message = "Sending code..."}) {
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

  void _navigateToVerificationFirebase({
    required String phoneNumber,
    required String verificationId,
    int? resendToken,
  }) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.verify,
      arguments: {
        'mode': 'firebase',
        'phoneNumber': phoneNumber,
        'verificationId': verificationId,
        'resendToken': resendToken,
      },
    );
  }

  void _navigateToVerificationDemo({
    required String phoneNumber,
    required String otp,
    required DateTime expiresAt,
  }) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.verify,
      arguments: {
        'mode': 'demo',
        'phoneNumber': phoneNumber,
        'otp': otp,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'validity': _otpValidity.inSeconds,
      },
    );
  }

  String _generateOtp(String phoneNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return OTP.generateTOTPCodeString(
      phoneNumber,
      timestamp,
      length: 6,
      interval: _otpValidity.inSeconds,
      algorithm: Algorithm.SHA1,
    );
  }

  Future<void> _verifyPhoneNumber() async {
    // Ensure phone number starts with country code, e.g., +97798XXXXXXXX
    final String phoneNumber =
        _selectedCountry.code + phoneController.text.trim();

    if (phoneNumber.length < 10 ||
        !RegExp(r'^\+\d{10,15}$').hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Please enter a valid phone number including country code (e.g., +97798XXXXXXXX).")),
      );
      return;
    }

    showLoadingDialog(context);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (!mounted) return;
        hideLoadingDialog(context);
        await _auth.signInWithCredential(credential);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number automatically verified!'),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.name);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        hideLoadingDialog(context);
        _handleVerificationFailure(e, phoneNumber);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        hideLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification code sent!")),
        );
        _navigateToVerificationFirebase(
          phoneNumber: phoneNumber,
          verificationId: verificationId,
          resendToken: resendToken,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!mounted) return;
        hideLoadingDialog(context);
        _navigateToVerificationFirebase(
          phoneNumber: phoneNumber,
          verificationId: verificationId,
        );
      },
      timeout: const Duration(seconds: 60),
    );
  }

  void _handleVerificationFailure(FirebaseAuthException e, String phoneNumber) {
    String message = "Verification failed: ${e.message}";
    if (e.code == 'invalid-phone-number') {
      message = "The provided phone number is not valid.";
    } else if (e.code == 'too-many-requests') {
      message = "Too many requests. Please try again later.";
    } else if (e.code == 'billing-not-enabled') {
      message =
          "SMS sending is disabled (billing not enabled). Using demo OTP locally.";
      _sendDemoOtp(phoneNumber);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _sendDemoOtp(String phoneNumber) {
    final otp = _generateOtp(phoneNumber);
    final expiresAt = DateTime.now().add(_otpValidity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo OTP for $phoneNumber: $otp'),
        duration: const Duration(seconds: 6),
      ),
    );
    _navigateToVerificationDemo(
      phoneNumber: phoneNumber,
      otp: otp,
      expiresAt: expiresAt,
    );
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
                                color: Colors.black.withValues(alpha: 0.06),
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
                              if (_selectedCountry.requiresBillingPlan)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Icon(Icons.info_outline,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "SMS delivery in this region may require Firebase Blaze billing due to carrier filtering.",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                  onPressed: _verifyPhoneNumber,
                                  child: const Text(
                                    "Send code",
                                    style: TextStyle(
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
