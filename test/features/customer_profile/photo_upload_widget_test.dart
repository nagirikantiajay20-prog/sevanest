// WIDGET tests: both photo uploads (profile photo, address home photo) share `checkPhoto`.
// Limits (JPEG/PNG, 5 MB) are provisional client rules until the backend confirms them.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/presentation/widgets/home_photo_field.dart';
import 'package:sevanest_customer/features/customer_profile/domain/customer_photo.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/customer_photo_providers.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/widgets/profile_photo_avatar.dart';

import '../../helpers/fakes.dart';

Uint8List _png([int len = 64]) =>
    Uint8List(len)..setAll(0, [0x89, 0x50, 0x4E, 0x47]);
final _gif = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 1, 2]);
const _timeout =
    "We're taking a little longer than expected. Please try again.";
const _badFormat = 'Use a JPG or PNG photo.';
const _tooBig = 'That photo is over 5 MB. Choose a smaller one.';

class _Photos implements CustomerPhotoRepository {
  int uploads = 0;
  Object? fail;
  Completer<void>? gate;

  @override
  Future<ProfilePhoto?> current() async => null;

  @override
  Future<void> upload(PickedPhoto photo) async {
    uploads++;
    await gate?.future;
    final f = fail;
    if (f != null) throw f;
  }
}

void main() {
  late _Photos repo;
  setUp(() => repo = _Photos());

  Future<void> pumpProfile(WidgetTester t) async {
    await t.pumpWidget(
      testApp(
        const Center(child: ProfilePhotoAvatar(initials: 'AB')),
        overrides: [customerPhotoRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> pickProfile(WidgetTester t, Uint8List? bytes) async {
    debugPickProfilePhoto = (_) async =>
        bytes == null ? null : XFile.fromData(bytes);
    addTearDown(() => debugPickProfilePhoto = null);
    await t.tap(find.byKey(const Key('profile_photo_btn')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('profile_photo_gallery_option')));
    await t.pump();
    await t.pump();
  }

  group('profile photo', () {
    testWidgets('a GIF is refused with a message and nothing is uploaded', (
      t,
    ) async {
      await pumpProfile(t);
      await pickProfile(t, _gif);
      expect(find.text(_badFormat), findsOneWidget);
      expect(repo.uploads, 0);
    });

    testWidgets('over 5 MB is refused with the size message', (t) async {
      await pumpProfile(t);
      await pickProfile(t, _png(maxHomePhotoBytes + 1));
      expect(find.text(_tooBig), findsOneWidget);
      expect(repo.uploads, 0);
    });

    testWidgets('backing out of the picker uploads nothing, says nothing', (
      t,
    ) async {
      await pumpProfile(t);
      await pickProfile(t, null);
      expect(repo.uploads, 0);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('while uploading: spinner, tile disabled, no second upload', (
      t,
    ) async {
      repo.gate = Completer();
      await pumpProfile(t);
      await pickProfile(t, _png());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        t.widget<InkResponse>(find.byKey(const Key('profile_photo_btn'))).onTap,
        isNull,
      );
      await t.tap(
        find.byKey(const Key('profile_photo_btn')),
        warnIfMissed: false,
      );
      await t.pump();
      expect(repo.uploads, 1);
      repo.gate!.complete();
      await t.pumpAndSettle();
      expect(find.text('Photo updated'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    for (final c in <(String, AppFailure, String)>[
      ('timeout', const NetworkFailure(null, true), _timeout),
      (
        'offline',
        const NetworkFailure(),
        "Couldn't reach SevaNest. Check your connection and try again.",
      ),
      (
        'server',
        const ServerFailure('Prisma stack trace'),
        'Our servers are having trouble. Please try again shortly.',
      ),
    ]) {
      testWidgets(
        'a ${c.$1} failure shows a friendly message, then the retry works',
        (t) async {
          repo.fail = c.$2;
          await pumpProfile(t);
          await pickProfile(t, _png());
          await t.pumpAndSettle();
          expect(find.text(c.$3), findsOneWidget);
          expect(find.textContaining('Prisma'), findsNothing);
          expect(
            t
                .widget<InkResponse>(find.byKey(const Key('profile_photo_btn')))
                .onTap,
            isNotNull,
          );
          repo.fail = null;
          await t.pumpAndSettle(const Duration(seconds: 5));
          await pickProfile(t, _png());
          await t.pumpAndSettle();
          expect(repo.uploads, 2);
          expect(find.text('Photo updated'), findsOneWidget);
        },
      );
    }
  });

  group('address home photo', () {
    PickedPhoto? got;
    setUp(() => got = null);

    Future<void> pumpHome(WidgetTester t, {bool enabled = true}) async {
      await t.pumpWidget(
        testApp(
          SingleChildScrollView(
            child: HomePhotoField(
              photo: got,
              url: null,
              enabled: enabled,
              onPicked: (p) => got = p,
              onRemoved: () {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    Future<void> pickHome(WidgetTester t, Uint8List? bytes) async {
      debugPickHomePhoto = (_) async =>
          bytes == null ? null : XFile.fromData(bytes);
      addTearDown(() => debugPickHomePhoto = null);
      await t.tap(find.byKey(const Key('home_photo_add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('home_photo_gallery_option')));
      await t.pumpAndSettle();
    }

    testWidgets('a GIF is refused and never handed on', (t) async {
      await pumpHome(t);
      await pickHome(t, _gif);
      expect(find.text(_badFormat), findsOneWidget);
      expect(got, isNull);
    });

    testWidgets('over 5 MB is refused and never handed on', (t) async {
      await pumpHome(t);
      await pickHome(t, _png(maxHomePhotoBytes + 1));
      expect(find.text(_tooBig), findsOneWidget);
      expect(got, isNull);
    });

    testWidgets('backing out hands nothing on and shows no error', (t) async {
      await pumpHome(t);
      await pickHome(t, null);
      expect(got, isNull);
      expect(find.text(_badFormat), findsNothing);
    });

    testWidgets('a valid PNG is handed on', (t) async {
      await pumpHome(t);
      await pickHome(t, _png());
      expect(got?.contentType, 'image/png');
    });

    testWidgets('while the address is saving the tile cannot be tapped', (
      t,
    ) async {
      await pumpHome(t, enabled: false);
      await t.tap(find.byKey(const Key('home_photo_add')), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('home_photo_gallery_option')), findsNothing);
    });
  });

  test('both flows judge the same bytes the same way (shared checkPhoto)', () {
    expect(checkPhoto(_png()), PhotoCheck.ok);
    expect(checkPhoto(_gif), PhotoCheck.badFormat);
    expect(checkPhoto(Uint8List(0)), PhotoCheck.badFormat);
    expect(checkPhoto(_png(maxHomePhotoBytes + 1)), PhotoCheck.tooBig);
  });
}
