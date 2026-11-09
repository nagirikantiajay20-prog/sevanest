import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/account_data_cleaner.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/service_discovery/domain/timing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _draftKey = requirementDraftPrefKey;

/// Single source of truth for the requirement being built. Every change is persisted so the app
/// can resume after being killed mid-requirement (call [restore] on start).
///
/// The draft belongs to the signed-in customer: it is dropped (memory and storage) the moment the
/// session ends, including an expiry that does not rebuild the provider scope, and it is only
/// restored while a session exists.
class RequirementDraftNotifier extends Notifier<RequirementDraft> {
  @override
  RequirementDraft build() {
    ref.listen<AuthStatus>(authProvider, (_, next) {
      if (next == AuthStatus.unauthenticated) _discard();
    });
    return const RequirementDraft();
  }

  void _discard() {
    ref.read(requirementNoteProvider.notifier).set('');
    state = const RequirementDraft();
    _persist(); // empty draft => removes the stored copy (also covers an in-flight write)
  }

  void _set(RequirementDraft d) {
    state = d;
    _persist();
  }

  /// "Hire help" / "Find a worker" and "discard": always starts clean.
  void reset() {
    ref.read(requirementNoteProvider.notifier).set('');
    _set(const RequirementDraft());
  }

  /// Category tile on Home: fresh draft with the service preset.
  void startWithService(String serviceId) {
    ref.read(requirementNoteProvider.notifier).set('');
    _set(RequirementDraft(serviceId: serviceId));
  }

  /// Picking a different service clears everything that depended on it (DISC-03).
  void setService(String id) {
    if (state.serviceId != id) _set(state.withService(id));
  }

  /// Drops an engagement the chosen service doesn't offer (stale resumed draft).
  void clearEngagement() {
    final id = state.serviceId;
    if (id != null && state.engagement != null) _set(state.withService(id));
  }

  /// A different engagement drops timing it can't use and any budget priced for the old one.
  void setEngagement(EngagementType t) => _set(state.withEngagement(t));

  void setAddress(Address a) => _set(state.withAddress(a));

  void setTiming(Timing? t) => _set(state.withTiming(t));

  void setStartDate(DateTime? d) => _set(state.withStartDate(d));

  void setBudget(Budget? b) => _set(state.withBudget(b));

  Future<void> restore() async {
    try {
      if (ref.read(authProvider) != AuthStatus.authenticated) return;
      final raw = (await SharedPreferences.getInstance()).getString(_draftKey);
      // The session may have ended while the read was pending: never revive a stale draft.
      if (ref.read(authProvider) != AuthStatus.authenticated) return;
      if (raw != null && state.isEmpty) {
        state = RequirementDraft.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } on Object {
      // A corrupt or unavailable draft just means starting fresh.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.isEmpty) {
        await prefs.remove(_draftKey);
      } else {
        await prefs.setString(_draftKey, jsonEncode(state.toJson()));
      }
    } on Object {
      // Persistence is best-effort.
    }
  }
}

final requirementDraftProvider =
    NotifierProvider<RequirementDraftNotifier, RequirementDraft>(
      RequirementDraftNotifier.new,
    );

/// The optional "note for the worker" typed on Review; the interview request starts from it.
class RequirementNoteNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String note) => state = note;
}

final requirementNoteProvider =
    NotifierProvider<RequirementNoteNotifier, String>(
      RequirementNoteNotifier.new,
    );
