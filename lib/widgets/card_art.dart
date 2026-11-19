import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A ledger card drawn in code: brand gradient body, folded facets, a chip,
/// a ₹ mark and a light sheen that sweeps once when shown. Sharp on every
/// screen and weighs nothing.
class LedgerCardArt extends StatefulWidget {
  const LedgerCardArt({super.key, this.width = 300, required this.txnCount});
  final double width;
  final int txnCount;

  static const aspectRatio = 1.586; // ID-1 card

  @override
  State<LedgerCardArt> createState() => _LedgerCardArtState();
}

class _LedgerCardArtState extends State<LedgerCardArt> with SingleTickerProviderStateMixin {
  late final _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final _curve = CurvedAnimation(parent: _sheen, curve: Motion.signature);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_sheen.isAnimating && _sheen.value == 0) {
      Future.delayed(Motion.sheet, () {
        if (mounted) _sheen.forward();
      });
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    return Semantics(
      label: 'Kharcha ledger card, ${widget.txnCount} transactions stored on this phone',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.055),
          boxShadow: [
            BoxShadow(color: Brand.mid.withAlpha(context.isDark ? 90 : 70), blurRadius: w * 0.12, offset: Offset(0, w * 0.06)),
          ],
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size(w, w / LedgerCardArt.aspectRatio),
            painter: _CardPainter(_curve, widget.txnCount),
          ),
        ),
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  _CardPainter(this.sheen, this.count) : super(repaint: sheen);
  final Animation<double> sheen;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final card = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.055));
    canvas.save();
    canvas.clipRRect(card);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.heroTop, Brand.heroMid, Brand.blue, Brand.violet],
          stops: [0, 0.4, 0.8, 1],
        ).createShader(rect),
    );

    final facet = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withAlpha(36), Colors.white.withAlpha(6)],
      ).createShader(rect);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.58, h)
          ..lineTo(w * 0.84, 0)
          ..lineTo(w * 0.96, 0)
          ..lineTo(w * 0.7, h)
          ..close(),
        facet);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.78, h)
          ..lineTo(w, h * 0.2)
          ..lineTo(w, h * 0.55)
          ..lineTo(w * 0.9, h)
          ..close(),
        facet);

    // Chip.
    final chip = Rect.fromLTWH(w * 0.08, h * 0.38, w * 0.13, h * 0.19);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chip, Radius.circular(w * 0.018)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xfff3e3b0), Color(0xffc9a85a), Color(0xffeed9a0)]).createShader(chip),
    );
    final lines = Paint()
      ..color = const Color(0xff8a6d2c)
      ..strokeWidth = math.max(0.6, w * 0.003);
    for (final f in [0.33, 0.66]) {
      canvas.drawLine(Offset(chip.left, chip.top + chip.height * f), Offset(chip.right, chip.top + chip.height * f), lines);
    }
    canvas.drawLine(Offset(chip.center.dx, chip.top), Offset(chip.center.dx, chip.bottom), lines);

    _text(canvas, 'KHARCHA', Offset(w * 0.08, h * 0.11), w * 0.05, FontWeight.w800, 2.4, 235);
    _text(canvas, '₹', Offset(w * 0.84, h * 0.07), w * 0.09, FontWeight.w800, 0, 220);
    _text(canvas, '$count transactions', Offset(w * 0.08, h * 0.68), w * 0.045, FontWeight.w600, 0.6, 215);
    _text(canvas, 'STORED ON THIS PHONE', Offset(w * 0.08, h * 0.82), w * 0.032, FontWeight.w600, 1.6, 140);

    // Light sweep.
    final x = -0.6 + 2.2 * sheen.value;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(x * 2 - 1.6, -1),
          end: Alignment(x * 2 - 0.4, 1),
          colors: [Colors.white.withAlpha(0), Colors.white.withAlpha(46), Colors.white.withAlpha(0)],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.drawRRect(
      card.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withAlpha(80), Colors.white.withAlpha(10)],
        ).createShader(rect),
    );
  }

  void _text(Canvas canvas, String text, Offset at, double size, FontWeight weight, double spacing, int alpha) {
    (TextPainter(
      text: TextSpan(
          text: text, style: TextStyle(fontSize: size, fontWeight: weight, letterSpacing: spacing, color: Colors.white.withAlpha(alpha))),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, at);
  }

  @override
  bool shouldRepaint(_CardPainter old) => old.count != count;
}
