import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sevanest_customer/core/storage/receipt_files.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key of the unfinished requirement (service, address snapshot, timing, budget).
/// It belongs to one customer, so it is removed whenever a session ends or a new one starts.
const requirementDraftPrefKey = 'requirement_draft_v1';

typedef PrefsSource = Future<SharedPreferences> Function();
typedef DirectoriesSource = Future<List<Directory>> Function();

Future<List<Directory>> _defaultReceiptDirectories() async {
  final dirs = <Directory>[];
  for (final source in <Future<Directory?> Function()>[
    getExternalStorageDirectory,
    getApplicationDocumentsDirectory,
  ]) {
    try {
      final d = await source();
      if (d != null) dirs.add(d);
    } on Object {
      // not available on this platform
    }
  }
  return dirs;
}

void _clearImageMemoryCache() {
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}

/// Removes the data one customer leaves on the device so the next account never sees it.
///
/// Application-level cleanup only: it deletes the app's own preference key, receipt PDFs and the
/// in-memory image cache. It does not claim to erase bytes from the storage medium, and it leaves
/// shared, non-account data (device id, notification choices, pending-payment safety net) alone.
/// Every step is best effort and never throws, so a failed cleanup cannot block logout.
class AccountDataCleaner {
  const AccountDataCleaner({
    this.prefs = SharedPreferences.getInstance,
    this.receiptDirectories = _defaultReceiptDirectories,
    this.clearImages = _clearImageMemoryCache,
  });

  final PrefsSource prefs;
  final DirectoriesSource receiptDirectories;
  final void Function() clearImages;

  /// Just the persisted requirement draft (used when a new session starts).
  Future<void> clearDraft() => _guard(() async {
    await (await prefs()).remove(requirementDraftPrefKey);
  });

  /// Everything account-specific: the draft, saved receipts and cached images.
  Future<void> clear() async {
    await clearDraft();
    await _guard(_deleteReceipts);
    await _guard(() async => clearImages());
  }

  Future<void> _deleteReceipts() async {
    for (final dir in await receiptDirectories()) {
      await _guard(() async {
        if (!dir.existsSync()) return;
        await for (final e in dir.list(followLinks: false)) {
          if (e is! File) continue;
          final name = e.uri.pathSegments.last;
          if (name.startsWith(receiptFilePrefix) && name.endsWith('.pdf')) {
            await _guard(() async {
              await e.delete();
            });
          }
        }
      });
    }
  }

  Future<void> _guard(Future<void> Function() step) async {
    try {
      await step();
    } on Object {
      // best effort: the session still ends
    }
  }
}

final accountDataCleanerProvider = Provider<AccountDataCleaner>(
  (_) => const AccountDataCleaner(),
);
