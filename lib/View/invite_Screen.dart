import 'package:flutter/material.dart';

// Service Imports (Go up one folder '..', then into 'services')
import '../services/relationship_service.dart';
import '../services/user_data_service.dart';
import '../services/invite_notification_service.dart';
import '../Model/invite_info.dart';

// View Imports (Same folder, so no '..')
import 'dashboard_screen.dart';
import 'caregiver_screen.dart';

class InviteScreen extends StatefulWidget {
  final String inviterId;
  final String role; // 'caregiver' or 'patient'
  final String? inviterName;

  const InviteScreen({
    super.key,
    required this.inviterId,
    required this.role,
    this.inviterName,
  });

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _isProcessing = false;
  String? _error;

  Future<void> _respondInvite(String action) async {
    final userId = await UserDataService.getUserId();

    if (userId == null || userId.isEmpty) {
      setState(() => _error = 'Please log in to respond to invitations.');
      return;
    }

    if (userId.trim() == widget.inviterId.trim()) {
      setState(() => _error = 'You cannot invite yourself.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final message = await RelationshipService.respondToInvite(
        inviterId: widget.inviterId.trim(),
        inviteeId: userId.trim(),
        type: widget.role.trim(),
        action: action,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      await InviteNotificationService.removePendingInvite(
        widget.inviterId,
        widget.role,
      );

      await UserDataService.clearInviteInfo();

      if (!mounted) return;

      if (action == 'accept') {
        await UserDataService.markNewConnectionSynced();
        // Go to Caregiver Screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CaregiverScreen()),
          (_) => false,
        );
      } else {
        // Go to Dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const DashboardScreen(initialIndex: 0)),
          (_) => false,
        );
      }
    } catch (e) {
      print("Invite Error: $e");
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _skipInvite() async {
    await InviteNotificationService.addPendingInvite(
      InviteInfo(
        inviterId: widget.inviterId,
        role: widget.role,
        inviterName: widget.inviterName,
      ),
    );

    await UserDataService.clearInviteInfo();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen(initialIndex: 0)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCaregiverInvite = widget.role == 'caregiver';
    final inviteeRoleText = isCaregiverInvite ? 'caregiver' : 'patient';
    final inviterDisplayName = widget.inviterName ?? 'Someone on RemindMe';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Invitation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$inviterDisplayName invited you!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Accept to sync profiles and start sharing reminders as a $inviteeRoleText.',
                style: const TextStyle(color: Colors.black54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.person_add_alt_1, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inviterDisplayName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isCaregiverInvite
                                      ? 'Needs your help as a caregiver'
                                      : 'Wants to be under your care',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed:
                    _isProcessing ? null : () => _respondInvite('accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Accept invite'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed:
                    _isProcessing ? null : () => _respondInvite('reject'),
                child: const Text('Reject'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isProcessing ? null : _skipInvite,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
