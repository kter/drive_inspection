# PermissionService Contract

**Service**: PermissionService
**Purpose**: Manage runtime permissions for motion sensors across iOS and Android
**Type**: Internal service interface

---

## Interface Definition

```dart
abstract class IPermissionService {
  /// Check current permission status for motion sensors
  ///
  /// Does not request permission, only checks current state.
  ///
  /// Returns: Future<PermissionStatus> indicating current permission state
  Future<PermissionStatus> checkPermissionStatus();

  /// Request motion sensor permission from user
  ///
  /// On iOS: Shows system permission dialog
  /// On Android: No-op (accelerometer doesn't require permission)
  ///
  /// Returns: Future<PermissionStatus> indicating granted/denied result
  Future<PermissionStatus> requestPermission();

  /// Open app settings for user to manually enable permission
  ///
  /// Useful when permission is permanently denied.
  ///
  /// Returns: Future<bool> - true if settings opened successfully
  Future<bool> openAppSettings();

  /// Check if permission can be requested
  ///
  /// Returns false if permission is permanently denied or restricted.
  ///
  /// Returns: bool indicating if request is possible
  bool canRequestPermission(PermissionStatus status);
}
```

---

## Behavior Specifications

### Permission Status Flow

```
Initial State: notDetermined
  ↓
[User grants] → granted → Service can access sensor
  ↓
[User denies] → denied → Show error message
  ↓
[User denies with "don't ask"] → permanentlyDenied → Show settings link
  ↓
[System restricted] → restricted → Show error (parental controls, etc.)
```

### Platform-Specific Behavior

**iOS**:
- `notDetermined`: Permission not yet requested
- First call to requestPermission() shows system dialog
- User choice persists (granted/denied)
- Requires NSMotionUsageDescription in Info.plist

**Android**:
- Always returns `granted` (no permission needed for accelerometer)
- requestPermission() is no-op
- checkPermissionStatus() always returns PermissionStatus.granted

### Error Scenarios

**Missing Info.plist Entry (iOS)**:
```dart
// App crashes with error:
// "This app has crashed because it attempted to access privacy-sensitive data
// without a usage description."
//
// Prevention: Always include NSMotionUsageDescription
```

**Permanently Denied**:
```dart
final status = await service.checkPermissionStatus();
if (status == PermissionStatus.permanentlyDenied) {
  // Show UI with "Open Settings" button
  await service.openAppSettings();
}
```

**Restricted (iOS Parental Controls)**:
```dart
if (status == PermissionStatus.restricted) {
  // Show error: "Motion sensor access is restricted by device settings"
  // User cannot grant permission (system-level restriction)
}
```

---

## State Transitions

### PermissionStatus Enum

```dart
enum PermissionStatus {
  /// Permission not yet requested (iOS only)
  notDetermined,

  /// User granted permission
  granted,

  /// User denied permission (can request again)
  denied,

  /// User denied with "don't ask again" (Android)
  permanentlyDenied,

  /// System-level restriction (iOS parental controls)
  restricted,
}
```

### Valid Transitions

```
notDetermined → granted       (user approves)
notDetermined → denied        (user denies)
denied → granted              (user approves on retry)
denied → permanentlyDenied    (user denies with "don't ask")
Any → restricted              (system restriction applied)
```

### Invalid Transitions

```
granted → denied              (❌ permission cannot be revoked programmatically)
permanentlyDenied → granted   (❌ requires user action in Settings)
restricted → granted          (❌ requires system-level change)
```

---

## Testing Contract

### Unit Tests Required

1. **Status checking**
   - Mock platform: iOS → notDetermined initially
   - Mock platform: Android → always granted

2. **Permission request**
   - iOS: Request shows dialog → returns granted/denied
   - Android: Request is no-op → returns granted

3. **Settings navigation**
   - openAppSettings() → returns true if successful
   - Verify platform-specific settings URLs

4. **Permission validation**
   - canRequestPermission(granted) → false
   - canRequestPermission(denied) → true
   - canRequestPermission(permanentlyDenied) → false
   - canRequestPermission(restricted) → false

### Mock Implementation

```dart
class MockPermissionService implements IPermissionService {
  PermissionStatus _status = PermissionStatus.notDetermined;

  @override
  Future<PermissionStatus> checkPermissionStatus() async {
    return _status;
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    if (_status == PermissionStatus.notDetermined) {
      _status = PermissionStatus.granted; // Simulate user approval
    }
    return _status;
  }

  // Set for testing
  void setMockStatus(PermissionStatus status) {
    _status = status;
  }

  // ... other methods
}
```

---

## UI Integration Patterns

### Permission Request Flow

```dart
class PermissionGate extends StatefulWidget {
  final Widget child;

  @override
  _PermissionGateState createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  late IPermissionService _permissionService;
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _permissionService = PermissionService();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await _permissionService.checkPermissionStatus();
    setState(() => _status = status);

    if (status == PermissionStatus.notDetermined) {
      _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    final status = await _permissionService.requestPermission();
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return LoadingScreen();
    }

    switch (_status!) {
      case PermissionStatus.granted:
        return widget.child; // Show main app

      case PermissionStatus.denied:
        return PermissionDeniedScreen(
          onRetry: _requestPermission,
        );

      case PermissionStatus.permanentlyDenied:
        return PermissionPermanentlyDeniedScreen(
          onOpenSettings: _permissionService.openAppSettings,
        );

      case PermissionStatus.restricted:
        return PermissionRestrictedScreen();

      case PermissionStatus.notDetermined:
        return RequestingPermissionScreen();
    }
  }
}
```

---

## Dependencies

**External**:
- permission_handler: ^11.3.1 (cross-platform permission management)

**Internal**:
- PermissionStatus (enum)

---

## Platform Configuration

### iOS Setup

**Info.plist** (Required):
```xml
<key>NSMotionUsageDescription</key>
<string>This app monitors vehicle acceleration for driving analysis.</string>
```

**Minimum Version**: iOS 12.0+

### Android Setup

**No configuration required** - Accelerometer doesn't need runtime permission

**Minimum SDK**: API 21 (Android 5.0 Lollipop)

---

## Performance Requirements

### Response Time
- checkPermissionStatus(): < 50ms (local check)
- requestPermission(): Variable (waits for user input)
- openAppSettings(): < 100ms (platform navigation)

### Memory
- Minimal footprint (< 100 KB)
- No persistent state beyond permission status

---

## Example Usage

```dart
// Check before initializing sensor service
final permissionService = PermissionService();
final status = await permissionService.checkPermissionStatus();

if (status == PermissionStatus.granted) {
  // Initialize accelerometer service
  await accelerometerService.initialize();
} else if (permissionService.canRequestPermission(status)) {
  // Request permission
  final newStatus = await permissionService.requestPermission();
  if (newStatus == PermissionStatus.granted) {
    await accelerometerService.initialize();
  }
} else if (status == PermissionStatus.permanentlyDenied) {
  // Show "Open Settings" button
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Permission Required'),
      content: Text('Please enable motion sensor access in Settings.'),
      actions: [
        TextButton(
          onPressed: () => permissionService.openAppSettings(),
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```
