import 'package:flutter/material.dart';
import 'package:sevanest_customer/app/theme/tokens.dart';
import 'package:sevanest_customer/app/theme/typography.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_parts.dart';

/// One cell of [ChoicesTicket]: a circular avatar, small caption, bold name and a pencil.
class TicketCell {
  const TicketCell({
    required this.caption,
    required this.name,
    required this.icon,
    required this.semanticLabel,
    required this.onChange,
    this.photo,
    this.changeKey,
  });
  final String caption;
  final String name;
  final IconData icon;
  final String? photo;
  final String semanticLabel;
  final VoidCallback onChange;
  final Key? changeKey;
}

/// "Your choices so far" ticket (design: Find a Worker 3): one frosted card, a dashed tear line
/// between cells, punched notches top and bottom, and a sheen sweeping across.
class ChoicesTicket extends StatelessWidget {
  const ChoicesTicket({required this.cells, super.key});
  final List<TicketCell> cells;

  @override
  Widget build(BuildContext context) {
    final clock = DiscoverClock.of(context);
    final single = cells.length == 1;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DiscoverGlass(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<double>(
                    valueListenable: clock,
                    builder: (_, t, _) => LayoutBuilder(
                      builder: (_, box) {
                        final w = box.maxWidth * 0.3;
                        final k = Curves.easeInOut.transform((t / 4500) % 1);
                        return Stack(
                          children: [
                            Positioned(
                              left: w * (-1.2 + 3.8 * k),
                              top: 0,
                              bottom: 0,
                              width: w,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.whiteClear,
                                      AppColors.whiteA60x99,
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, c) in cells.indexed) ...[
                        if (i > 0) const _TearLine(),
                        Expanded(
                          child: _Cell(cell: c, single: single),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const _Notch(top: -9),
        const _Notch(bottom: -9),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({this.top, this.bottom});
  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    bottom: bottom,
    left: 0,
    right: 0,
    child: const IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grayF7F4EE,
          ),
          child: SizedBox(width: 18, height: 18),
        ),
      ),
    ),
  );
}

class _TearLine extends StatelessWidget {
  const _TearLine({this.horizontal = false});
  final bool horizontal;

  @override
  Widget build(BuildContext context) => horizontal
      ? CustomPaint(
          size: const Size(double.infinity, 2),
          painter: _DashPainter(horizontal: true),
        )
      : CustomPaint(size: const Size(2, 0), painter: _DashPainter());
}

class _DashPainter extends CustomPainter {
  _DashPainter({this.horizontal = false});
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = dsNavy.withValues(alpha: 0.2)
      ..strokeWidth = 2;
    if (horizontal) {
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, 1), Offset(x + 4, 1), p);
      }
      return;
    }
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 4), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell, required this.single, this.grid = false});
  final TicketCell cell;
  final bool single;

  /// Compact side-by-side cell of [ChoicesGrid].
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final row = single || grid;
    final size = grid
        ? 36.0
        : single
        ? 44.0
        : 38.0;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.pillActive,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: dsNavy.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: cell.photo == null
          ? Icon(cell.icon, size: 20, color: AppColors.teal)
          : Image.asset(
              cell.photo!,
              fit: BoxFit.cover,
              cacheWidth: 140,
              errorBuilder: (_, _, _) =>
                  Icon(cell.icon, size: 20, color: AppColors.teal),
            ),
    );
    final caption = Text(
      cell.caption,
      style: AppText.body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.2,
        color: dsMuted,
      ),
    );
    final name = Text(
      cell.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.body.copyWith(
        fontSize: grid
            ? 14
            : single
            ? 16
            : 14.5,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: dsNavy,
      ),
    );
    final pencil = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal.withValues(alpha: 0.12),
      ),
      child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.teal),
    );
    return Semantics(
      button: true,
      label: cell.semanticLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: cell.changeKey,
          borderRadius: BorderRadius.circular(20),
          onTap: cell.onChange,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Stack(
              children: [
                Padding(
                  padding: grid
                      ? const EdgeInsets.fromLTRB(10, 8, 36, 8)
                      : single
                      ? const EdgeInsets.fromLTRB(10, 6, 48, 6)
                      : const EdgeInsets.fromLTRB(6, 6, 6, 4),
                  child: row
                      ? Row(
                          children: [
                            avatar,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [caption, name],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            avatar,
                            const SizedBox(height: 3),
                            caption,
                            name,
                          ],
                        ),
                ),
                Positioned(
                  top: row ? 0 : 4,
                  bottom: row ? 0 : null,
                  right: grid
                      ? 8
                      : single
                      ? 12
                      : 6,
                  child: row ? Center(child: pencil) : pencil,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Your choices so far" for steps 5-6 (design: Find a Worker 5-6): a two-column ticket, dashed
/// tear lines between cells, punched notches on the sides and top; an odd last cell spans both.
class ChoicesGrid extends StatelessWidget {
  const ChoicesGrid({required this.cells, super.key});
  final List<TicketCell> cells;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      if (i > 0) rows.add(const _TearLine(horizontal: true));
      final pair = cells.skip(i).take(2).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Cell(cell: pair[0], single: false, grid: true)),
              if (pair.length == 2) ...[
                const _TearLine(),
                Expanded(
                  child: _Cell(cell: pair[1], single: false, grid: true),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DiscoverGlass(
          child: Stack(
            children: [
              const DiscoverSheen(widthFactor: 0.3, periodMs: 4500, alpha: 0.6),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Column(children: rows),
              ),
            ],
          ),
        ),
        const _Notch(top: -9),
        if (cells.length.isEven) const _Notch(bottom: -9),
        const _SideNotch(left: true),
        const _SideNotch(left: false),
      ],
    );
  }
}

class _SideNotch extends StatelessWidget {
  const _SideNotch({required this.left});
  final bool left;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left ? -9 : null,
    right: left ? null : -9,
    top: 0,
    bottom: 0,
    child: const IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grayF7F4EE,
          ),
          child: SizedBox(width: 18, height: 18),
        ),
      ),
    ),
  );
}
