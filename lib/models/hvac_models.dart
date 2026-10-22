enum RegionType {
  usCanada('US & Canada', 'Default: Imperial (ASHRAE)'),
  ukAustralia('UK & Australia', 'Default: Metric (EN 1505/1506) / CIBSE'),
  continentalEurope('Continental Europe', 'Default: Metric (EN 1505/1506)'),
  restOfWorld('Rest of World', 'Default: Metric (ISO/ASHRAE SI)');

  final String displayName;
  final String description;
  const RegionType(this.displayName, this.description);
}

enum MeasurementStandard {
  imperial('Imperial (ASHRAE)', 'CFM, fpm, inches, in. wg/100ft'),
  metric('Metric (EN 1505/1506)', 'L/s or m³/h, m/s, mm, Pa/m');

  final String title;
  final String unitsSummary;
  const MeasurementStandard(this.title, this.unitsSummary);
}

enum DuctShape {
  rectangular('Rectangular Duct', 'Huebscher Equivalent Diameter'),
  round('Round Duct', 'Circular cross-section (Spiral / Rigid)'),
  flatOval('Flat Oval Duct', 'Low-clearance aerodynamic duct');

  final String title;
  final String subtitle;
  const DuctShape(this.title, this.subtitle);
}

enum MetricFlowUnit {
  litersPerSecond('L/s', 1.0),
  cubicMetersPerHour('m³/h', 3.6);

  final String label;
  final double conversionFactor;
  const MetricFlowUnit(this.label, this.conversionFactor);
}

class CalculationResult {
  final MeasurementStandard standard;
  final DuctShape shape;

  // Airflow
  final double airflowCfm;
  final double airflowLs;
  final double airflowM3h;

  // Velocity
  final double velocityFpm;
  final double velocityMs;

  // Cross-sectional Area
  final double areaSqFt;
  final double areaSqM;

  // Round Diameters
  final double exactRoundDiameterIn;
  final double exactRoundDiameterMm;
  final double standardRoundDiameterIn;
  final double standardRoundDiameterMm;

  // Rectangular Dimensions
  final double rectHeightIn;
  final double rectWidthIn;
  final double rectHeightMm;
  final double rectWidthMm;
  final double aspectRatio;
  final double huebscherEquivalentDiameterIn;
  final double huebscherEquivalentDiameterMm;

  // Pressure & Friction
  final double velocityPressureInWg;
  final double velocityPressurePa;
  final double frictionLossPer100FtInWg;
  final double frictionLossPerMPa;

  // Recommended Sheet Metal Gauges
  final String recommendedGaugeSMACNA;
  final String recommendedGaugeDW144;

  final String? aspectRatioWarning;
  final String? velocityWarning;

  const CalculationResult({
    required this.standard,
    required this.shape,
    required this.airflowCfm,
    required this.airflowLs,
    required this.airflowM3h,
    required this.velocityFpm,
    required this.velocityMs,
    required this.areaSqFt,
    required this.areaSqM,
    required this.exactRoundDiameterIn,
    required this.exactRoundDiameterMm,
    required this.standardRoundDiameterIn,
    required this.standardRoundDiameterMm,
    required this.rectHeightIn,
    required this.rectWidthIn,
    required this.rectHeightMm,
    required this.rectWidthMm,
    required this.aspectRatio,
    required this.huebscherEquivalentDiameterIn,
    required this.huebscherEquivalentDiameterMm,
    required this.velocityPressureInWg,
    required this.velocityPressurePa,
    required this.frictionLossPer100FtInWg,
    required this.frictionLossPerMPa,
    required this.recommendedGaugeSMACNA,
    required this.recommendedGaugeDW144,
    this.aspectRatioWarning,
    this.velocityWarning,
  });
}
