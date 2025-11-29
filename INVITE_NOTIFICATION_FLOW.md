# Invite Notification Flow Implementation

## Overview
This document describes the complete invite notification and flow implementation that allows users to:
1. Receive invites via deep links
2. Skip invites for later (saved to dashboard notifications)
3. View pending invites in dashboard notifications
4. Accept/Decline invites from notifications
5. See profile sync after accepting

## Implementation Details

### 1. **InviteNotificationService** (`lib/services/invite_notification_service.dart`)
- Manages pending invites in local storage (SharedPreferences)
- Methods:
  - `addPendingInvite()` - Save an invite for later
  - `getPendingInvites()` - Retrieve all pending invites
  - `removePendingInvite()` - Remove a specific invite
  - `clearAllPendingInvites()` - Clear all pending invites
  - `hasPendingInvites()` - Check if any pending invites exist

### 2. **Updated InviteScreen** (`lib/View/invite_Screen.dart`)
- **Skip Behavior**: When user clicks "Skip for now":
  - Invite is saved to `InviteNotificationService`
  - User is navigated back to dashboard
  - Invite appears in dashboard notifications
  
- **Accept/Decline Behavior**: When user accepts or declines:
  - Invite is removed from pending invites
  - Backend is notified via `RelationshipService.respondToInvite()`
  - On accept: Navigates to Caregiver tab (index 2)
  - On decline: Returns to previous screen

### 3. **Updated DashboardScreen** (`lib/View/dashboard_screen.dart`)
- **Notification Drawer**: Shows both medicine reminders and pending invites
- **Invite Notifications**:
  - Display with pink icon (vs blue for medicine reminders)
  - Show inviter name and role
  - Clickable - opens `InviteScreen` when tapped
  - Can be deleted from drawer menu
  
- **Auto-refresh**: 
  - Loads pending invites on init
  - Reloads when returning from invite screen
  - Reloads when switching tabs

### 4. **Updated RelationshipService** (`lib/services/relationship_service.dart`)
- Added authentication headers to all API calls
- `respondToInvite()` now includes Bearer token
- `fetchCaregivers()` and `fetchPatients()` include authentication

### 5. **Updated NotificationEntry Model**
- Added `type` field ('medicine' or 'invite')
- Added `inviteInfo` field to store invite details
- Allows dashboard to differentiate between notification types

## User Flow

### Initial Invite Reception
1. User clicks invite link → `InviteLinkService` handles it
2. Backend creates pending invite record
3. `InviteScreen` opens automatically
4. User sees invite details with Accept/Decline/Skip options

### Skip Flow
1. User clicks "Skip for now"
2. Invite saved to local storage via `InviteNotificationService`
3. User navigated to dashboard
4. Invite appears in notification drawer (top-right icon)
5. User can click notification later to open `InviteScreen`

### Accept/Decline Flow
1. User clicks Accept or Decline
2. Backend API called (`/api/relationship/respond-invite`)
3. Backend updates both users' relationship status
4. Invite removed from pending invites
5. If accepted:
   - Relationship created in backend
   - Both users see updated connections
   - User navigated to Caregiver tab
   - Profiles become visible to each other

### Notification Click Flow
1. User sees invite notification in dashboard drawer
2. User clicks on invite notification
3. `InviteScreen` opens with invite details
4. User can Accept/Decline/Skip again
5. After action, returns to dashboard with updated notifications

## Backend Integration

The backend should handle:
- Creating pending invites when invite link is clicked
- Updating relationship status when invite is accepted/declined
- Notifying both users when invite status changes
- Returning pending invites when requested (if endpoint exists)

### API Endpoints Used
- `POST /api/relationship/invite/caregiver/:inviterId?userId=:inviteeId`
- `POST /api/relationship/invite/patient/:inviterId?userId=:inviteeId`
- `POST /api/relationship/respond-invite`
- `GET /api/relationship/caregivers`
- `GET /api/relationship/patients`

## Profile Sync

When an invite is accepted:
1. Backend creates relationship record
2. Both users can see each other in:
   - Caregiver tab (for patients)
   - Patient list (for caregivers)
3. Profiles become visible and synced
4. Both users receive notifications about the connection

## UI/UX Features

- **Visual Distinction**: Invite notifications use pink icons, medicine reminders use blue
- **Smooth Navigation**: Skip → Dashboard → Click → Invite Screen → Action
- **Persistent Storage**: Invites saved locally survive app restarts
- **Dynamic Updates**: Notifications update in real-time
- **Consistent State**: Both users see updated relationship status

## Testing Checklist

- [ ] Click invite link → InviteScreen opens
- [ ] Click Skip → Invite appears in dashboard notifications
- [ ] Click notification → InviteScreen opens
- [ ] Accept invite → Relationship created, navigate to Caregiver tab
- [ ] Decline invite → Invite removed, return to previous screen
- [ ] Delete notification → Invite removed from drawer
- [ ] Both users see updated relationship status
- [ ] Profiles visible after acceptance
- [ ] Multiple pending invites display correctly
- [ ] App restart preserves pending invites

## Files Modified

1. `lib/services/invite_notification_service.dart` (NEW)
2. `lib/View/invite_Screen.dart` (UPDATED)
3. `lib/View/dashboard_screen.dart` (UPDATED)
4. `lib/services/relationship_service.dart` (UPDATED)
5. `lib/services/invite_link_service.dart` (UPDATED - imports only)

## Notes

- Pending invites are stored locally using SharedPreferences
- Backend should handle relationship creation and notifications
- Both users' dashboards update when invite is accepted/declined
- Profile sync happens automatically via backend relationship management

