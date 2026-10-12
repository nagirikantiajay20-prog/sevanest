import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Backend is the authority; this only mirrors whether we hold a session (AGENTS §9).
class AuthNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.unknown;

  SessionStore get _store => ref.read(sessionStoreProvider);

  Future<void> restore() async {
    final tokens = await _store.read();
    state = tokens == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
  }

  Future<void> signIn({required String access, required String refresh}) async {
    await _store.write(access: access, refresh: refresh);
    state = AuthStatus.authenticated;
  }

  Future<void> signOut() async {
    await _store.clear();
    ref.read(profileCompleteProvider.notifier).set(null);
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);

/// null = not yet known. Set from `GET /me` (modules/01_authentication.md).
class ProfileCompleteNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  // ignore: use_setters_to_change_properties
  void set(bool? value) => state = value;
}

final profileCompleteProvider =
    NotifierProvider<ProfileCompleteNotifier, bool?>(
      ProfileCompleteNotifier.new,
    );
