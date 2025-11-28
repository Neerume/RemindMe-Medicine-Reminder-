import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Model/relationship_connection.dart';
import '../config/api.dart';
import '../services/relationship_service.dart';
import '../services/user_data_service.dart';
import 'package:share_plus/share_plus.dart';  // Add this

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen>
    with TickerProviderStateMixin {
  String? caregiverLink;
  String? patientLink;
  String? caregiverShareLink;
  String? patientShareLink;
  String? userId;
  bool _connectionsLoading = false;
  String? _connectionError;
  List<RelationshipConnection> _caregivers = [];
  List<RelationshipConnection> _patients = [];
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
    final fetchedUserId = await _resolveCurrentUserId();
    final profile = await UserDataService.getUserData();
    final displayName = profile['username'] ?? '';

    if (fetchedUserId == null || fetchedUserId.isEmpty) {
      setState(() {
        caregiverLink = 'Unable to load user ID';
        patientLink = 'Unable to load user ID';
        _connectionError = 'Please log in to share invites.';
      });
      return;
    }

    userId = fetchedUserId;

    // In-app deep link
    caregiverLink = RelationshipService.buildDeepLink(
      role: 'caregiver',
      inviterId: userId!,
      inviterName: displayName,
    );
    patientLink = RelationshipService.buildDeepLink(
      role: 'patient',
      inviterId: userId!,
      inviterName: displayName,
    );

    caregiverShareLink = RelationshipService.buildHostedInviteLink(
      role: 'caregiver',
      inviterId: userId!,
      inviterName: displayName,
    );

    patientShareLink = RelationshipService.buildHostedInviteLink(
      role: 'patient',
      inviterId: userId!,
      inviterName: displayName,
    );


    setState(() {});
    await _loadConnections();
  }

  Future<String?> _resolveCurrentUserId() async {
    final storedId = await UserDataService.getUserId();
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    final token = await UserDataService.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getProfile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedId = data['_id'] ?? data['id'];
        final fetchedName = data['name'];

        if (fetchedName is String && fetchedName.isNotEmpty) {
          await UserDataService.updateUsername(fetchedName);
        }

        if (fetchedId is String && fetchedId.isNotEmpty) {
          await UserDataService.saveUserId(fetchedId);
          return fetchedId;
        }
      }
    } catch (_) {
      // ignore and allow UI to handle missing ID
    }

    return null;
  }

  Future<void> _loadConnections() async {
    final currentUserId = userId;
    if (currentUserId == null || currentUserId.isEmpty) {
      setState(() {
        _connectionError = 'Please log in to view caregivers.';
      });
      return;
    }

    setState(() {
      _connectionsLoading = true;
      _connectionError = null;
    });

    try {
      final caregivers = await RelationshipService.fetchCaregivers(currentUserId);
      final patients = await RelationshipService.fetchPatients(currentUserId);

      if (!mounted) return;
      setState(() {
        _caregivers = caregivers;
        _patients = patients;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionError = 'Unable to load your network. Pull to refresh.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _connectionsLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadConnections();
  }

  Future<void> _shareLink(String link) async {
    await Share.share(link);
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

  bool _ensureShareLink(String link) {
    if (link.isNotEmpty) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite link not ready yet. Please try again.'),
      ),
    );
    return false;
  }

  Future<void> _shareViaWhatsApp(String link, String type) async {
    if (!_ensureShareLink(link)) return;
    final text = _getShareText(link, type);
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await _launchUri(uri, 'Could not open WhatsApp.');
  }

  Future<void> _shareViaInstagram(String link, String type) async {
    if (!_ensureShareLink(link)) return;
    final text = _getShareText(link, type);

    // Copy to clipboard (Instagram cannot open deep links)
    await Clipboard.setData(ClipboardData(text: text));

    // Open Instagram app or website
    final uri = Uri.parse('https://instagram.com/');
    await _launchUri(uri, 'Unable to open Instagram. Text copied to clipboard!');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied! Paste it in Instagram Direct.'),
        ),
      );
    }
  }

  Future<void> _shareViaFacebook(String link, String type) async {
    if (!_ensureShareLink(link)) return;
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
    );
    await _launchUri(uri, 'Unable to open Facebook.');
  }

  Future<void> _shareViaEmail(String link, String type,
      {bool isGmail = false}) async {
    if (!_ensureShareLink(link)) return;
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
    required String displayLink,
    required String shareLink,
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
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: displayLink));

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Link copied to clipboard!"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
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
                                  displayLink,
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
                        onTap: () => _shareViaWhatsApp(shareLink, type),
                        delay: 0,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['instagram']!,
                        label: 'Instagram',
                        onTap: () => _shareViaInstagram(shareLink, type),
                        delay: 50,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['facebook']!,
                        label: 'Facebook',
                        onTap: () => _shareViaFacebook(shareLink, type),
                        delay: 100,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['gmail']!,
                        label: 'Gmail',
                        onTap: () => _shareViaEmail(shareLink, type, isGmail: true),
                        delay: 150,
                      ),
                      _buildLogoButton(
                        url: _logoUrls['email']!,
                        label: 'Email',
                        onTap: () => _shareViaEmail(shareLink, type, isGmail: false),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTablet = constraints.maxWidth > 700;
              final double horizontalPadding = isTablet ? 48 : 20;

              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                            subtitle: 'Share with someone who can help manage your care',
                            icon: Icons.people_rounded,
                            qrData: caregiverLink ?? '',
                            displayLink: caregiverLink ?? 'Loading...',
                            shareLink: caregiverShareLink ?? caregiverLink ?? '',
                            type: 'caregiver',
                            index: 0,
                          ),
                          _buildInviteSection(
                            title: 'Invite People to Care',
                            subtitle: 'Let loved ones join your care journey',
                            icon: Icons.favorite_rounded,
                            qrData: patientLink ?? '',
                            displayLink: patientLink ?? 'Loading...',
                            shareLink: patientShareLink ?? patientLink ?? '',
                            type: 'patient',
                            index: 1,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Your network',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'See who is synced with you as caregivers or patients.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 20),
                          _buildConnectionsContent(),
                        ],
                      ),
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

  Widget _buildConnectionsContent() {
    if (_connectionsLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_connectionError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _connectionError!,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _connectionsLoading ? null : _loadConnections,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildConnectionSection(
          title: 'Your caregivers',
          emptyText: 'No caregivers yet. Share your caregiver link to get started.',
          connections: _caregivers,
          color: const Color(0xffFFB2B4),
          icon: Icons.volunteer_activism,
        ),
        const SizedBox(height: 16),
        _buildConnectionSection(
          title: 'People you care for',
          emptyText: 'No patients yet. Share your patient link to help others.',
          connections: _patients,
          color: const Color(0xffA5E5DD),
          icon: Icons.health_and_safety,
        ),
      ],
    );
  }

  Widget _buildConnectionSection({
    required String title,
    required String emptyText,
    required List<RelationshipConnection> connections,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (connections.isNotEmpty)
                Text(
                  '${connections.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (connections.isEmpty)
            Text(
              emptyText,
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildConnectionCard(connections[index], color);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: connections.length,
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(RelationshipConnection connection, Color color) {
    final avatarImage = _avatarFromBase64(connection.photo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.4),
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? Text(
                    connection.name.isNotEmpty ? connection.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connection.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  connection.phoneNumber,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _avatarFromBase64(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      final cleaned = data.contains(',') ? data.split(',').last : data;
      final bytes = base64Decode(cleaned);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}
