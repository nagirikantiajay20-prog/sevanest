import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/core/mock/mock_api.dart';
import 'package:sevanest_customer/core/network/dio_provider.dart';
import 'package:sevanest_customer/features/service_discovery/data/catalog_repository_mock.dart';
import 'package:sevanest_customer/features/service_discovery/data/catalog_repository_remote.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';

/// Live backend in stg / prod (and in dev when switched on); seeded mock otherwise.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final live = ref.watch(mockApiProvider.select((s) => s.live));
  return live
      ? CatalogRepositoryRemote(ref.watch(dioProvider))
      : CatalogRepositoryMock(() => ref.read(mockApiProvider));
});

/// `GET /catalog/categories`. Re-fetches when the dev menu changes the mock behaviour.
final categoriesProvider = FutureProvider.autoDispose<List<ServiceCategory>>((
  ref,
) {
  ref.watch(mockApiProvider);
  return ref.read(catalogRepositoryProvider).categories();
});

/// The category chosen in the draft, once the catalogue is loaded.
final selectedCategoryProvider = Provider.autoDispose<ServiceCategory?>((ref) {
  final id = ref.watch(requirementDraftProvider.select((d) => d.serviceId));
  final list = ref.watch(categoriesProvider).value;
  if (id == null || list == null) return null;
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});
