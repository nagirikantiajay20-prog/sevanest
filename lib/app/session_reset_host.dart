import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Called by logout: drops every provider and cache so the next user sees none of the previous
/// user's data. A no-op outside [SessionResetHost].
final resetAppProvider = Provider<void Function()>((_) => () {});

/// Root [ProviderScope] that is rebuilt from scratch on [resetAppProvider]. Cheaper and safer
/// than invalidating each provider by hand (a missed one would leak the last user's data).
class SessionResetHost extends StatefulWidget {
  const SessionResetHost({
    required this.overrides,
    required this.child,
    super.key,
  });

  final List<Override> overrides;
  final Widget child;

  @override
  State<SessionResetHost> createState() => _SessionResetHostState();
}

class _SessionResetHostState extends State<SessionResetHost> {
  int _epoch = 0;

  void _reset() {
    if (mounted) setState(() => _epoch++);
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey(_epoch),
    // Failures surface as error states with a user-driven Retry; no hidden auto-retries (AGENTS §65).
    retry: (_, _) => null,
    overrides: [
      ...widget.overrides,
      resetAppProvider.overrideWithValue(_reset),
    ],
    child: widget.child,
  );
}
