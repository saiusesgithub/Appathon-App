# ShadowMesh

Offline-first Bluetooth chat + file transfer toolkit.

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).

## Example

```dart
import 'package:device_apps/device_apps.dart';

Future<void> uninstallShadowMesh() async {
	await DeviceApps.uninstallApp('com.example.shadowmesh');
}
```

## Installing

```yaml
dependencies:
	device_apps: ^2.1.1
```

Run:

```bash
flutter pub get
```

### Android manifest setup

```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
<uses-permission android:name="android.permission.REQUEST_DELETE_PACKAGES" />
```

## Versions

| Plugin | ShadowMesh |
| ------ | ---------- |
| device_apps ^2.1.1 | 1.0.0 |

## Scores

No scores are tracked for this internal build.

## Device Apps plugin for Flutter

Used for uninstalling the app through the Kill Switch and managing discoverability of installed apps.

Refer to the [official README](https://pub.dev/packages/device_apps) for full API coverage.
