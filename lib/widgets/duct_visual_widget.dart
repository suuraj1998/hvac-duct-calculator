import 'package:flutter/material.dart';
import '../models/hvac_models.dart';

class DuctVisualWidget extends StatelessWidget {
  final CalculationResult result;

  const DuctVisualWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF13171D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A323D)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE 2D DUCT CROSS-SECTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.shape == DuctShape.round ? 'Circular' : 'Rectangular',
                  style: const TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _DuctPainter(result: result),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuctPainter extends CustomPainter {
  final CalculationResult result;

  _DuctPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final linePaint = Paint()
      ..color = result.shape == DuctShape.round
          ? const Color(0xFF06B6D4)
          : const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = (result.shape == DuctShape.round
              ? const Color(0xFF06B6D4)
              : const Color(0xFF10B981))
          .withAlpha(38)
      ..style = PaintingStyle.fill;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    if (result.shape == DuctShape.round) {
      final double maxRadius = (size.height / 2) - 20;
      final double radius = maxRadius.clamp(20.0, maxRadius);

      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, linePaint);

      final axisPaint = Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy),
        axisPaint,
      );

      final labelText = result.standard == MeasurementStandard.imperial
          ? 'Ø ${result.standardRoundDiameterIn}"'
          : 'Ø ${result.standardRoundDiameterMm.round()} mm';

      final tp = TextPainter(
        text: TextSpan(text: labelText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - 2));
    } else {
      final double wVal = result.standard == MeasurementStandard.imperial
          ? (result.rectWidthIn > 0 ? result.rectWidthIn : 12.0)
          : (result.rectWidthMm > 0 ? result.rectWidthMm : 300.0);
      final double hVal = result.standard == MeasurementStandard.imperial
          ? (result.rectHeightIn > 0 ? result.rectHeightIn : 12.0)
          : (result.rectHeightMm > 0 ? result.rectHeightMm : 300.0);

      final double aspect = wVal / hVal;
      double drawW = size.width - 80;
      double drawH = drawW / aspect;

      if (drawH > size.height - 40) {
        drawH = size.height - 40;
        drawW = drawH * aspect;
      }

      drawW = drawW.clamp(30.0, size.width - 60);
      drawH = drawH.clamp(20.0, size.height - 40);

      final rect = Rect.fromCenter(center: center, width: drawW, height: drawH);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, linePaint);

      final wText = result.standard == MeasurementStandard.imperial
          ? '${result.rectWidthIn}" W'
          : '${result.rectWidthMm.round()} mm W';
      final hText = result.standard == MeasurementStandard.imperial
          ? '${result.rectHeightIn}" H'
          : '${result.rectHeightMm.round()} mm H';

      final tpW = TextPainter(
        text: TextSpan(text: wText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final tpH = TextPainter(
        text: TextSpan(text: hText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tpW.paint(canvas, Offset(center.dx - tpW.width / 2, rect.top - tpW.height - 4));
      tpH.paint(canvas, Offset(rect.right + 6, center.dy - tpH.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DuctPainter oldDelegate) =>
      oldDelegate.result != result;
}
