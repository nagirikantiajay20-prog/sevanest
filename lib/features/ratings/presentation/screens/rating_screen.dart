import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_glass.dart'
    show AuthCta;
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';
import 'package:sevanest_customer/features/ratings/presentation/providers/rating_providers.dart';
import 'package:sevanest_customer/features/ratings/presentation/widgets/rating_parts.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/support/presentation/widgets/support_glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_page.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_parts.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/glass_success_overlay.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// `/ratings/:id` (module doc 10.3). There is no eligibility endpoint, so eligibility is the
/// booking's allowed actions (`rate`) plus "no rating exists yet" (`GET /ratings/bookings/{id}`).
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({required this.bookingId, super.key});
  final String bookingId;

  @override
  ConsumerState<RatingScreen> createState() => _State();
}

class _State extends ConsumerState<RatingScreen> {
  final _comment = TextEditingController();
  int? _score;
  final _tags = <String>{};
  var _sending = false;
  var _thanks = false;
  var _alreadyRated = false;
  var _notEligible = false;
  String? _error;

  /// One key per form: a retry after a lost answer returns the first rating, never a second.
  final _key = const Uuid().v4();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _toBooking() =>
      context.go(Routes.path(Routes.bookingDetail, {'id': widget.bookingId}));

  /// Tags offered for the score: praise from 4 up, complaints at 2 and below, none between.
  /// (The backend accepts any pairing; this pairing is the design's, pending client approval.)
  List<RatingTag> _offered(int scale) {
    final s = _score;
    if (s == null) return const [];
    final all = ref.read(ratingTagsProvider);
    final praise = s * 5 >= scale * 4;
    if (!praise && s * 5 > scale * 2) return const [];
    return all.where((t) => t.positive == praise).toList();
  }

  Future<void> _submit() async {
    final score = _score;
    if (score == null || _sending) return;
    final l10n = AppLocalizations.of(context);
    final offered = _offered(ref.read(ratingScaleMaxProvider).value ?? 5);
    final tags = [
      for (final t in offered)
        if (_tags.contains(t.code)) t.code,
    ];
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(ratingRepositoryProvider)
          .submit(
            widget.bookingId,
            score: score,
            review: _comment.text,
            tags: tags,
            idempotencyKey: _key,
          );
      ref
        ..invalidate(bookingRatingProvider(widget.bookingId))
        ..invalidate(myRatingsProvider)
        ..invalidate(bookingProvider(widget.bookingId))
        ..invalidate(bookingListProvider);
      if (mounted) setState(() => _thanks = true);
    } on ConflictFailure catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'RATING_ALREADY_EXISTS') {
          _alreadyRated = true;
        } else {
          _error = l10n.errorGeneric;
        }
      });
    } on ValidationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'RATING_NOT_ELIGIBLE') {
          _notEligible = true;
        } else if (e.code == 'RATING_SCORE_OUT_OF_SCALE') {
          _score = null;
          _error = l10n.ratingScaleError;
        } else if (_comment.text.trim().length >
            ref.read(ratingReviewMaxProvider)) {
          // 400 for a review over `ratingReviewMax` (the field cap makes this rare).
          _error = l10n.ratingReviewTooLong(ref.read(ratingReviewMaxProvider));
        } else {
          _error = l10n.errorGeneric;
        }
      });
    } on Object catch (e) {
      // The stars and the comment stay.
      if (mounted) {
        setState(
          () => _error =
              e is NetworkFailure ||
                  e is ServerFailure ||
                  e is UnauthorizedFailure ||
                  e is ForbiddenFailure
              ? failureMessage(l10n, e)
              : l10n.errorGeneric,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final booking = ref.watch(bookingProvider(widget.bookingId));
    final rated = ref.watch(bookingRatingProvider(widget.bookingId));
    final b = booking.value;
    final existing = rated.value;
    final showForm =
        !_thanks &&
        b != null &&
        rated.hasValue &&
        existing == null &&
        !_alreadyRated &&
        !_notEligible &&
        b.actions.contains(BookingAction.rate);
    return FindGlassPage(
      title: l10n.ratingTitle,
      backLabel: l10n.back,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(Routes.bookings),
      overlay: _thanks
          ? KeyedSubtree(
              key: const Key('rating_thanks'),
              child: GlassSuccessOverlay(
                title: l10n.ratingThanksTitle,
                body: l10n.ratingThanksBody,
                rows: const [],
                ctaKey: const Key('rating_done_btn'),
                ctaLabel: l10n.ratingDone,
                onPressed: _toBooking,
              ),
            )
          : null,
      bottom: showForm
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (ctx) => AuthCta(
                    key: const Key('rating_submit_btn'),
                    clock: DiscoverClock.of(ctx),
                    label: l10n.ratingSubmit,
                    loadingLabel: l10n.ratingSubmit,
                    loading: _sending,
                    breathe: true,
                    showArrow: false,
                    radius: 18,
                    height: 58,
                    onPressed: _score == null ? null : _submit,
                  ),
                ),
                TextButton(
                  key: const Key('rating_skip_btn'),
                  onPressed: _sending ? null : _toBooking,
                  child: Text(l10n.ratingSkip),
                ),
              ],
            )
          : null,
      body: _thanks
          ? const SizedBox.shrink()
          : GlassAsyncView<Booking>(
              value: booking,
              onRetry: () => ref.invalidate(bookingProvider(widget.bookingId)),
              data: (b) => GlassAsyncView<Rating?>(
                value: rated,
                onRetry: () =>
                    ref.invalidate(bookingRatingProvider(widget.bookingId)),
                data: (existing) {
                  if (existing != null || _alreadyRated) {
                    return RatingMessage(
                      key: const Key('rating_already_rated'),
                      icon: Icons.star_rounded,
                      title: l10n.ratingAlreadyTitle,
                      score: existing?.score,
                      scale: ref.watch(ratingScaleMaxProvider).value ?? 5,
                      body: existing?.review,
                      onDone: _toBooking,
                    );
                  }
                  if (_notEligible || !b.actions.contains(BookingAction.rate)) {
                    return RatingMessage(
                      key: const Key('rating_not_eligible'),
                      icon: Icons.info_outline_rounded,
                      title: l10n.ratingNotEligibleTitle,
                      body: l10n.ratingNotEligibleBody,
                      onDone: _toBooking,
                    );
                  }
                  return _form(l10n, b);
                },
              ),
            ),
    );
  }

  Widget _form(AppLocalizations l10n, Booking b) {
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final max = ref.watch(ratingReviewMaxProvider);
    final offered = _offered(scale);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        RatingHero(
          booking: b,
          score: _score,
          scale: scale,
          enabled: !_sending,
          onScore: (n) => setState(() {
            _score = n;
            _tags.clear();
          }),
        ),
        if (offered.isNotEmpty)
          SupportSection(
            title: offered.first.positive
                ? l10n.ratingTagsGood
                : l10n.ratingTagsBad,
            hint: l10n.hintOptional,
            delayMs: 80,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in offered)
                  RatingChip(
                    key: Key('rating_tag_${t.code}'),
                    label: t.label,
                    selected: _tags.contains(t.code),
                    onTap: _sending
                        ? null
                        : () => setState(() {
                            _tags.contains(t.code)
                                ? _tags.remove(t.code)
                                : _tags.add(t.code);
                          }),
                  ),
              ],
            ),
          ),
        SupportSection(
          title: l10n.ratingReviewLabel,
          hint: l10n.hintOptional,
          delayMs: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassNoteField(
                key: const Key('rating_comment_field'),
                controller: _comment,
                enabled: !_sending,
                maxLength: max,
                minLines: 3,
                hint: l10n.ratingReviewHint,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.ratingReviewNote,
                style: AppText.body.copyWith(fontSize: 13, color: dsMuted),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SupportNotice(
              key: const Key('rating_error'),
              icon: Icons.error_outline_rounded,
              iconColor: supportDanger,
              title: _error!,
            ),
          ),
      ],
    );
  }
}
