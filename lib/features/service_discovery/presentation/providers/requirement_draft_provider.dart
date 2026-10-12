import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';

class RequirementDraftNotifier extends Notifier<RequirementDraft> {
  @override
  RequirementDraft build() => const RequirementDraft();

  /// "Hire help" / "Find a worker": always starts clean.
  void reset() => state = const RequirementDraft();

  /// Category tile on Home: fresh draft with the service preset.
  void startWithService(String serviceId) =>
      state = RequirementDraft(serviceId: serviceId);
}

final requirementDraftProvider =
    NotifierProvider<RequirementDraftNotifier, RequirementDraft>(
      RequirementDraftNotifier.new,
    );
