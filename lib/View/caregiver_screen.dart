// FILE: lib/View/caregiver_screen.dart
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

// Check your imports match your folder structure exactly
import '../Model/relationship_connection.dart';
import '../config/api.dart';
import '../services/relationship_service.dart';
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
    String displayName = "My Name";
    try {
      final profile = await UserDataService.getUserData();
      final nameVal = profile['username'];
      if (nameVal is String && nameVal.isNotEmpty) {
        displayName = nameVal;
      }
    } catch (e) {
      // ignore
    }

    if (fetchedUserId == null || fetchedUserId.isEmpty) {
      setState(() {
        caregiverLink = 'Unable to load user ID';
        patientLink = 'Unable to load user ID';
        _connectionError = 'Please log in to share invites.';
      });
      return;
    }

    userId = fetchedUserId;
    caregiverLink = RelationshipService.buildDeepLink(
        role: 'caregiver', inviterId: userId!, inviterName: displayName);
    patientLink = RelationshipService.buildDeepLink(
        role: 'patient', inviterId: userId!, inviterName: displayName);
    caregiverShareLink = RelationshipService.buildHostedInviteLink(
        role: 'caregiver', inviterId: userId!, inviterName: displayName);
    patientShareLink = RelationshipService.buildHostedInviteLink(
        role: 'patient', inviterId: userId!, inviterName: displayName);

    setState(() {});
    await _loadConnections();
  }

  Future<String?> _resolveCurrentUserId() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return "demo_user_123456";
  }

  Future<void> _loadConnections() async {
    final currentUserId = userId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    setState(() {
      _connectionsLoading = true;
      _connectionError = null;
    });

    try {
      final caregivers =
          await RelationshipService.fetchCaregivers(currentUserId);
      final patients = await RelationshipService.fetchPatients(currentUserId);

      if (!mounted) return;
      setState(() {
        _caregivers = caregivers;
        _patients = patients;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionError = 'Unable to load network.';
      });
    } finally {
      if (mounted) setState(() => _connectionsLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadConnections();
  }

  bool _ensureShareLink(String link) {
    if (link.isNotEmpty) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite link not ready yet.')));
    return false;
  }

  String _getShareText(String link, String type) {
    return type == 'caregiver'
        ? 'Join me as a caregiver on RemindMe! 🏥\n$link'
        : 'I need care on RemindMe! 💊\n$link';
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
    await Clipboard.setData(ClipboardData(text: text));
    final uri = Uri.parse('https://instagram.com/');
    await _launchUri(uri, 'Link copied! Open Instagram manually.');
  }

  Future<void> _shareViaFacebook(String link, String type) async {
    if (!_ensureShareLink(link)) return;
    final uri = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}');
    await _launchUri(uri, 'Unable to open Facebook.');
  }

  Future<void> _shareViaEmail(String link, String type,
      {bool isGmail = false}) async {
    if (!_ensureShareLink(link)) return;
    final subject =
        type == 'caregiver' ? 'Join me on RemindMe' : 'Help me on RemindMe';
    final body = _getShareText(link, type);
    final params = {'subject': subject, 'body': body};
    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    Uri emailLaunchUri = isGmail
        ? Uri.parse('googlegmail:///co?$query')
        : Uri.parse('mailto:?$query');

    try {
      if (!await launchUrl(emailLaunchUri,
          mode: LaunchMode.externalApplication)) {
        if (isGmail) await _shareViaEmail(link, type, isGmail: false);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Email app')));
    }
  }

  Future<void> _launchUri(Uri uri, String fallbackMessage) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw 'Could not launch';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(fallbackMessage)));
    }
  }

  Widget _buildPremiumQRCode(String data, double size) {
    if (data.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
        child: const Center(
            child: CircularProgressIndicator(color: Color(0xffFF9FA0))),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xffFF9FA0).withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: size,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black),
    );
  }

  Widget _buildInviteSection(
      {required String title,
      required String subtitle,
      required IconData icon,
      required String qrData,
      required String displayLink,
      required String shareLink,
      required String type,
      required int index}) {
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
                    const Color(0xffFF9FA0).withValues(alpha: 0.12),
                    const Color(0xffE8E9FF).withValues(alpha: 0.18),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: const Color(0xffFF9FA0).withValues(alpha: 0.25),
                    width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color:
                                const Color(0xffFF9FA0).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18)),
                        child: Icon(icon,
                            color: const Color(0xffFF9FA0), size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(child: _buildPremiumQRCode(qrData, 200.0)),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: displayLink));
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Link copied!"),
                                duration: Duration(seconds: 1)));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                const Color(0xffFF9FA0).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link,
                              color: Color(0xffFF9FA0), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(displayLink,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          const Icon(Icons.copy, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildLogoButton(
                          url: _logoUrls['whatsapp']!,
                          label: 'WhatsApp',
                          onTap: () => _shareViaWhatsApp(shareLink, type),
                          delay: 0),
                      _buildLogoButton(
                          url: _logoUrls['instagram']!,
                          label: 'Instagram',
                          onTap: () => _shareViaInstagram(shareLink, type),
                          delay: 50),
                      _buildLogoButton(
                          url: _logoUrls['facebook']!,
                          label: 'Facebook',
                          onTap: () => _shareViaFacebook(shareLink, type),
                          delay: 100),
                      _buildLogoButton(
                          url: _logoUrls['gmail']!,
                          label: 'Gmail',
                          onTap: () =>
                              _shareViaEmail(shareLink, type, isGmail: true),
                          delay: 150),
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

  Widget _buildLogoButton(
      {required String url,
      required String label,
      required VoidCallback onTap,
      required int delay}) {
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
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 4)
                      ]),
                  child: Image.network(url,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.share, color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
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
        title: const Text('RemindMe',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInviteSection(
                      title: 'Invite Caregiver',
                      subtitle: 'Share with someone who can help',
                      icon: Icons.people_rounded,
                      qrData: caregiverLink ?? '',
                      displayLink: caregiverLink ?? 'Loading...',
                      shareLink: caregiverShareLink ?? '',
                      type: 'caregiver',
                      index: 0),
                  _buildInviteSection(
                      title: 'Invite People to Care',
                      subtitle: 'Let loved ones join',
                      icon: Icons.favorite_rounded,
                      qrData: patientLink ?? '',
                      displayLink: patientLink ?? 'Loading...',
                      shareLink: patientShareLink ?? '',
                      type: 'patient',
                      index: 1),
                  const SizedBox(height: 32),
                  const Text('Your network',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (_connectionsLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        _buildConnectionSection(
                            title: 'Caregivers',
                            emptyText: 'No caregivers yet',
                            connections: _caregivers,
                            color: const Color(0xffFFB2B4),
                            icon: Icons.volunteer_activism),
                        const SizedBox(height: 16),
                        _buildConnectionSection(
                            title: 'Patients',
                            emptyText: 'No patients yet',
                            connections: _patients,
                            color: const Color(0xffA5E5DD),
                            icon: Icons.health_and_safety),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionSection(
      {required String title,
      required String emptyText,
      required List<RelationshipConnection> connections,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 30)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          if (connections.isEmpty)
            Text(emptyText, style: TextStyle(color: Colors.grey[600]))
          else
            ...connections.map((c) => ListTile(
                  leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.4),
                      child: Text(c.name[0])),
                  title: Text(c.name),
                  subtitle: Text(c.phoneNumber),
                )),
        ],
      ),
    );
  }
}
