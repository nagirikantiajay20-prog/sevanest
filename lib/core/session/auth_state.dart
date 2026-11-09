import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/storage/account_data_cleaner.dart';
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

  /// The last local-data cleanup started by [signIn] / [signOut]. Cleanup runs beside the session
  /// change (it must never delay or block it); tests await this to see its result.
  Future<void> pendingCleanup = Future<void>.value();

  Future<void> signIn({required String access, required String refresh}) async {
    // A new session never inherits an unfinished requirement, even if the last cleanup failed.
    pendingCleanup = ref.read(accountDataCleanerProvider).clearDraft();
    await _store.write(access: access, refresh: refresh);
    state = AuthStatus.authenticated;
  }

  /// The one way a session ends: explicit logout, expired refresh token, "sign in again" on the
  /// splash. Account data on the device goes with it (best effort, never blocks sign-out).
  Future<void> signOut() async {
    await _store.clear();
    pendingCleanup = ref.read(accountDataCleanerProvider).clear();
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
