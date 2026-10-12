import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';

Future<T?> showSnBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: builder(ctx),
    ),
  );
}
