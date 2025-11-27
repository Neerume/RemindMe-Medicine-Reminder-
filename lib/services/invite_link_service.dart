  import 'dart:async';

  import 'package:app_links/app_links.dart';
  import 'package:flutter/material.dart';

  import '../View/inviteScreen.dart';
  import '../routes.dart';
  import 'app_navigator.dart';
  import 'relationship_service.dart';
  import 'user_data_service.dart';

  /// Handles inbound deep links so invite URLs open the correct screen.
  class InviteLinkService {
    InviteLinkService._();

    static final InviteLinkService instance = InviteLinkService._();

    final AppLinks _appLinks = AppLinks();
    StreamSubscription<Uri>? _sub;
    bool _initialized = false;

    Future<void> initialize() async {
      if (_initialized) return;
      _initialized = true;

      final initialUri = await _appLinks.getInitialAppLink();
      await _handleUri(initialUri);

      _sub = _appLinks.uriLinkStream.listen(
        (uri) => _handleUri(uri),
        onError: (err) => debugPrint('Invite link error: $err'),
      );
    }

    Future<void> dispose() async {
      await _sub?.cancel();
      _sub = null;
      _initialized = false;
    }

    Future<void> _handleUri(Uri? uri) async {
      if (uri == null) return;

      final isInviteScheme =
          uri.scheme == RelationshipService.inviteScheme &&
              uri.host == RelationshipService.inviteHost &&
              uri.path == RelationshipService.invitePath;

      if (!isInviteScheme) return;

      final inviterId = uri.queryParameters['inviterId'];
      final role = uri.queryParameters['role'];
      final inviterName = uri.queryParameters['inviterName'];

      if (inviterId == null || inviterId.isEmpty || role == null || role.isEmpty) {
        return;
      }

      await UserDataService.saveInviteInfo(
        inviterId: inviterId,
        role: role,
        inviterName: inviterName,
      );

      final navigator = AppNavigator.navigatorKey.currentState;
      if (navigator == null) return;

      final token = await UserDataService.getToken();
      if (token == null || token.isEmpty) {
        navigator.pushNamedAndRemoveUntil(AppRoutes.signup, (route) => false);
        return;
      }

      navigator.push(
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

