import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/hvac_models.dart';
import '../services/calculator_service.dart';
import '../services/ad_service.dart';
import '../services/platform_support.dart';
import '../services/revenue_cat_service.dart';
import '../services/pdf_export_service.dart';
import 'reference_library_screen.dart';
import 'paywall_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  MeasurementStandard _standard = MeasurementStandard.imperial;
  DuctShape _shape = DuctShape.rectangular;
  final MetricFlowUnit _metricFlowUnit = MetricFlowUnit.litersPerSecond;

  final TextEditingController _airflowCtrl =
      TextEditingController(text: '1200');
  final TextEditingController _velocityCtrl =
      TextEditingController(text: '900');
  final TextEditingController _rectHeightCtrl =
      TextEditingController(text: '12');

  CalculationResult? _result;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _recalculate();
    _initBannerAd();
  }

  void _initBannerAd() {
    if (RevenueCatService.instance.isProUser || !PlatformSupport.supportsAds) {
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: AdService.testBannerIdAndroid,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  void _toggleMeasurementStandard() {
    setState(() {
      final airflow = double.tryParse(_airflowCtrl.text.replaceAll(',', '.')) ?? 1200;
      final velocity = double.tryParse(_velocityCtrl.text.replaceAll(',', '.')) ?? 900;
      final inHeight = double.tryParse(_rectHeightCtrl.text.replaceAll(',', '.')) ?? 12;

      if (_standard == MeasurementStandard.imperial) {
        _standard = MeasurementStandard.metric;
        _airflowCtrl.text = (airflow * 0.471947).round().toString();
        _velocityCtrl.text = (velocity * 0.00508).toStringAsFixed(1);
        _rectHeightCtrl.text = (inHeight * 25.4).round().toString();
      } else {
        _standard = MeasurementStandard.imperial;
        _airflowCtrl.text = (airflow / 0.471947).round().toString();
        _velocityCtrl.text = (velocity / 0.00508).round().toString();
        _rectHeightCtrl.text = (inHeight / 25.4).round().toString();
      }
      _recalculate();
    });
  }

  void _recalculate() {
    final airflow = double.tryParse(_airflowCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final velocity = double.tryParse(_velocityCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final rectHeight = double.tryParse(_rectHeightCtrl.text.replaceAll(',', '.')) ?? 0.0;

    setState(() {
      _result = CalculatorService.instance.calculate(
        standard: _standard,
        shape: _shape,
        airflowInput: airflow,
        metricFlowUnit: _metricFlowUnit,
        velocityInput: velocity,
        rectSideAInput: rectHeight,
      );
    });
  }

  void _onClearCalculation() {
    AdService.instance.showInterstitialIfAllowed();

    setState(() {
      _airflowCtrl.text =
          _standard == MeasurementStandard.imperial ? '1000' : '500';
      _velocityCtrl.text =
          _standard == MeasurementStandard.imperial ? '800' : '4.0';
      _rectHeightCtrl.text =
          _standard == MeasurementStandard.imperial ? '12' : '300';
      _recalculate();
    });
  }

  void _handlePdfExport() {
    if (_result == null) return;

    AdService.instance.showRewardedAdForPdfExport(
      onRewardEarned: () => _openPdfMetadataDialog(),
      onFailed: () => _openPdfMetadataDialog(),
    );
  }

  void _openPdfMetadataDialog() {
    final jobCtrl =
        TextEditingController(text: 'Air Handling Unit 1 - Main Trunk');
    final locCtrl = TextEditingController(text: 'Floor 3 Mechanical Room');
    final techCtrl = TextEditingController(text: 'Lead HVAC Engineer');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171B21),
        title: const Text('Export PDF Job Sheet',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: jobCtrl,
                decoration:
                    const InputDecoration(labelText: 'Job / System Name')),
            const SizedBox(height: 12),
            TextField(
                controller: locCtrl,
                decoration:
                    const InputDecoration(labelText: 'Client Location')),
            const SizedBox(height: 12),
            TextField(
                controller: techCtrl,
                decoration:
                    const InputDecoration(labelText: 'Technician Name')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(ctx);
              PdfExportService.instance.exportJobSheet(
                result: _result!,
                jobName: jobCtrl.text,
                clientLocation: locCtrl.text,
                technicianName: techCtrl.text,
              );
            },
            child: const Text('Generate PDF',
                style: TextStyle(color: Color(0xFF003822))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = RevenueCatService.instance.isProUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HVAC Duct Calculator',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F1216),
        actions: [
          ActionChip(
            label: Text(
              _standard == MeasurementStandard.imperial
                  ? '🇺🇸 Imperial'
                  : '🇪🇺 Metric',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            backgroundColor: const Color(0xFF222831),
            onPressed: _toggleMeasurementStandard,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book, color: Color(0xFF06B6D4)),
            tooltip: 'Reference Library',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReferenceLibraryScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              isPro ? Icons.verified : Icons.workspace_premium,
              color: isPro ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
            tooltip: isPro ? 'Pro Active' : 'Upgrade to Pro',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 800;

                Widget content;
                if (isWideScreen) {
                  content = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildInputCard()),
                      const SizedBox(width: 16),
                      if (_result != null)
                        Expanded(child: _buildRealTimeResultsCard(_result!)),
                    ],
                  );
                } else {
                  content = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInputCard(),
                      const SizedBox(height: 16),
                      if (_result != null) _buildRealTimeResultsCard(_result!),
                    ],
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
          if (!isPro && _isBannerLoaded && _bannerAd != null)
            SafeArea(
              top: false,
              child: Container(
                color: const Color(0xFF171B21),
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<DuctShape>(
                    segments: const [
                      ButtonSegment(
                          value: DuctShape.rectangular,
                          label: Text('Rectangular')),
                      ButtonSegment(
                          value: DuctShape.round, label: Text('Round')),
                    ],
                    selected: {_shape},
                    onSelectionChanged: (set) {
                      setState(() {
                        _shape = set.first;
                        _recalculate();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
                  tooltip: 'Reset calculation',
                  onPressed: _onClearCalculation,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _airflowCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _standard == MeasurementStandard.imperial
                          ? 'Airflow (CFM)'
                          : 'Airflow (L/s)',
                      prefixIcon:
                          const Icon(Icons.air, color: Color(0xFF06B6D4)),
                    ),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _velocityCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _standard == MeasurementStandard.imperial
                          ? 'Velocity (fpm)'
                          : 'Velocity (m/s)',
                      prefixIcon:
                          const Icon(Icons.speed, color: Color(0xFF10B981)),
                    ),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
              ],
            ),
            if (_shape == DuctShape.rectangular) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _rectHeightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _standard == MeasurementStandard.imperial
                      ? 'Duct Height (inches) - Ceiling Clearance'
                      : 'Duct Height (mm)',
                  prefixIcon:
                      const Icon(Icons.height, color: Color(0xFFA855F7)),
                ),
                onChanged: (_) => _recalculate(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeResultsCard(CalculationResult res) {
    final isPro = RevenueCatService.instance.isProUser;

    return Card(
      color: const Color(0xFF171B21),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RECOMMENDED DUCT SIZE',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    _shape == DuctShape.round
                        ? 'EN 1506 Standard'
                        : 'ASHRAE Huebscher',
                    style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_shape == DuctShape.rectangular) ...[
              Text(
                _standard == MeasurementStandard.imperial
                    ? '${res.rectWidthIn}" W x ${res.rectHeightIn}" H'
                    : '${res.rectWidthMm.round()} mm W x ${res.rectHeightMm.round()} mm H',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Huebscher Circular Equivalent: ${res.huebscherEquivalentDiameterIn}" (${res.huebscherEquivalentDiameterMm.round()} mm) • Ratio ${res.aspectRatio}:1',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ] else ...[
              Text(
                _standard == MeasurementStandard.imperial
                    ? '${res.standardRoundDiameterIn}" Ø'
                    : '${res.standardRoundDiameterMm.round()} mm Ø',
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF06B6D4)),
              ),
              const SizedBox(height: 4),
              Text(
                'Exact Theoretical Diameter: ${res.exactRoundDiameterIn}" (${res.exactRoundDiameterMm.round()} mm)',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
            if (res.aspectRatioWarning != null || res.velocityWarning != null) ...[
              const SizedBox(height: 12),
              if (res.aspectRatioWarning != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF451A03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(res.aspectRatioWarning!,
                            style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              if (res.velocityWarning != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF451A03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(res.velocityWarning!,
                            style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11)),
                      ),
                    ],
                  ),
                ),
            ],
            const Divider(height: 28, color: Color(0xFF2A323D)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn(
                    'Friction Loss',
                    '${res.frictionLossPer100FtInWg} in.wg',
                    '${res.frictionLossPerMPa} Pa/m'),
                _buildMetricColumn(
                    'Velocity Press (Pv)',
                    '${res.velocityPressureInWg} in.wg',
                    '${res.velocityPressurePa} Pa'),
                _buildMetricColumn(
                    'Free Area', '${res.areaSqFt} sq ft', '${res.areaSqM} m²'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF222831),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SMACNA: ${res.recommendedGaugeSMACNA} • DW144: ${res.recommendedGaugeDW144}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: const Color(0xFF00363F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  isPro
                      ? 'Export PDF Job Sheet (Pro)'
                      : 'Export PDF Job Sheet (Watch Ad)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _handlePdfExport,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String title, String val1, String val2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(val1,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white)),
        Text(val2,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }
}
