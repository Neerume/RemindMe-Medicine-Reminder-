// caregiver_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_data_service.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen>
    with TickerProviderStateMixin {
  String? caregiverLink;
  String? patientLink;
  String? userId;
  final TextEditingController _caregiverEmailController =
      TextEditingController();
  final TextEditingController _patientEmailController = TextEditingController();
  final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@[\w\.-]+\.\w+$');
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Official Logo URLs
  final String _whatsappUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/512px-WhatsApp.svg.png";
  final String _instagramUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Instagram_icon.png/600px-Instagram_icon.png";
  final String _facebookUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/600px-Facebook_Logo_%282019%29.png";
  final String _gmailUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Gmail_icon_%282020%29.svg/512px-Gmail_icon_%282020%29.svg.png";

  @override
  void initState() {
    super.initState();
    _loadLinks();

    // initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _caregiverEmailController.dispose();
    _patientEmailController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadLinks() async {
    final userData = await UserDataService.getUserData();
    userId = userData['userId'] ?? 'default_user';

    caregiverLink = 'https://connectcaregiver/1/$userId';
    patientLink = 'https://connectpatient/1/$userId';

    if (mounted) setState(() {});
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text(
                'Link copied to clipboard!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareViaWhatsApp(String link, String type) async {
    final text = type == 'caregiver'
        ? 'Join me as a caregiver on RemindMe! 🏥\n$link'
        : 'I need care on RemindMe! 💊\n$link';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await _launchUri(
        uri, 'Could not open WhatsApp. Please ensure it is installed.');
  }

  Future<void> _shareViaInstagram(String link, String type) async {
    final text = type == 'caregiver'
        ? 'Join me as a caregiver on RemindMe! 🏥\n$link'
        : 'I need care on RemindMe! 💊\n$link';
    final uri = Uri.parse(
      'https://www.instagram.com/direct/new/?text=${Uri.encodeComponent(text)}',
    );
    await _launchUri(uri, 'Unable to open Instagram.');
  }

  Future<void> _shareViaFacebook(String link, String type) async {
    final text = type == 'caregiver'
        ? 'Join me as a caregiver on RemindMe!'
        : 'I need care on RemindMe!';
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}&quote=${Uri.encodeComponent(text)}',
    );
    await _launchUri(uri, 'Unable to open Facebook.');
  }

  Future<void> _shareViaEmail(String link, String type, String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !_emailRegex.hasMatch(trimmed)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid email address first.')),
      );
      return;
    }

    final subject = type == 'caregiver'
        ? 'Join me as a caregiver on RemindMe'
        : 'Join my RemindMe care circle';
    final body = type == 'caregiver'
        ? 'Hi,\n\nPlease help me manage my medicines using RemindMe.\n$link'
        : 'Hi,\n\nI would love your support on RemindMe.\n$link';

    final uri = Uri(
      scheme: 'mailto',
      path: trimmed,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    await _launchUri(uri, 'Unable to open email app.');
  }

  Future<void> _launchUri(Uri uri, String fallbackMessage) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackMessage),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildPremiumQRCode(String data, double size) {
    if (data.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffFF9FA0)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffFF9FA0).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        padding: const EdgeInsets.all(12),
        embeddedImage: null,
        embeddedImageStyle: null,
      ),
    );
  }

  Widget _buildInviteSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String qrData,
    required String link,
    required String type,
    required int index,
    required TextEditingController emailController,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xffFF9FA0).withOpacity(0.12),
                    const Color(0xffE8E9FF).withOpacity(0.18),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffFF9FA0).withOpacity(0.15),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xffFF9FA0).withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffFF9FA0).withOpacity(0.2),
                              const Color(0xffFF9FA0).withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffFF9FA0).withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xffFF9FA0),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                letterSpacing: -0.8,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: _buildPremiumQRCode(
                      qrData,
                      220.0,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 800 + (index * 100)),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (value * 0.05),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  const Color(0xffFFF2F2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xffFF9FA0).withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xffFF9FA0).withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _copyLink(link);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFF9FA0)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.link_rounded,
                                          color: Color(0xffFF9FA0),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Invitation Link',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              link,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[900],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xffFF9FA0),
                                              const Color(0xffFF9FA0)
                                                  .withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xffFF9FA0)
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.copy_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Share via',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 18,
                    children: [
                      _buildModernShareButton(
                        imageUrl: _whatsappUrl,
                        label: 'WhatsApp',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _shareViaWhatsApp(link, type);
                        },
                        delay: index * 100,
                      ),
                      _buildModernShareButton(
                        imageUrl: _instagramUrl,
                        label: 'Instagram',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _shareViaInstagram(link, type);
                        },
                        delay: index * 100 + 100,
                      ),
                      _buildModernShareButton(
                        imageUrl: _facebookUrl,
                        label: 'Facebook',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _shareViaFacebook(link, type);
                        },
                        delay: index * 100 + 200,
                      ),
                      _buildModernShareButton(
                        imageUrl: _gmailUrl,
                        label: 'Gmail',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _shareViaEmail(link, type, emailController.text);
                        },
                        delay: index * 100 + 300,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Invite via email',
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: () =>
                            _shareViaEmail(link, type, emailController.text),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: const Color(0xffFF9FA0).withOpacity(0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: const Color(0xffFF9FA0).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated button to use Network Images for real logos
  Widget _buildModernShareButton({
    required String imageUrl,
    required String label,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  // Padded image to ensure it looks good inside the circle
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/1.png',
              width: 40,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red, size: 24);
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'RemindMe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View History')),
              );
            },
            color: Colors.grey[700],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTablet = constraints.maxWidth > 700;
              final double horizontalPadding = isTablet ? 48 : 20;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInviteSection(
                          title: 'Invite Caregiver',
                          subtitle:
                              'Share with someone who can help manage your care',
                          icon: Icons.people_rounded,
                          qrData: caregiverLink ?? '',
                          link: caregiverLink ?? 'Loading...',
                          type: 'caregiver',
                          index: 0,
                          emailController: _caregiverEmailController,
                        ),
                        _buildInviteSection(
                          title: 'Invite People to Care',
                          subtitle: 'Let loved ones join your care journey',
                          icon: Icons.favorite_rounded,
                          qrData: patientLink ?? '',
                          link: patientLink ?? 'Loading...',
                          type: 'patient',
                          index: 1,
                          emailController: _patientEmailController,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
