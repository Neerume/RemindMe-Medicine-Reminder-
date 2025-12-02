import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/invite_info.dart';

/// Service to manage pending invite notifications
class InviteNotificationService {
  static const String _keyPendingInvites = 'pending_invites';

  /// Add a pending invite to local storage
  static Future<void> addPendingInvite(InviteInfo invite) async {
    final prefs = await SharedPreferences.getInstance();
    final invitesJson = prefs.getString(_keyPendingInvites);
    
    List<InviteInfo> invites = [];
    if (invitesJson != null) {
      final List<dynamic> invitesList = json.decode(invitesJson);
      invites = invitesList.map((e) => InviteInfo.fromJson(e)).toList();
    }

    // Check if invite already exists (avoid duplicates)
    final exists = invites.any((inv) => 
      inv.inviterId == invite.inviterId && inv.role == invite.role);
    
    if (!exists) {
      invites.add(invite);
      final updatedJson = json.encode(
        invites.map((inv) => inv.toJson()).toList(),
      );
      await prefs.setString(_keyPendingInvites, updatedJson);
    }
  }

  /// Get all pending invites
  static Future<List<InviteInfo>> getPendingInvites() async {
    final prefs = await SharedPreferences.getInstance();
    final invitesJson = prefs.getString(_keyPendingInvites);
    
    if (invitesJson == null) {
      return [];
    }

    final List<dynamic> invitesList = json.decode(invitesJson);
    return invitesList.map((e) => InviteInfo.fromJson(e)).toList();
  }

  /// Remove a pending invite
  static Future<void> removePendingInvite(String inviterId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    final invitesJson = prefs.getString(_keyPendingInvites);
    
    if (invitesJson == null) {
      return;
    }

    final List<dynamic> invitesList = json.decode(invitesJson);
    final List<InviteInfo> invites = invitesList
        .map((e) => InviteInfo.fromJson(e))
        .where((inv) => !(inv.inviterId == inviterId && inv.role == role))
        .toList();

    final updatedJson = json.encode(
      invites.map((inv) => inv.toJson()).toList(),
    );
    await prefs.setString(_keyPendingInvites, updatedJson);
  }

  /// Clear all pending invites
  static Future<void> clearAllPendingInvites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingInvites);
  }

  /// Check if there are any pending invites
  static Future<bool> hasPendingInvites() async {
    final invites = await getPendingInvites();
    return invites.isNotEmpty;
  }
}

