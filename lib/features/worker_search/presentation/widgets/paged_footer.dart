import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/core/localization/failure_message.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:sevanest_customer/shared/models/paged_state.dart';

/// Last row of a cursor-paged list: a loader while the next page loads, or a retry button when
/// that page failed (the list above is kept).
class PagedFooter extends StatelessWidget {
  const PagedFooter({
    required this.page,
    required this.onRetry,
    this.retryKey = const Key('results_load_more_retry_btn'),
    super.key,
  });

  final PagedState<Object?> page;
  final VoidCallback onRetry;
  final Key retryKey;

  @override
  Widget build(BuildContext context) {
    if (page.loadMoreError != null) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: TextButton(
          key: retryKey,
          onPressed: onRetry,
          child: Text(
            '${l10n.resultsLoadMoreRetry}\n${failureMessage(l10n, page.loadMoreError!)}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (page.isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: CircularProgressIndicator(key: Key('results_footer_loader')),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// A first page that does not fill the viewport never scrolls, so the end-of-list listener never
/// fires: ask for the next page ourselves. Not after a failure, or it would retry in a loop.
void loadMoreIfShort(
  ScrollController controller,
  PagedState<Object?> page,
  VoidCallback loadMore,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller.hasClients &&
        controller.position.maxScrollExtent <= 0 &&
        page.loadMoreError == null &&
        page.canLoadMore) {
      loadMore();
    }
  });
}
