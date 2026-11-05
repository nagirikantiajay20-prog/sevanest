import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/core/config/app_config.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/core/session/auth_state.dart';
import 'package:sevanest_customer/core/storage/secure_session_store.dart';
import 'package:sevanest_customer/core/widgets/sn_button.dart';
import 'package:sevanest_customer/core/widgets/sn_card.dart';
import 'package:sevanest_customer/features/authentication/presentation/providers/auth_providers.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/auth_widgets.dart';
import 'package:sevanest_customer/features/authentication/presentation/widgets/motion.dart';
import 'package:sevanest_customer/features/customer_profile/presentation/providers/account_providers.dart';
import 'package:sevanest_customer/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown as "slow" after this long (design: "Still loading. Your connection seems slow.").
const splashSlowAfter = Duration(seconds: 4);

/// Give up and offer retry after this long (modules/01_authentication.md: >8 s).
const splashTimeout = Duration(seconds: 8);

/// Minimum time the branded splash stays up, so it never flashes past on a fast start.
const splashMinHold = Duration(milliseconds: 1800);

/// Overridden to [Duration.zero] in tests.
final splashHoldProvider = Provider<Duration>((_) => splashMinHold);

/// Whether the customer / worker choice is shown after the splash. Tests that only need to get
/// past the splash override it to false, which proceeds as a customer straight away.
final splashChoiceProvider = Provider<bool>((_) => true);

enum _Splash { loading, slow, choose, failed }

/// Restores the stored session, validates it with `GET /customers/me`, then lets the router
/// redirect (login / profile setup / home). Never leaves the user on a blank screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  _Splash _state = _Splash.loading;
  Timer? _slowTimer;
  bool _running = false;

  /// What "Proceed with Customer App" does once the session check is done (restore or sign out).
  Future<void> Function()? _enter;
  bool _entering = false;

  /// Milliseconds since the splash appeared; drives every animation (frozen in tests).
  final _now = ValueNotifier<double>(0);
  final _heroKey = GlobalKey();
  Ticker? _ticker;
  Rect? _hero;

  /// When the arch zoom started (ms on [_now]'s clock), once it has.
  double? _zoomAt;

  @override
  void initState() {
    super.initState();
    final animate =
        ref.read(splashHoldProvider) > Duration.zero &&
        !WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    if (animate) {
      _ticker = createTicker((d) {
        final t = d.inMicroseconds / 1000;
        if (_zoomAt == null && t >= _zoomAt0) _zoomAt = t;
        _now.value = t;
      })..start();
    } else {
      // Tests and reduced motion: show the finished screen, nothing keeps animating.
      _zoomAt = 0;
      _now.value = 100000;
    }
    Future.microtask(_boot);
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _ticker?.dispose();
    _now.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    if (_running) return;
    _running = true;
    setState(() => _state = _Splash.loading);
    _slowTimer?.cancel();
    _slowTimer = Timer(splashSlowAfter, () {
      if (mounted && _state == _Splash.loading) {
        setState(() => _state = _Splash.slow);
      }
    });
    // The router leaves the splash as soon as authProvider resolves, so resolve it last:
    // check the session and profile first, hold the branded screen, then navigate once.
    final hold = Future<void>.delayed(ref.read(splashHoldProvider));
    try {
      if (await ref.read(sessionStoreProvider).read() != null) {
        final complete = await ref
            .read(authRepositoryProvider)
            .profileComplete()
            .timeout(splashTimeout);
        if (!mounted) return;
        ref.read(profileCompleteProvider.notifier).set(complete);
      }
      await hold;
      _offerChoice(ref.read(authProvider.notifier).restore);
    } on UnauthorizedFailure {
      await hold;
      _offerChoice(ref.read(authProvider.notifier).signOut);
    } on Object {
      // Network, timeout, 5xx...: keep the session, let the user retry or sign in again.
      if (mounted) setState(() => _state = _Splash.failed);
    } finally {
      _slowTimer?.cancel();
      _running = false;
    }
  }

  void _offerChoice(Future<void> Function() enter) {
    if (!mounted) return;
    _enter = enter;
    if (!ref.read(splashChoiceProvider)) {
      unawaited(_proceedCustomer());
      return;
    }
    setState(() => _state = _Splash.choose);
  }

  Future<void> _proceedCustomer() async {
    if (_entering) return;
    _entering = true;
    try {
      await _enter?.call();
    } finally {
      _entering = false;
    }
  }

  /// The worker app is a separate application: open its configured link, never a made-up one.
  Future<void> _openWorkerApp() async {
    final url = ref.read(appConfigProvider).workerAppUrl;
    final uri = url.isEmpty ? null : Uri.tryParse(url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Object {
        // falls through to the message below
      }
    }
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).workerAppUnavailable),
        ),
      );
  }

  Future<void> _signInAgain() => ref.read(authProvider.notifier).signOut();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failed = _state == _Splash.failed;
    final version = ref.watch(appVersionProvider).value;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final Widget actions;
    if (failed) {
      actions = Column(
        children: [
          _FailedCard(onRetry: _boot, onSignInAgain: _signInAgain),
          AuthLink(
            key: const Key('splash_support_link'),
            label: l10n.contactSupport,
            icon: Icons.headset_mic_outlined,
            onTap: () => openSupport(context, ref),
          ),
        ],
      );
    } else if (_state == _Splash.choose) {
      actions = _EntryButtons(
        onCustomer: _proceedCustomer,
        onWorker: _openWorkerApp,
        clock: _now,
      );
    } else {
      actions = _Progress(slow: _state == _Splash.slow);
    }

    final content = LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
              child: Column(
                children: [
                  _Header(clock: _now, tagline: l10n.splashTagline),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ConstrainedBox(
                      // The failure card needs the room; the photo then just fills the screen.
                      // Short phones (about 640 dp) shrink the photo so Get Started stays on screen.
                      constraints: BoxConstraints(
                        minHeight: failed
                            ? 0
                            : (box.maxHeight < 700 ? 96 : 190),
                      ),
                      child: SizedBox(key: _heroKey, width: double.infinity),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Rise(
                    clock: _now,
                    start: _introAt + 550,
                    child: const _TrustRow(),
                  ),
                  const SizedBox(height: 6),
                  Rise(clock: _now, start: _introAt + 650, child: actions),
                  const SizedBox(height: 6),
                  if (version != null)
                    Text(
                      l10n.versionLabel(version),
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        color: AppColors.slate400,
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: _cream,
      body: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          return ValueListenableBuilder<double>(
            valueListenable: _now,
            child: SafeArea(child: content),
            builder: (context, t, child) {
              final tz = _zoomAt == null ? -1.0 : t - _zoomAt!;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(child: _Backdrop()),
                  _Decor(t: t, tz: tz),
                  if (_hero != null) ..._heroLayers(size, t, tz),
                  _Scrim(opacity: seg(tz, 350, 700, Curves.easeOut)),
                  child!,
                  if (_hero != null && _hero!.height >= _minHero)
                    ..._badges(size, t),
                  _BootCover(t: t),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Hero rectangle in body coordinates, refreshed after each layout.
  void _measure() {
    if (!mounted) return;
    final box = _heroKey.currentContext?.findRenderObject() as RenderBox?;
    final root = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || root == null) return;
    final r = box.localToGlobal(Offset.zero, ancestor: root) & box.size;
    if (r != _hero) setState(() => _hero = r);
  }

  /// Photo geometry: fixed in screen space, the arch only reveals more of it.
  ({double sc, double dw, double dh, double y}) _photo(Size s) {
    final sc = _photoZoom * math.max(s.width / _photoW, s.height / _photoH);
    final dh = _photoH * sc;
    return (sc: sc, dw: _photoW * sc, dh: dh, y: -(dh - s.height) / 2);
  }

  List<Widget> _heroLayers(Size size, double t, double tz) {
    final hero = _hero!;
    final arch = Rect.fromLTWH(
      hero.center.dx - 116,
      hero.top,
      232,
      hero.height,
    );
    final end = Rect.fromLTWH(-120, -120, size.width + 240, size.height + 240);
    final collapsed = hero.height < _minHero;
    final e = collapsed ? 1.0 : seg(tz, 0, 800, _expand);
    final o = Rect.lerp(arch, end, e)!;
    final rt = o.width / 2;
    final rb = _lerp(28, 60, e);
    final open = seg(t, _introAt + 150, 800, const Cubic(.65, 0, .2, 1));
    final inner = o.deflate(6);
    final clip = Rect.fromLTWH(
      inner.left + inner.width * (1 - open) / 2,
      inner.top,
      inner.width * open,
      inner.height,
    );
    final ph = _photo(size);
    final ringP = seg(tz, 0, 760, const Cubic(.3, 0, .2, 1));
    final glowP = seg(tz, 100, 1000, const Cubic(.3, 0, .2, 1));
    final cx = hero.center.dx;
    final cy = hero.center.dy;

    Widget ring(double d, double secs, bool reverse) => Positioned(
      left: cx - d / 2,
      top: cy - d / 2,
      width: d,
      height: d,
      child: Opacity(
        opacity: 1 - ringP,
        child: Transform.scale(
          scale: 1 + 0.7 * ringP,
          child: Transform.rotate(
            angle: (reverse ? -1 : 1) * 2 * math.pi * (t / 1000 / secs),
            child: const CustomPaint(painter: _DashedRing()),
          ),
        ),
      ),
    );

    return [
      if (glowP < 1 && !collapsed) ...[
        Positioned(
          left: cx - 130,
          top: hero.top + hero.height * 0.55 - 130,
          width: 260,
          height: 260,
          child: Opacity(
            opacity: 1 - glowP,
            child: Transform.scale(
              scale: 1 + 1.6 * glowP,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.orangeF59E0BA22,
                      AppColors.orangeF59E0BA0,
                    ],
                    stops: [0, 0.68],
                  ),
                ),
              ),
            ),
          ),
        ),
        ring(300, 50, false),
        ring(370, 70, true),
      ],
      Positioned.fromRect(
        rect: o,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(rt),
              topRight: Radius.circular(rt),
              bottomLeft: Radius.circular(rb),
              bottomRight: Radius.circular(rb),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.sky1B3354A26,
                blurRadius: 44,
                offset: Offset(0, 22),
              ),
            ],
          ),
        ),
      ),
      Positioned.fromRect(
        rect: clip,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(rt - 6),
            topRight: Radius.circular(rt - 6),
            bottomLeft: Radius.circular(rb - 6),
            bottomRight: Radius.circular(rb - 6),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -clip.left,
                top: ph.y - clip.top,
                width: ph.dw,
                height: ph.dh,
                child: Image.asset(
                  'assets/splash/photo.jpg',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _badges(Size size, double t) {
    final hero = _hero!;
    final ph = _photo(size);
    final face = Rect.fromLTWH(
      ph.sc * 215,
      ph.y + ph.sc * 735,
      ph.sc * 180,
      ph.sc * 190,
    );
    // Labels are wider than the 66 dp avatar; the right-hand ones are inset so they stay on screen.
    const m = 20.0, bw = 66.0, bh = 78.0, labelInset = 14.0;
    return [
      for (final b in _badgeData)
        () {
          final x = b.left ? hero.left + 4 : hero.right - 4 - bw - labelInset;
          var y = hero.top + hero.height * b.top;
          final hit =
              x < face.right + m &&
              x + bw > face.left - m &&
              y < face.bottom + m &&
              y + bh > face.top - m;
          if (hit) {
            final down = face.bottom + m - y;
            final up = y + bh - (face.top - m);
            y += down < up ? down : -up;
          }
          final p = seg(
            t,
            _introAt + b.delay,
            450,
            const Cubic(.34, 1.56, .64, 1),
          );
          final bobAt = _introAt + b.delay + 450;
          var dy = 14 * (1 - p);
          var scale = 0.4 + 0.6 * p;
          if (t >= bobAt) {
            final bp = ((t - bobAt) / 4000) % 1;
            dy = -6 * Curves.ease.transform(bp < 0.5 ? bp * 2 : 2 - bp * 2);
            scale = 1;
          }
          return Positioned(
            left: x,
            top: y,
            width: bw,
            child: Opacity(
              opacity: p.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(scale: scale, child: _Badge(b)),
              ),
            ),
          );
        }(),
    ];
  }
}

/// Below this the hero is too short for the arch and badges (failure card showing).
const _minHero = 120.0;
const _cream = AppColors.whiteFBF9F6;
const _photoW = 884.0;
const _photoH = 1779.0;
const _photoZoom = 1.054;
const _expand = Cubic(.72, 0, .16, 1);

/// The brand logo screen holds this long (ms), then fades while the splash builds beneath it.
const _introAt = 1400.0;
const _bootFade = 420.0;

/// The arch starts zooming this long after the splash appears.
const _zoomAt0 = _introAt + 1500;

double _lerp(double a, double b, double t) => a + (b - a) * t;

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surface, _cream, AppColors.grayF4EFE8],
        stops: [0, 0.6, 1],
      ),
    ),
  );
}

class _BadgeData {
  const _BadgeData(this.asset, this.label, this.top, this.left, this.delay);
  final String asset;
  final String label;
  final double top;
  final bool left;
  final double delay;
}

const _badgeData = [
  _BadgeData('assets/splash/badge_cleaning.jpg', 'Cleaning', 0.06, true, 450),
  _BadgeData('assets/splash/badge_driver.jpg', 'Driver', 0.25, false, 550),
  _BadgeData('assets/splash/badge_cook.jpg', 'Cook', 0.50, true, 650),
  _BadgeData('assets/splash/badge_elder.jpg', 'Elderly Care', 0.69, false, 750),
];

class _Badge extends StatelessWidget {
  const _Badge(this.b);
  final _BadgeData b;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.sky1B3354A30,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            b.asset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 16,
        child: OverflowBox(
          maxWidth: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.whiteA88xE0,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.sky1B3354A14,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                b.label,
                maxLines: 1,
                softWrap: false,
                style: AppText.body.copyWith(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDeep,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Dots, faint living-room photo and drifting colour blobs; fades out as the arch zooms.
class _Decor extends StatelessWidget {
  const _Decor({required this.t, required this.tz});
  final double t;
  final double tz;

  @override
  Widget build(BuildContext context) {
    final fade = 1 - seg(tz, 0, 520, Curves.easeOut);
    if (fade <= 0) return const SizedBox.shrink();
    Widget blob(
      Color c, {
      required double top,
      double? left,
      double? right,
      double delay = 0,
    }) {
      final ph = ((t / 1000 + delay) / 10) % 1;
      final k = Curves.ease.transform(ph < 0.5 ? ph * 2 : 2 - ph * 2);
      return Positioned(
        top: top,
        left: left,
        right: right,
        width: 420,
        height: 420,
        child: Transform.translate(
          offset: Offset(26 * k, 34 * k),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [c, c.withValues(alpha: 0)],
                stops: const [0.2, 1],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Opacity(
        opacity: fade,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 300,
              child: Opacity(
                opacity: 0.16,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.transparentBlack,
                      AppColors.blackA100xFF,
                    ],
                    stops: [0, 0.75],
                  ).createShader(r),
                  child: Image.asset(
                    'assets/splash/photo_faded.jpg',
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
            blob(AppColors.teal0F766EA22, top: -160, right: -200),
            blob(AppColors.orangeF59E0BA24, top: 270, left: -210, delay: -5),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fadeEnd = size.height * 0.7;
    final p = Paint();
    for (var y = 9.0; y < fadeEnd; y += 18) {
      p.color = const Color(
        0xFF1B3354,
      ).withValues(alpha: 0.09 * (1 - y / fadeEnd));
      for (var x = 9.0; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), 0.7, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}

class _DashedRing extends CustomPainter {
  const _DashedRing();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.teal0F766EA28;
    final circle = Path()..addOval(Offset.zero & size);
    for (final m in circle.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => false;
}

/// Cream fade at top and bottom so text stays readable over the full-screen photo.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    Widget band(double h, {required bool top}) => Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: const [
              AppColors.whiteFBF9F6A88,
              AppColors.whiteFBF9F6A62,
              AppColors.whiteFBF9F6A0,
            ],
            stops: [0, 120 / h, 1],
          ),
        ),
      ),
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Stack(children: [band(250, top: true), band(260, top: false)]),
        ),
      ),
    );
  }
}

/// The brand logo screen shown first, then faded (and nudged up in scale) away.
class _BootCover extends StatelessWidget {
  const _BootCover({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    if (t >= _introAt + _bootFade) return const SizedBox.shrink();
    final p = seg(t, _introAt, _bootFade, const Cubic(.4, 0, .2, 1));
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 1 - p,
          child: Transform.scale(
            scale: 1 + 0.06 * p,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surface, _cream, AppColors.grayF4EFE8],
                  stops: [0, 0.6, 1],
                ),
              ),
              child: SizedBox.expand(
                child: Image(
                  image: AssetImage('assets/splash/boot.jpg'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo with its breathing halo, caption and heading.
class _Header extends StatelessWidget {
  const _Header({required this.clock, required this.tagline});
  final ValueListenable<double> clock;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const accent = 'your home';
    final i = tagline.indexOf(accent);
    const base = TextStyle(
      fontFamily: AppFonts.heading,
      fontSize: 26,
      height: 1.15,
      fontWeight: FontWeight.w700,
      color: AppColors.navyDeep,
    );
    final heading = i < 0
        ? TextSpan(text: tagline)
        : TextSpan(
            children: [
              TextSpan(text: tagline.substring(0, i)),
              const TextSpan(
                text: accent,
                style: TextStyle(
                  color: AppColors.teal,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(text: tagline.substring(i + accent.length)),
            ],
          );
    return Column(
      children: [
        Semantics(
          label: l10n.appName,
          child: ExcludeSemantics(
            child: ValueListenableBuilder<double>(
              valueListenable: clock,
              builder: (context, t, _) {
                final p = seg(t, _introAt, 550, riseCurve);
                final hp = ((t / 1000) / 2.6) % 1;
                final h = Curves.easeInOut.transform(
                  hp < 0.5 ? hp * 2 : 2 - hp * 2,
                );
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.5 + 0.5 * h,
                      child: Transform.scale(
                        scale: 1 + 0.16 * h,
                        child: const SizedBox(
                          width: 130,
                          height: 130,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.teal0F766EA30,
                                  AppColors.teal0F766EA0,
                                ],
                                stops: [0, 0.7],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: p,
                      child: Transform.scale(
                        scale: 0.86 + 0.14 * p,
                        child: Image.asset(
                          'assets/splash/logo.webp',
                          width: 170,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Rise(
          clock: clock,
          start: _introAt + 100,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.brandCaption,
              style: AppText.body.copyWith(
                fontSize: 11,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
                color: AppColors.slate600,
              ),
            ),
          ),
        ),
        Rise(
          clock: clock,
          start: _introAt + 200,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text.rich(heading, textAlign: TextAlign.center, style: base),
          ),
        ),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget item(IconData icon, String label, {bool first = false}) => Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(left: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.teal, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          item(
            Icons.verified_user_outlined,
            l10n.trustVerifiedWorkers,
            first: true,
          ),
          item(Icons.credit_card_outlined, l10n.trustSecurePayments),
          item(Icons.headset_mic_outlined, l10n.trustHelpSupport),
        ],
      ),
    );
  }
}

/// Two full-width pill buttons: filled customer entry (with a light sheen) and outlined worker.
class _EntryButtons extends StatelessWidget {
  const _EntryButtons({
    required this.onCustomer,
    required this.onWorker,
    required this.clock,
  });
  final VoidCallback onCustomer;
  final VoidCallback onWorker;
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget pill({
      required Key key,
      required String label,
      required IconData icon,
      required VoidCallback onTap,
      required bool filled,
    }) {
      final fg = filled ? AppColors.surface : AppColors.navyDeep;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: filled ? AppColors.navyDeep : AppColors.whiteA90xE6,
          border: filled
              ? null
              : Border.all(color: AppColors.navyDeep, width: 2),
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: AppColors.sky1B3354A32,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: key,
            onTap: onTap,
            child: SizedBox(
              height: filled ? 56 : 52,
              child: Stack(
                children: [
                  if (filled)
                    Positioned.fill(
                      child: ValueListenableBuilder<double>(
                        valueListenable: clock,
                        builder: (context, t, _) => LayoutBuilder(
                          builder: (context, box) {
                            final sw = box.maxWidth * 0.4;
                            final p = Curves.easeInOut.transform(
                              (t / 3200) % 1,
                            );
                            return Stack(
                              children: [
                                Positioned(
                                  left: sw * _lerp(-1.2, 2.6, p),
                                  top: 0,
                                  bottom: 0,
                                  width: sw,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.whiteClear,
                                          AppColors.whiteA35x59,
                                          AppColors.whiteClear,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Icon(icon, color: fg, size: 22),
                        ),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppText.body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: fg,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill(
          key: const Key('splash_customer_btn'),
          label: l10n.getStarted,
          icon: Icons.person_outline_rounded,
          onTap: onCustomer,
          filled: true,
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          key: const Key('splash_worker_btn'),
          onPressed: onWorker,
          icon: const Icon(Icons.work_outline_rounded, size: 14),
          label: Text(l10n.workerAppShort),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navyDeep,
            minimumSize: const Size(48, 40),
            textStyle: AppText.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.slow});
  final bool slow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: slow ? l10n.splashSlow : l10n.splashLoading,
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              width: 160,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: slow ? 0.8 : 0.35),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    key: const Key('splash_progress'),
                    value: v,
                    minHeight: 4,
                    color: AppColors.teal,
                    backgroundColor: AppColors.hairline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              slow ? l10n.splashSlow : l10n.splashLoading,
              textAlign: TextAlign.center,
              style: AppText.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedCard extends StatelessWidget {
  const _FailedCard({required this.onRetry, required this.onSignInAgain});
  final VoidCallback onRetry;
  final VoidCallback onSignInAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SnCard(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.warnBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warnIcon,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.splashFailedTitle,
              textAlign: TextAlign.center,
              style: AppText.screenTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.splashFailedBody,
              textAlign: TextAlign.center,
              style: AppText.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            SnButton(
              key: const Key('splash_retry_btn'),
              label: l10n.tryAgain,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: const Key('splash_login_btn'),
              onPressed: onSignInAgain,
              child: Text(l10n.signInAgain),
            ),
          ],
        ),
      ),
    );
  }
}
