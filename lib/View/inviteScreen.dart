import 'package:flutter/material.dart';

import '../services/relationship_service.dart';
import '../services/user_data_service.dart';
import 'dashboard_screen.dart';

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
    if (userId == null) {
      setState(() {
        _error = 'Please log in to respond to invitations.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final message = await RelationshipService.respondToInvite(
        inviterId: widget.inviterId,
        inviteeId: userId,
        type: widget.role,
        action: action,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await UserDataService.clearInviteInfo();

      if (action == 'accept') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(initialIndex: 2),
          ),
          (_) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to update invite. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                    fontWeight: FontWeight.w600,
                                  ),
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCaregiverInvite ? Icons.medical_services : Icons.favorite,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isCaregiverInvite
                                    ? 'You will appear under “People you care for”.'
                                    : 'They will appear in “Your caregivers”.',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
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
                onPressed: _isProcessing ? null : () => _respondInvite('accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Accept invite',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isProcessing ? null : () => _respondInvite('reject'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              const Text(
                'Need someone else to help? Share your link from the caregiver tab anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
