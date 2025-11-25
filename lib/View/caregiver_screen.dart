import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
// Note: Ensure this import path is correct for your project
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
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // -- Image URLs for Real Logos --
  final Map<String, String> _logoUrls = {
    'whatsapp':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/512px-WhatsApp.svg.png',
    'instagram':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Instagram_icon.png/600px-Instagram_icon.png',
    'facebook':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/512px-2021_Facebook_icon.svg.png',
    'gmail':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Gmail_icon_%282020%29.svg/512px-Gmail_icon_%282020%29.svg.png',
    'email':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Mail_iOS.svg/512px-Mail_iOS.svg.png',
  };

  @override
  void initState() {
    super.initState();
    _loadLinks();
    // Animation Setup
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
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadLinks() async {
    // Assuming this service returns your user data
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
                'Link copied!',
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

  // --- Sharing Logic ---

  String _getShareText(String link, String type) {
    return type == 'caregiver'
        ? 'Join me as a caregiver on RemindMe! 🏥\n$link'
        : 'I need care on RemindMe! 💊\n$link';
  }

  String _getShareSubject(String type) {
    return type == 'caregiver'
        ? 'Join me on RemindMe'
        : 'Help me with care on RemindMe';
  }

  Future<void> _shareViaWhatsApp(String link, String type) async {
    final text = _getShareText(link, type);
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await _launchUri(uri, 'Could not open WhatsApp.');
  }

  Future<void> _shareViaInstagram(String link, String type) async {
    // Instagram doesn't support easy "Share text" deep linking directly to DM like WA.
    // Standard behavior: Copy text and open Instagram.
    final text = _getShareText(link, type);
    await Clipboard.setData(ClipboardData(text: text));

    // Try opening Instagram
    final uri = Uri.parse('https://instagram.com/');
    await _launchUri(
        uri, 'Unable to open Instagram. Text copied to clipboard!');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Link copied! Paste it in Instagram Direct.')),
      );
    }
  }

  Future<void> _shareViaFacebook(String link, String type) async {
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
    );
    await _launchUri(uri, 'Unable to open Facebook.');
  }

  Future<void> _shareViaEmail(String link, String type,
      {bool isGmail = false}) async {
    final subject = _getShareSubject(type);
    final body = _getShareText(link, type);

    // Encode parameters to handle spaces and special characters
    final params = {
      'subject': subject,
      'body': body,
    };

    final String query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    Uri emailLaunchUri;

    if (isGmail) {
      // Tries to force open the Gmail App via URL Scheme
      emailLaunchUri = Uri.parse('googlegmail:///co?$query');
    } else {
      // Standard system email
      emailLaunchUri = Uri.parse('mailto:?$query');
    }

    try {
      if (!await launchUrl(emailLaunchUri,
          mode: LaunchMode.externalApplication)) {
        // If Gmail scheme fails (app not installed), fall back to standard mailto
        if (isGmail) {
          await _shareViaEmail(link, type, isGmail: false);
        } else {
          throw 'Could not launch email';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${isGmail ? "Gmail" : "Email app"}'),
          ),
        );
      }
    }
  }

  Future<void> _launchUri(Uri uri, String fallbackMessage) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch';
      }
    } catch (e) {
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

  // --- UI Components ---

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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xffFF9FA0).withOpacity(0.12),
                    const Color(0xffE8E9FF).withOpacity(0.18),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color(0xffFF9FA0).withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffFF9FA0).withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffFF9FA0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon,
                            color: const Color(0xffFF9FA0), size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // QR Code
                  Center(child: _buildPremiumQRCode(qrData, 200.0)),
                  const SizedBox(height: 24),

                  // Copy Link Field
                  InkWell(
                    onTap: () => _copyLink(link),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xffFF9FA0).withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffFF9FA0).withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]),
                      child: Row(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.link,
                                  color: Color(0xffFF9FA0), size: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Invite Link",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  link,
                                  style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: const Color(0xffFF9FA0),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.copy,
                                  size: 16, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Share Section
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            height: 1, width: 20, color: Colors.grey[300]),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Share via',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        Container(
                            height: 1, width: 20, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Real Logos Grid
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildLogoButton(
                        url: _logoUrls['whatsapp']!,
                        label: 'WhatsApp',
                        onTap: () => _shareViaWhatsApp(link, type),
                        delay: 0,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['instagram']!,
                        label: 'Instagram',
                        onTap: () => _shareViaInstagram(link, type),
                        delay: 50,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['facebook']!,
                        label: 'Facebook',
                        onTap: () => _shareViaFacebook(link, type),
                        delay: 100,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['gmail']!,
                        label: 'Gmail',
                        onTap: () => _shareViaEmail(link, type, isGmail: true),
                        delay: 150,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['email']!,
                        label: 'Email',
                        onTap: () => _shareViaEmail(link, type, isGmail: false),
                        delay: 200,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoButton({
    required String url,
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
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      // Fallback logic if internet fails
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.share,
                            color: Colors.grey, size: 24);
                      },
                      // Loading logic
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
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
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Use local asset for your main app logo if available
            Image.asset(
              'assets/1.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) =>
                  const Icon(Icons.favorite, color: Color(0xffFF9FA0)),
            ),
            const SizedBox(width: 12),
            const Text(
              'RemindMe',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 26),
            onPressed: () {},
            color: Colors.grey[800],
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              highlightColor: const Color(0xffFF9FA0).withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: LayoutBuilder(builder: (context, constraints) {
            // Tablet responsiveness check
            final bool isTablet = constraints.maxWidth > 700;
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 24, vertical: 24),
                  children: [
                    _buildInviteSection(
                      title: 'Invite Caregiver',
                      subtitle:
                          'Share with someone who can help manage your care',
                      icon: Icons.health_and_safety_rounded,
                      qrData: caregiverLink ?? '',
                      link: caregiverLink ?? 'Loading...',
                      type: 'caregiver',
                      index: 0,
                    ),
                    const SizedBox(height: 8),
                    _buildInviteSection(
                      title: 'Invite Patient',
                      subtitle: 'Let loved ones join your care journey',
                      icon: Icons.volunteer_activism_rounded,
                      qrData: patientLink ?? '',
                      link: patientLink ?? 'Loading...',
                      type: 'patient',
                      index: 1,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
