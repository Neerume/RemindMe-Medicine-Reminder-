import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../View/invite_Screen.dart';
import '../routes.dart';
import 'app_navigator.dart';
import 'relationship_service.dart';
import 'user_data_service.dart';
import 'invite_notification_service.dart';
import '../Model/invite_info.dart';

class InviteLinkService {
  InviteLinkService._();

  static final InviteLinkService instance = InviteLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  get initialRoute => null;

  Object? get initialArgs => null;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (err) => debugPrint('Invite link error: $err'),
    );
  }
  Future<void> handleInviteLink(Uri uri) async {
    await _handleUri(uri);
  }


  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  bool _isCustomScheme(Uri uri) {
    return uri.scheme == RelationshipService.inviteScheme &&
        uri.host == RelationshipService.inviteHost &&
        uri.path == RelationshipService.invitePath;
  }

  bool _isHostedLink(Uri uri) {
    return uri.scheme == 'https' &&
        uri.host == 'neerume.github.io' &&
        uri.path.startsWith('/remindme_links/');
  }

  Future<void> _handleUri(Uri? uri) async {
    if (uri == null) return;
    if (!_isCustomScheme(uri) && !_isHostedLink(uri)) return;

    final inviterId = uri.queryParameters['inviterId'];
    final role = uri.queryParameters['role'];
    final inviterName = uri.queryParameters['inviterName'];

    if (inviterId == null ||
        inviterId.isEmpty ||
        role == null ||
        role.isEmpty) {
      return;
    }

    // Save invite info locally
    await UserDataService.saveInviteInfo(
      inviterId: inviterId,
      role: role,
      inviterName: inviterName,
    );

    // Check if user is logged in
    final userId = await UserDataService.getUserId();
    final navigator = AppNavigator.navigatorKey.currentState;

    if (userId == null) {
      navigator?.pushNamedAndRemoveUntil(AppRoutes.signup, (route) => false);
      return;
    }

    // Send pending invite to backend
    try {
      if (role == 'caregiver') {
        await RelationshipService.inviteCaregiver(
            inviterId: inviterId, inviteeId: userId);
      } else if (role == 'patient') {
        await RelationshipService.invitePatient(
            inviterId: inviterId, inviteeId: userId);
      }
    } catch (e) {
      debugPrint('Failed to create invite: $e');
    }

    // Navigate to InviteScreen
    navigator?.push(
      MaterialPageRoute(
        builder: (_) => InviteScreen(
          inviterId: inviterId,
          role: role,
          inviterName: inviterName,
        ),
      ),
    );
  }
}
