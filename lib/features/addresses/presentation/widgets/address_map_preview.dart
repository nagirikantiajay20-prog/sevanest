import 'package:flutter/material.dart';

/// Stylised street map from the add-address design (318 x 130 artwork, scaled to cover): blocks,
/// white roads, a dashed amber route, a pulsing ring and a navy pin that drops in.
class AddressMapPainter extends CustomPainter {
  const AddressMapPainter({required this.drop, required this.ring});

  /// Pin drop progress, 0 (above, hidden) .. 1 (landed); may overshoot slightly.
  final double drop;

  /// Ring pulse, 0 (hidden) .. 1.
  final double ring;

  static const _w = 318.0;
  static const _h = 130.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _w > size.height / _h
        ? size.width / _w
        : size.height / _h;
    canvas
      ..save()
      ..translate((size.width - _w * scale) / 2, (size.height - _h * scale) / 2)
      ..scale(scale);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _w, _h),
      Paint()..color = const Color(0xFFEAF4F1),
    );
    void block(double x, double y, double w, double h, Color c) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            const Radius.circular(8),
          ),
          Paint()..color = c,
        );
    const sand = Color(0xFFF7F2E8);
    for (final b in const [
      [10.0, 12.0, 70.0, 38.0],
      [96.0, 12.0, 64.0, 38.0],
      [236.0, 12.0, 72.0, 38.0],
      [96.0, 74.0, 64.0, 44.0],
      [196.0, 74.0, 40.0, 44.0],
      [252.0, 74.0, 56.0, 44.0],
    ]) {
      block(b[0], b[1], b[2], b[3], sand);
    }
    block(10, 74, 70, 44, const Color(0xFFCDEBD6));

    Paint road(double w) => Paint()
      ..color = Colors.white
      ..strokeWidth = w
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(const Offset(0, 62), const Offset(_w, 62), road(11))
      ..drawLine(const Offset(88, 0), const Offset(88, _h), road(9))
      ..drawLine(const Offset(180, 0), const Offset(180, _h), road(9))
      ..drawLine(const Offset(244, 0), const Offset(244, _h), road(7));
    final dash = Paint()
      ..color = const Color(0xB3F59E0B)
      ..strokeWidth = 2;
    for (var x = 0.0; x < _w; x += 14) {
      canvas.drawLine(Offset(x, 62), Offset(x + 6, 62), dash);
    }

    const pin = Offset(180, 62);
    if (ring > 0) {
      canvas.drawCircle(
        pin,
        14 * (0.4 + 2.0 * ring),
        Paint()
          ..color = const Color(0xFF0F766E).withValues(alpha: 0.8 * (1 - ring))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (drop > 0) {
      canvas
        ..save()
        ..translate(0, -70 * (1 - drop));
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(180, 66), width: 18, height: 6),
        Paint()..color = const Color(0x400F2340),
      );
      final body = Path()
        ..moveTo(180, 64)
        ..cubicTo(171, 53, 166, 47, 166, 40)
        ..arcToPoint(const Offset(194, 40), radius: const Radius.circular(14))
        ..cubicTo(194, 47, 189, 53, 180, 64)
        ..close();
      canvas
        ..drawPath(body, Paint()..color = const Color(0xFF1B3354))
        ..drawCircle(const Offset(180, 40), 5.5, Paint()..color = Colors.white)
        ..restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AddressMapPainter old) =>
      old.drop != drop || old.ring != ring;
}
