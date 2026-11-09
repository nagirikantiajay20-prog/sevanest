// UNIT tests: draft rules and persistence (the app resumes mid-requirement).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/domain/requirement_draft.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _addr = Address(
  id: 'a1',
  line: 'Flat 1',
  area: 'Madhapur',
  city: 'Hyderabad',
  pincode: '500081',
  isDefault: true,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A signed-in customer: the draft is only saved and restored while a session exists.
  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [authProvider.overrideWith(_SignedIn.new)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('JSON round trip keeps service, engagement and address', () {
    const d = RequirementDraft(
      serviceId: 'cook',
      engagement: EngagementType.partTime,
      address: _addr,
    );
    final back = RequirementDraft.fromJson(d.toJson());
    expect(back.serviceId, 'cook');
    expect(back.engagement, EngagementType.partTime);
    expect(back.address?.pincode, '500081');
    expect(back.address?.isDefault, isTrue);
  });

  test('a different service clears the engagement but keeps the address', () {
    final n = make().read(requirementDraftProvider.notifier)
      ..setService('cook')
      ..setEngagement(EngagementType.daily)
      ..setAddress(_addr)
      ..setService('maid');
    final s = n.state;
    expect(s.serviceId, 'maid');
    expect(s.engagement, isNull);
    expect(s.address?.id, 'a1');
  });

  test('choosing the same service keeps the engagement', () {
    final n = make().read(requirementDraftProvider.notifier)
      ..setService('cook')
      ..setEngagement(EngagementType.daily)
      ..setService('cook');
    expect(n.state.engagement, EngagementType.daily);
  });

  test('startWithService / reset', () {
    final c = make();
    final n = c.read(requirementDraftProvider.notifier)
      ..setAddress(_addr)
      ..startWithService('driver');
    expect(n.state.serviceId, 'driver');
    expect(n.state.address, isNull);
    n.reset();
    expect(n.state.isEmpty, isTrue);
  });

  test('restore brings back a persisted draft; reset forgets it', () async {
    final c1 = make();
    c1.read(requirementDraftProvider.notifier)
      ..setService('cook')
      ..setEngagement(EngagementType.hourly);
    await Future<void>.delayed(Duration.zero);

    final c2 = make();
    await c2.read(requirementDraftProvider.notifier).restore();
    expect(c2.read(requirementDraftProvider).serviceId, 'cook');
    expect(c2.read(requirementDraftProvider).engagement, EngagementType.hourly);

    c2.read(requirementDraftProvider.notifier).reset();
    await Future<void>.delayed(Duration.zero);
    final c3 = make();
    await c3.read(requirementDraftProvider.notifier).restore();
    expect(c3.read(requirementDraftProvider).isEmpty, isTrue);
  });

  test('restore never overwrites a draft already in progress', () async {
    final c1 = make();
    c1.read(requirementDraftProvider.notifier).setService('cook');
    await Future<void>.delayed(Duration.zero);
    final c2 = make();
    c2.read(requirementDraftProvider.notifier).state = const RequirementDraft(
      serviceId: 'maid',
    );
    await c2.read(requirementDraftProvider.notifier).restore();
    expect(c2.read(requirementDraftProvider).serviceId, 'maid');
  });
}

class _SignedIn extends AuthNotifier {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}
