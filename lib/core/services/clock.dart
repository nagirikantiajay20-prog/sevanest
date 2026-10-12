import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now", injectable so date rules (start-date window, "Tomorrow" shortcuts) are testable.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
