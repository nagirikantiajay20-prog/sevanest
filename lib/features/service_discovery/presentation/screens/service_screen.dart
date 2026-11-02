import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/widgets/sn_photo.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/catalog_providers.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/providers/requirement_draft_provider.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_scaffold.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';

/// `/discover/category` (screen 06, step 1 of 6): pick the service.
/// States: loading skeleton, list, searching, no result, error, empty, selected.
class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({this.edit = false, super.key});

  /// Opened from a "Change" chip / Review: Continue returns instead of moving on.
  final bool edit;

  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setQuery(String q) => setState(() => _query = q);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final selectedId = ref.watch(requirementDraftProvider).serviceId;
    final selected = ref.watch(selectedCategoryProvider);

    final list = categories.value;
    Widget results;
    if (categories.hasError && list == null) {
      results = SliverToBoxAdapter(
        child: StepErrorCard(
          title: l10n.serviceLoadFailedTitle,
          body: l10n.discoverLoadFailedBody,
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
      );
    } else if (list == null) {
      results = const SliverToBoxAdapter(child: _ServiceSkeleton());
    } else if (list.isEmpty) {
      results = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            l10n.serviceEmptyTitle,
            key: const Key('discover_empty'),
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontSize: 15, color: dsText),
          ),
        ),
      );
    } else {
      final shown = list.where((c) => c.matches(_query)).toList();
      results = shown.isEmpty
          ? SliverToBoxAdapter(
              child: _NoResult(
                query: _query,
                onClear: () {
                  _search.clear();
                  _setQuery('');
                },
              ),
            )
          : SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ServiceRow(
                index: i,
                category: shown[i],
                selected: shown[i].id == selectedId,
                onTap: () => ref
                    .read(requirementDraftProvider.notifier)
                    .setService(shown[i].id),
              ),
            );
    }

    return DiscoverScaffold(
      step: 1,
      title: l10n.discoverTitle,
      confirmBack: true,
      continueLabel: selected == null
          ? null
          : l10n.discoverContinueWith(selected.name),
      onContinue: selected == null
          ? null
          : () => discoverContinue(
              context,
              edit: widget.edit,
              next: Routes.discoverEngagement,
            ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 22),
              child: DiscoverRise(
                delayMs: 0,
                child: StepHeading(
                  heading: l10n.serviceHeading,
                  sub: l10n.serviceSub,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: DiscoverRise(
                delayMs: 160,
                child: _SearchField(
                  controller: _search,
                  focus: _focus,
                  hint: l10n.serviceSearchHint,
                  clearLabel: l10n.serviceClearSearch,
                  onChanged: _setQuery,
                  onClear: () {
                    _search.clear();
                    _setQuery('');
                  },
                ),
              ),
            ),
          ),
          results,
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

/// Frosted search box; ringed in teal while focused.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.clearLabel,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final String clearLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final on = focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: on
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.18),
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: DiscoverGlass(
        radius: 18,
        borderColor: on ? AppColors.teal : const Color(0xE6FFFFFF),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded, size: 22, color: dsNavy),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('discover_search_field'),
                  controller: controller,
                  focusNode: focus,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: AppText.body.copyWith(fontSize: 16, color: dsNavy),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppText.body.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  key: const Key('discover_search_clear'),
                  tooltip: clearLabel,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: dsMuted,
                  ),
                  onPressed: onClear,
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// One service: photo, serif name, description, optional "Popular" pill and a radio mark.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.index,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photo = AppPhotos.forService('${category.id} ${category.name}');
    const ms = Duration(milliseconds: 300);
    return DiscoverRise(
      delayMs: 200.0 + index * 70,
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        label: category.name,
        child: AnimatedSlide(
          duration: ms,
          curve: Curves.easeOutBack,
          offset: Offset(0, selected ? -3 / 92 : 0),
          child: DiscoverGlass(
            radius: 24,
            borderColor: selected ? AppColors.teal : const Color(0xE6FFFFFF),
            borderWidth: 2,
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment(-0.6, -1),
                    end: Alignment(0.6, 1),
                    colors: [Color(0xF2E2EEEC), Color(0xB3FFFFFF)],
                  )
                : null,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: Key('discover_category_tile_${category.id}'),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 92),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        _Thumb(
                          photo: photo,
                          icon: category.icon,
                          zoom: selected,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.name, style: authSerif(19, 1.2)),
                              const SizedBox(height: 2),
                              Text(
                                category.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body.copyWith(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  color: dsText,
                                ),
                              ),
                              if (category.popular) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2EEEC),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.servicePopular,
                                    style: AppText.label.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.teal
                                : const Color(0xB3FFFFFF),
                            border: Border.all(
                              width: 2,
                              color: selected
                                  ? AppColors.teal
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  key: Key('discover_category_check'),
                                  size: 17,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 66px rounded photo (icon when the design has none for this service); zooms when [zoom].
class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.icon, required this.zoom});
  final String? photo;
  final IconData icon;
  final bool zoom;

  @override
  Widget build(BuildContext context) => Container(
    width: 66,
    height: 66,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(19),
      boxShadow: [
        BoxShadow(
          color: dsNavy.withValues(alpha: 0.2),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: photo == null
        ? ColoredBox(
            color: const Color(0xFFE2EEEC),
            child: Icon(icon, color: AppColors.teal),
          )
        : AnimatedScale(
            duration: const Duration(milliseconds: 500),
            scale: zoom ? 1.14 : 1,
            child: Image.asset(
              photo!,
              fit: BoxFit.cover,
              cacheWidth: 200,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => ColoredBox(
                color: const Color(0xFFE2EEEC),
                child: Icon(icon, color: AppColors.teal),
              ),
            ),
          ),
  );
}

class _ServiceSkeleton extends StatelessWidget {
  const _ServiceSkeleton();

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: ValueListenableBuilder<double>(
        valueListenable: clock,
        builder: (context, t, _) {
          final x = -1 + 2 * ((t / 1400) % 1);
          Widget bar(double h, {double? w, double r = 10}) => Container(
            height: h,
            width: w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              gradient: LinearGradient(
                begin: Alignment(x - 1, 0),
                end: Alignment(x + 1, 0),
                colors: [
                  dsNavy.withValues(alpha: 0.07),
                  dsNavy.withValues(alpha: 0.15),
                  dsNavy.withValues(alpha: 0.07),
                ],
              ),
            ),
          );
          return Column(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DiscoverGlass(
                    radius: 24,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                      child: Row(
                        children: [
                          bar(66, w: 66, r: 19),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                bar(16, w: 110),
                                const SizedBox(height: 10),
                                bar(12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoverRise(
      delayMs: 0,
      child: DiscoverGlass(
        radius: 26,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE2EEEC),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 28,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.serviceNoMatch(query.trim()),
                    key: const Key('discover_no_result'),
                    textAlign: TextAlign.center,
                    style: authSerif(20, 1.25),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.serviceNoMatchBody,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(fontSize: 14, color: dsText),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const Key('discover_clear_search_btn'),
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    foregroundColor: dsNavy,
                    backgroundColor: const Color(0xCCFFFFFF),
                    side: const BorderSide(color: dsNavy, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: AppText.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(l10n.serviceClearSearch),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
