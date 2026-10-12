import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Install id sent as `deviceId` on OTP verify ("one active session per device").
/// Not a secret, so shared_preferences is fine (tokens stay in the secure store).
abstract interface class DeviceIdStore {
  Future<String> get();
}

class PrefsDeviceIdStore implements DeviceIdStore {
  static const _key = 'device_id';
  String? _cached;

  @override
  Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    // Backend validates the format; a v4 UUID is accepted (verified live).
    final id = prefs.getString(_key) ?? const Uuid().v4();
    await prefs.setString(_key, id);
    return _cached = id;
  }
}

final deviceIdStoreProvider = Provider<DeviceIdStore>(
  (ref) => PrefsDeviceIdStore(),
);
