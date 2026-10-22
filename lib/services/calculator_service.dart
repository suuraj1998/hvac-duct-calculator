import 'dart:math' as math;
import '../models/hvac_models.dart';

class CalculatorService {
  CalculatorService._();
  static final CalculatorService instance = CalculatorService._();

  // European EN 1506 standard circular duct diameters in mm
  static const List<double> en1506StandardSizesMm = [
    63, 80, 100, 125, 150, 160, 180, 200, 224, 250, 280, 315, 355, 400, 450,
    500, 560, 630, 710, 800, 900, 1000, 1120, 1250
  ];

  // US ASHRAE standard circular duct diameters in inches
  static const List<double> usStandardSizesIn = [
    4, 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34,
    36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60
  ];

  /// Huebscher's Equation for equivalent circular diameter of rectangular duct
  /// Formula: De = 1.30 * (a * b)^0.625 / (a + b)^0.25
  /// Reference: ASHRAE Handbook - Fundamentals (Duct Design)
  double calculateHuebscherEquivalent(double a, double b) {
    if (a <= 0 || b <= 0) return 0.0;
    final double numerator = 1.30 * math.pow(a * b, 0.625);
    final double denominator = math.pow(a + b, 0.25).toDouble();
    return numerator / denominator;
  }

  /// Inverts Huebscher's equation to find rectangular side B given De and side A.
  /// Uses binary search for high numerical precision.
  double solveHuebscherWidth(double targetDe, double sideA) {
    if (targetDe <= 0 || sideA <= 0) return 0.0;
    double low = 0.1;
    double high = math.max(targetDe * 10, 5000);

    for (int i = 0; i < 40; i++) {
      final double mid = (low + high) / 2;
      final double currentDe = calculateHuebscherEquivalent(sideA, mid);
      if ((currentDe - targetDe).abs() < 0.001) {
        return mid;
      }
      if (currentDe < targetDe) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  /// Calculates round diameter by Equal Friction Method:
  /// D = [0.109136 * (CFM^1.9) / DeltaP]^(1 / 5.02)
  double calculateDiameterFromTargetFriction(double cfm, double targetInWgPer100Ft) {
    if (cfm <= 0 || targetInWgPer100Ft <= 0) return 0.0;
    final inside = (0.109136 * math.pow(cfm, 1.9)) / targetInWgPer100Ft;
    return math.pow(inside, 1 / 5.02).toDouble();
  }

  /// Snaps exact calculated diameter to nearest certified industry standard size
  double snapToStandardSize(double exact, List<double> standards) {
    if (exact <= 0) return standards.first;
    double closest = standards.first;
    double minDiff = double.infinity;
    for (final double s in standards) {
      final double diff = (s - exact).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }
    return closest;
  }

  /// Calculates Friction Loss rate in both in. wg/100ft and Pa/m
  /// ASHRAE galvanized steel formula: DeltaP_100ft = 0.109136 * (CFM^1.9) / (D^5.02)
  Map<String, double> calculateFrictionLoss(double cfm, double diameterInches) {
    if (cfm <= 0 || diameterInches <= 0) {
      return {'inWgPer100Ft': 0.0, 'paPerM': 0.0};
    }
    final double inWgPer100Ft =
        0.109136 * (math.pow(cfm, 1.9) / math.pow(diameterInches, 5.02));
    final double paPerM = inWgPer100Ft * 8.1722;
    return {
      'inWgPer100Ft': double.parse(inWgPer100Ft.toStringAsFixed(3)),
      'paPerM': double.parse(paPerM.toStringAsFixed(2)),
    };
  }

  /// Calculates Velocity Pressure:
  /// Imperial: Pv = (V / 4005)^2 in. wg
  /// Metric: Pv = 0.5 * rho * V^2 Pa (rho = 1.204 kg/m³)
  Map<String, double> calculateVelocityPressure(double fpm, double ms) {
    final double inWg = math.pow(fpm / 4005, 2).toDouble();
    final double pa = 0.5 * 1.204 * math.pow(ms, 2);
    return {
      'inWg': double.parse(inWg.toStringAsFixed(4)),
      'pa': double.parse(pa.toStringAsFixed(1)),
    };
  }

  /// Evaluates recommended sheet metal gauge according to SMACNA and DW144
  Map<String, String> getRecommendedGauge(double maxDimInches, double maxDimMm) {
    String smacna;
    if (maxDimInches <= 12) {
      smacna = '26 Ga (0.0217")';
    } else if (maxDimInches <= 30) {
      smacna = '24 Ga (0.0276")';
    } else if (maxDimInches <= 54) {
      smacna = '22 Ga (0.0336")';
    } else if (maxDimInches <= 84) {
      smacna = '20 Ga (0.0396")';
    } else {
      smacna = '18 Ga (0.0516")';
    }

    String dw144;
    if (maxDimMm <= 300) {
      dw144 = '0.6 mm (Class A/B)';
    } else if (maxDimMm <= 800) {
      dw144 = '0.8 mm (Class A/B)';
    } else if (maxDimMm <= 1250) {
      dw144 = '1.0 mm (Class A/B/C)';
    } else {
      dw144 = '1.2 mm (Class C/D)';
    }

    return {'smacna': smacna, 'dw144': dw144};
  }

  CalculationResult calculate({
    required MeasurementStandard standard,
    required DuctShape shape,
    required double airflowInput,
    required MetricFlowUnit metricFlowUnit,
    required double velocityInput,
    required double rectSideAInput,
  }) {
    double cfm = 0.0;
    double ls = 0.0;
    double m3h = 0.0;
    double fpm = 0.0;
    double ms = 0.0;

    if (standard == MeasurementStandard.imperial) {
      cfm = airflowInput > 0 ? airflowInput : 0.0;
      ls = cfm * 0.471947;
      m3h = cfm * 1.69901;
      fpm = velocityInput > 0 ? velocityInput : 0.0;
      ms = fpm * 0.00508;
    } else {
      if (metricFlowUnit == MetricFlowUnit.litersPerSecond) {
        ls = airflowInput > 0 ? airflowInput : 0.0;
        m3h = ls * 3.6;
        cfm = ls / 0.471947;
      } else {
        m3h = airflowInput > 0 ? airflowInput : 0.0;
        ls = m3h / 3.6;
        cfm = m3h / 1.69901;
      }
      ms = velocityInput > 0 ? velocityInput : 0.0;
      fpm = ms * 196.85;
    }

    double areaSqFt = 0.0;
    double areaSqIn = 0.0;
    double areaSqM = 0.0;

    if (cfm > 0 && fpm > 0) {
      areaSqFt = cfm / fpm;
      areaSqIn = areaSqFt * 144;
      areaSqM = areaSqFt * 0.092903;
    }

    double exactRoundDiameterIn = 0.0;
    double exactRoundDiameterMm = 0.0;
    if (areaSqIn > 0) {
      exactRoundDiameterIn = 2 * math.sqrt(areaSqIn / math.pi);
      exactRoundDiameterMm = exactRoundDiameterIn * 25.4;
    }

    final double standardRoundDiameterIn =
        snapToStandardSize(exactRoundDiameterIn, usStandardSizesIn);
    final double standardRoundDiameterMm =
        snapToStandardSize(exactRoundDiameterMm, en1506StandardSizesMm);

    double rectHeightIn = 0.0;
    double rectHeightMm = 0.0;
    double rectWidthIn = 0.0;
    double rectWidthMm = 0.0;
    double huebscherEqIn = 0.0;
    double huebscherEqMm = 0.0;
    double aspectRatio = 1.0;

    if (standard == MeasurementStandard.imperial) {
      rectHeightIn = rectSideAInput > 0 ? rectSideAInput : 12.0;
      rectHeightMm = rectHeightIn * 25.4;
      final double solvedWidth =
          solveHuebscherWidth(exactRoundDiameterIn, rectHeightIn);
      rectWidthIn = double.parse(solvedWidth.toStringAsFixed(1));
      rectWidthMm = double.parse((rectWidthIn * 25.4).toStringAsFixed(0));
    } else {
      rectHeightMm = rectSideAInput > 0 ? rectSideAInput : 300.0;
      rectHeightIn = rectHeightMm / 25.4;
      final double solvedWidth =
          solveHuebscherWidth(exactRoundDiameterMm, rectHeightMm);
      rectWidthMm = double.parse(solvedWidth.toStringAsFixed(0));
      rectWidthIn = double.parse((rectWidthMm / 25.4).toStringAsFixed(1));
    }

    if (rectHeightIn > 0 && rectWidthIn > 0) {
      huebscherEqIn = calculateHuebscherEquivalent(rectHeightIn, rectWidthIn);
      huebscherEqMm = calculateHuebscherEquivalent(rectHeightMm, rectWidthMm);
      aspectRatio = math.max(rectWidthIn / rectHeightIn, rectHeightIn / rectWidthIn);
    }

    final double effectiveDuctDiameterIn =
        shape == DuctShape.round ? exactRoundDiameterIn : huebscherEqIn;

    final friction = calculateFrictionLoss(cfm, effectiveDuctDiameterIn);
    final velPress = calculateVelocityPressure(fpm, ms);

    final double maxDimIn = math.max(
      rectWidthIn,
      math.max(rectHeightIn, shape == DuctShape.round ? standardRoundDiameterIn : 0),
    );
    final double maxDimMm = math.max(
      rectWidthMm,
      math.max(rectHeightMm, shape == DuctShape.round ? standardRoundDiameterMm : 0),
    );
    final gaugeRec = getRecommendedGauge(maxDimIn, maxDimMm);

    String? aspectWarning;
    if (shape == DuctShape.rectangular) {
      if (aspectRatio > 4.0) {
        aspectWarning =
            'Aspect ratio ${aspectRatio.toStringAsFixed(1)}:1 exceeds ASHRAE 4:1 max limit!';
      } else if (aspectRatio > 2.5) {
        aspectWarning =
            'Elevated aspect ratio ${aspectRatio.toStringAsFixed(1)}:1. Ideal is ≤ 2:1.';
      }
    }

    String? velWarning;
    if (fpm > 2000) {
      velWarning =
          'High Velocity (${fpm.round()} fpm). Risk of excessive acoustic noise and friction.';
    } else if (fpm > 0 && fpm < 400) {
      velWarning =
          'Low Velocity (${fpm.round()} fpm). May cause thermal air stratification.';
    }

    return CalculationResult(
      standard: standard,
      shape: shape,
      airflowCfm: cfm,
      airflowLs: ls,
      airflowM3h: m3h,
      velocityFpm: fpm,
      velocityMs: ms,
      areaSqFt: double.parse(areaSqFt.toStringAsFixed(2)),
      areaSqM: double.parse(areaSqM.toStringAsFixed(3)),
      exactRoundDiameterIn: double.parse(exactRoundDiameterIn.toStringAsFixed(1)),
      exactRoundDiameterMm: double.parse(exactRoundDiameterMm.toStringAsFixed(0)),
      standardRoundDiameterIn: standardRoundDiameterIn,
      standardRoundDiameterMm: standardRoundDiameterMm,
      rectHeightIn: double.parse(rectHeightIn.toStringAsFixed(1)),
      rectWidthIn: double.parse(rectWidthIn.toStringAsFixed(1)),
      rectHeightMm: double.parse(rectHeightMm.toStringAsFixed(0)),
      rectWidthMm: double.parse(rectWidthMm.toStringAsFixed(0)),
      aspectRatio: double.parse(aspectRatio.toStringAsFixed(1)),
      huebscherEquivalentDiameterIn:
          double.parse(huebscherEqIn.toStringAsFixed(1)),
      huebscherEquivalentDiameterMm:
          double.parse(huebscherEqMm.toStringAsFixed(0)),
      velocityPressureInWg: friction['inWgPer100Ft'] ?? 0.0,
      velocityPressurePa: velPress['pa'] ?? 0.0,
      frictionLossPer100FtInWg: friction['inWgPer100Ft'] ?? 0.0,
      frictionLossPerMPa: friction['paPerM'] ?? 0.0,
      recommendedGaugeSMACNA: gaugeRec['smacna'] ?? '',
      recommendedGaugeDW144: gaugeRec['dw144'] ?? '',
      aspectRatioWarning: aspectWarning,
      velocityWarning: velWarning,
    );
  }
}
