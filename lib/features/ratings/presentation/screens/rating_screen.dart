import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevanest_customer/app/router/routes.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/core/widgets/async_value_view.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/core/widgets/sn_chip.dart';
import 'package:sevanest_customer/core/widgets/sn_header.dart';
import 'package:sevanest_customer/features/booking/domain/booking.dart';
import 'package:sevanest_customer/features/booking/presentation/providers/booking_providers.dart';
import 'package:sevanest_customer/features/ratings/domain/rating.dart';
import 'package:sevanest_customer/features/ratings/presentation/providers/rating_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/providers/worker_search_providers.dart';
import 'package:sevanest_customer/features/worker_search/presentation/widgets/worker_card.dart';
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
    return Scaffold(
      backgroundColor: AppColors.canvasCool,
      body: Column(
        children: [
          SnHeader(
            title: l10n.ratingTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.bookings),
          ),
          Expanded(child: _content(l10n, booking, rated)),
        ],
      ),
    );
  }

  Widget _content(
    AppLocalizations l10n,
    AsyncValue<Booking> booking,
    AsyncValue<Rating?> rated,
  ) {
    return _thanks
        ? _Message(
            key: const Key('rating_thanks'),
            icon: Icons.favorite,
            title: l10n.ratingThanksTitle,
            body: l10n.ratingThanksBody,
            onDone: _toBooking,
          )
        : AsyncValueView<Booking>(
            value: booking,
            onRetry: () => ref.invalidate(bookingProvider(widget.bookingId)),
            data: (b) => AsyncValueView<Rating?>(
              value: rated,
              onRetry: () =>
                  ref.invalidate(bookingRatingProvider(widget.bookingId)),
              data: (existing) {
                if (existing != null || _alreadyRated) {
                  return _Message(
                    key: const Key('rating_already_rated'),
                    icon: Icons.star,
                    title: l10n.ratingAlreadyTitle,
                    score: existing?.score,
                    scale: ref.watch(ratingScaleMaxProvider).value ?? 5,
                    body: existing?.review,
                    onDone: _toBooking,
                  );
                }
                if (_notEligible || !b.actions.contains(BookingAction.rate)) {
                  return _Message(
                    key: const Key('rating_not_eligible'),
                    icon: Icons.info_outline,
                    title: l10n.ratingNotEligibleTitle,
                    body: l10n.ratingNotEligibleBody,
                    onDone: _toBooking,
                  );
                }
                return _form(l10n, b);
              },
            ),
          );
  }

  Widget _form(AppLocalizations l10n, Booking b) {
    final scale = ref.watch(ratingScaleMaxProvider).value ?? 5;
    final max = ref.watch(ratingReviewMaxProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.worker != null) ...[
            SnCard(
              key: const Key('rating_worker_card'),
              child: Row(
                children: [
                  WorkerAvatar(b.worker!, radius: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      b.categoryName ?? b.worker!.categories.firstOrNull ?? '',
                      style: AppText.heading,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Center(
            child: Text(
              l10n.ratingQuestion,
              style: AppText.screenTitle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (var n = 1; n <= scale; n++)
                IconButton(
                  key: Key('rating_star_$n'),
                  tooltip: l10n.ratingStarLabel(n, scale),
                  iconSize: 36,
                  onPressed: _sending
                      ? null
                      : () => setState(() {
                          _score = n;
                          _tags.clear();
                        }),
                  icon: Icon(
                    n <= (_score ?? 0) ? Icons.star : Icons.star_border,
                    color: n <= (_score ?? 0)
                        ? AppColors.amber
                        : AppColors.slate,
                  ),
                ),
            ],
          ),
          Center(
            child: Text(
              _score == null
                  ? l10n.ratingTapHint
                  : l10n.ratingStarLabel(_score!, scale),
              key: const Key('rating_score_label'),
            ),
          ),
          if (_offered(scale).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              _offered(scale).first.positive
                  ? l10n.ratingTagsGood
                  : l10n.ratingTagsBad,
              style: AppText.label,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in _offered(scale))
                  SnChip(
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
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.ratingReviewLabel, style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('rating_comment_field'),
            controller: _comment,
            enabled: !_sending,
            maxLength: max,
            maxLines: 5,
            decoration: InputDecoration(hintText: l10n.ratingReviewHint),
          ),
          Text(l10n.ratingReviewNote, style: AppText.meta),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              key: const Key('rating_error'),
              style: AppText.body.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_score == null)
            Center(
              child: Text(
                l10n.ratingChoose,
                key: const Key('rating_choose_hint'),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SnButton(
            key: const Key('rating_submit_btn'),
            label: l10n.ratingSubmit,
            variant: SnButtonVariant.deep,
            isLoading: _sending,
            onPressed: _score == null ? null : _submit,
          ),
          SnButton(
            key: const Key('rating_skip_btn'),
            label: l10n.ratingSkip,
            variant: SnButtonVariant.text,
            onPressed: _sending ? null : _toBooking,
          ),
        ],
      ),
    );
  }
}

/// Thank-you, already-rated and not-eligible states: no form, one way back to the booking.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.onDone,
    this.body,
    this.score,
    this.scale = 5,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? body;
  final int? score;
  final int scale;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.tealWash,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 2),
              ),
              child: Icon(icon, size: 40, color: AppColors.teal),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppText.title, textAlign: TextAlign.center),
            if (score != null)
              Text(
                l10n.ratingStarLabel(score!, scale),
                key: const Key('rating_existing_score'),
              ),
            if (body != null && body!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(body!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: AppSpacing.lg),
            SnButton(
              key: const Key('rating_done_btn'),
              label: l10n.ratingDone,
              variant: SnButtonVariant.deep,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
