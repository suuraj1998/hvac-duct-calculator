import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_duct_calculator/models/hvac_models.dart';
import 'package:hvac_duct_calculator/services/calculator_service.dart';

void main() {
  group('CalculatorService Unit Tests', () {
    final calc = CalculatorService.instance;

    test('Huebscher equivalent diameter for 12x8 inch duct is accurate', () {
      final de = calc.calculateHuebscherEquivalent(12, 8);
      // Theoretical Huebscher De for 12x8: approx 10.68 inches
      expect(de, greaterThan(10.0));
      expect(de, lessThan(11.5));
    });

    test('Inverting Huebscher width solver recovers exact width', () {
      const double sideA = 12.0;
      final double targetDe = calc.calculateHuebscherEquivalent(sideA, 16.0);
      final double solvedWidth = calc.solveHuebscherWidth(targetDe, sideA);
      expect(solvedWidth, closeTo(16.0, 0.05));
    });

    test('Imperial duct calculation produces correct velocity and friction', () {
      final res = calc.calculate(
        standard: MeasurementStandard.imperial,
        shape: DuctShape.rectangular,
        airflowInput: 1200,
        metricFlowUnit: MetricFlowUnit.litersPerSecond,
        velocityInput: 900,
        rectSideAInput: 12,
      );

      expect(res.airflowCfm, equals(1200.0));
      expect(res.velocityFpm, equals(900.0));
      expect(res.areaSqFt, closeTo(1.33, 0.05));
      expect(res.rectHeightIn, equals(12.0));
      expect(res.rectWidthIn, greaterThan(12.0));
      expect(res.frictionLossPer100FtInWg, greaterThan(0.0));
      expect(res.velocityPressureInWg, greaterThan(0.0));
    });

    test('Metric duct calculation handles L/s and converts m³/h properly', () {
      final res = calc.calculate(
        standard: MeasurementStandard.metric,
        shape: DuctShape.rectangular,
        airflowInput: 500, // 500 L/s
        metricFlowUnit: MetricFlowUnit.litersPerSecond,
        velocityInput: 4.5, // 4.5 m/s
        rectSideAInput: 300, // 300 mm height
      );

      expect(res.airflowLs, equals(500.0));
      expect(res.airflowM3h, equals(1800.0)); // 500 * 3.6
      expect(res.velocityMs, equals(4.5));
      expect(res.rectHeightMm, equals(300.0));
      expect(res.rectWidthMm, greaterThan(300.0));
      expect(res.frictionLossPerMPa, greaterThan(0.0));
    });

    test('Round duct snapping snaps to standard US and EN sizes', () {
      final res = calc.calculate(
        standard: MeasurementStandard.imperial,
        shape: DuctShape.round,
        airflowInput: 1000,
        metricFlowUnit: MetricFlowUnit.litersPerSecond,
        velocityInput: 800,
        rectSideAInput: 0,
      );

      expect(res.standardRoundDiameterIn, greaterThan(0));
      expect(res.standardRoundDiameterMm, greaterThan(0));
      expect(CalculatorService.usStandardSizesIn, contains(res.standardRoundDiameterIn));
      expect(CalculatorService.en1506StandardSizesMm, contains(res.standardRoundDiameterMm));
    });

    test('High velocity triggers velocity warning', () {
      final res = calc.calculate(
        standard: MeasurementStandard.imperial,
        shape: DuctShape.rectangular,
        airflowInput: 5000,
        metricFlowUnit: MetricFlowUnit.litersPerSecond,
        velocityInput: 2500, // Exceeds 2000 fpm
        rectSideAInput: 12,
      );

      expect(res.velocityWarning, isNotNull);
      expect(res.velocityWarning, contains('High Velocity'));
    });

    test('High aspect ratio triggers aspect ratio warning', () {
      final res = calc.calculate(
        standard: MeasurementStandard.imperial,
        shape: DuctShape.rectangular,
        airflowInput: 5000,
        metricFlowUnit: MetricFlowUnit.litersPerSecond,
        velocityInput: 400, // Very low velocity forces huge width
        rectSideAInput: 6,   // Tiny height vs huge width
      );

      expect(res.aspectRatioWarning, isNotNull);
    });
  });
}
