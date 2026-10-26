import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hvac_models.dart';
import '../services/calculator_service.dart';
import '../services/ad_service.dart';
import '../services/platform_support.dart';
import '../services/revenue_cat_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/duct_visual_widget.dart';
import '../widgets/web_ad_banner.dart';
import '../widgets/web_ad_gate.dart';
import 'onboarding/onboarding_screen.dart';
import 'reference_library_screen.dart';
import 'paywall_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

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
  final List<DuctSegment> _segments = [];

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _recalculate();
    _initBannerAd();
  }

  void _initBannerAd() {
    if (RevenueCatService.instance.isProUser || !PlatformSupport.supportsAds) {
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerIdAndroid,
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

  void _addCurrentToSchedule() {
    if (_result == null) return;
    final segName = 'Segment ${_segments.length + 1} (${_shape == DuctShape.round ? "Round" : "Rect"})';
    setState(() {
      _segments.add(
        DuctSegment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: segName,
          result: _result!,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$segName" to Ductwork Schedule!')),
    );
  }

  Future<void> _openProfileCredentialsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final nameCtrl = TextEditingController(text: prefs.getString('tech_name') ?? 'Lead Technician');
    final emailCtrl = TextEditingController(text: prefs.getString('tech_email') ?? '');
    final companyCtrl = TextEditingController(text: prefs.getString('tech_company') ?? 'HVAC Field Services');
    bool trustDevice = prefs.getBool('trust_device') ?? true;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF171B21),
          title: const Row(
            children: [
              Icon(Icons.account_circle, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Technician Profile & Credentials', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stored 100% locally on your device. Credentials are never sent to external servers.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Technician Name')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 12),
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Firm Name')),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: trustDevice,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF10B981),
                  title: const Text('Trust this device & stay logged in', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Keeps your credentials saved locally so you do not need to re-enter them.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  onChanged: (val) => setDialogState(() => trustDevice = val ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                final nav = Navigator.of(ctx);
                await prefs.setString('tech_name', nameCtrl.text);
                await prefs.setString('tech_email', emailCtrl.text);
                await prefs.setString('tech_company', companyCtrl.text);
                await prefs.setBool('trust_device', trustDevice);
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Credentials & Login state saved securely on your device!')),
                );
              },
              child: const Text('Save & Stay Logged In', style: TextStyle(color: Color(0xFF003822), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performFullAppReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171B21),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Reset Application State?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will clear saved calculation parameters, local credentials, and duct schedules, and restart the app from the beginning onboarding wizard.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.verified, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your active subscription and Pro license will NOT be reset.',
                    style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final isPro = RevenueCatService.instance.isProUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Preserve active subscription status across app factory resets
    if (isPro) {
      RevenueCatService.instance.setDebugProStatus(true);
      await prefs.setBool('is_pro_active', true);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
    );
  }

  Future<void> _handlePdfExport() async {
    if (_result == null) return;

    if (kIsWeb) {
      await showWebAdGate(context);
      if (!mounted) return;
      _openPdfMetadataDialog();
      return;
    }

    AdService.instance.showRewardedAdForPdfExport(
      onRewardEarned: () => _openPdfMetadataDialog(),
      onFailed: () => _openPdfMetadataDialog(),
    );
  }

  void _openPdfMetadataDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('tech_name') ?? 'Lead HVAC Engineer';

    final jobCtrl = TextEditingController(text: 'Air Handling Unit 1 - Main Trunk');
    final locCtrl = TextEditingController(text: 'Floor 3 Mechanical Room');
    final techCtrl = TextEditingController(text: savedName);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171B21),
        title: const Text('Export PDF Job Sheet', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: jobCtrl, decoration: const InputDecoration(labelText: 'Job / System Name')),
            const SizedBox(height: 12),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Client Location')),
            const SizedBox(height: 12),
            TextField(controller: techCtrl, decoration: const InputDecoration(labelText: 'Technician Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(ctx);
              PdfExportService.instance.exportJobSheet(
                result: _result!,
                jobName: jobCtrl.text,
                clientLocation: locCtrl.text,
                technicianName: techCtrl.text,
              );
            },
            child: const Text('Generate PDF', style: TextStyle(color: Color(0xFF003822))),
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
        title: const Text('HVAC Duct Sizing Suite', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F1216),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: const Color(0xFF10B981),
          tabs: const [
            Tab(icon: Icon(Icons.calculate, size: 20), text: 'Duct Sizer'),
            Tab(icon: Icon(Icons.table_chart, size: 20), text: 'Schedule Table'),
            Tab(icon: Icon(Icons.swap_horiz, size: 20), text: 'Equal Friction'),
          ],
        ),
        actions: [
          ActionChip(
            label: Text(
              _standard == MeasurementStandard.imperial ? '🇺🇸 Imperial' : '🇪🇺 Metric',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            backgroundColor: const Color(0xFF222831),
            onPressed: _toggleMeasurementStandard,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Color(0xFF10B981)),
            tooltip: 'Local Profile Credentials',
            onPressed: _openProfileCredentialsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Color(0xFFEF4444)),
            tooltip: 'Reset App & Start From Beginning',
            onPressed: _performFullAppReset,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book, color: Color(0xFF06B6D4)),
            tooltip: 'Reference Library',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReferenceLibraryScreen()),
            ),
          ),
          if (!kIsWeb)
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
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildSizerTab(),
                _buildScheduleTab(),
                _buildConverterTab(),
              ],
            ),
          ),
          if (!isPro)
            SafeArea(
              top: false,
              child: kIsWeb
                  ? const WebAdBanner()
                  : (_isBannerLoaded && _bannerAd != null
                      ? Container(
                          color: const Color(0xFF171B21),
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        )
                      : const SizedBox.shrink()),
            ),
        ],
      ),
    );
  }

  Widget _buildSizerTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 800;

        Widget content;
        if (isWideScreen) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildInputCard()),
              const SizedBox(width: 16),
              if (_result != null) Expanded(child: _buildRealTimeResultsCard(_result!)),
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
    );
  }

  Widget _buildScheduleTab() {
    final totalCfm = _segments.fold<double>(0, (sum, item) => sum + item.result.airflowCfm);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0xFF171B21),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROJECT DUCTWORK SCHEDULE',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${_segments.length} Segments Listed • Total Airflow: ${totalCfm.round()} CFM',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF003822)),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export Schedule PDF'),
                        onPressed: _segments.isEmpty
                            ? null
                            : () {
                                PdfExportService.instance.exportScheduleSheet(
                                  segments: _segments,
                                  projectName: 'HVAC Air System Schedule',
                                  engineerName: 'HVAC Project Lead',
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_segments.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.note_add, color: Color(0xFF64748B), size: 48),
                        const SizedBox(height: 12),
                        const Text('No Duct Segments Added Yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Go to the Duct Sizer tab and tap "Add to Schedule Table" to build a multi-segment duct schedule.',
                            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _segments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final seg = _segments[index];
                    final res = seg.result;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF064E3B),
                          child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(seg.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(
                          res.shape == DuctShape.round
                              ? '${res.standardRoundDiameterIn}" Ø (${res.standardRoundDiameterMm.round()} mm) • ${res.airflowCfm.round()} CFM • ${res.velocityFpm.round()} fpm'
                              : '${res.rectWidthIn}" W x ${res.rectHeightIn}" H • ${res.airflowCfm.round()} CFM • ${res.velocityFpm.round()} fpm',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                          onPressed: () => setState(() => _segments.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConverterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EQUAL FRICTION & UNIT CONVERTER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Quick reference unit conversions for air distribution calculations.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  const Divider(height: 28, color: Color(0xFF2A323D)),
                  _buildConverterRow('Airflow', '1,000 CFM', '= 472 L/s = 1,699 m³/h'),
                  _buildConverterRow('Velocity', '1,000 fpm', '= 5.08 m/s'),
                  _buildConverterRow('Duct Size', '12 inches', '= 304.8 mm'),
                  _buildConverterRow('Friction Loss', '0.1 in. wg / 100ft', '= 0.817 Pa / m'),
                  _buildConverterRow('Velocity Pressure', '0.05 in. wg', '= 12.45 Pa'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConverterRow(String title, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF222831), borderRadius: BorderRadius.circular(6)),
                child: Text(val1, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(val2, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
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
                      ButtonSegment(value: DuctShape.rectangular, label: Text('Rectangular')),
                      ButtonSegment(value: DuctShape.round, label: Text('Round')),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _standard == MeasurementStandard.imperial ? 'Airflow (CFM)' : 'Airflow (L/s)',
                      prefixIcon: const Icon(Icons.air, color: Color(0xFF06B6D4)),
                    ),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _velocityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _standard == MeasurementStandard.imperial ? 'Velocity (fpm)' : 'Velocity (m/s)',
                      prefixIcon: const Icon(Icons.speed, color: Color(0xFF10B981)),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _standard == MeasurementStandard.imperial
                      ? 'Duct Height (inches) - Ceiling Clearance'
                      : 'Duct Height (mm)',
                  prefixIcon: const Icon(Icons.height, color: Color(0xFFA855F7)),
                ),
                onChanged: (_) => _recalculate(),
              ),
            ],
            const SizedBox(height: 16),
            if (_result != null) DuctVisualWidget(result: _result!),
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
                const Text('RECOMMENDED DUCT SIZE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    _shape == DuctShape.round ? 'EN 1506 Standard' : 'ASHRAE Huebscher',
                    style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.bold),
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
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: -0.5),
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
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF06B6D4)),
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
                  decoration: BoxDecoration(color: const Color(0xFF451A03), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF59E0B))),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(res.aspectRatioWarning!, style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11))),
                    ],
                  ),
                ),
              if (res.velocityWarning != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF451A03), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF59E0B))),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(res.velocityWarning!, style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11))),
                    ],
                  ),
                ),
            ],
            const Divider(height: 28, color: Color(0xFF2A323D)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn('Friction Loss', '${res.frictionLossPer100FtInWg} in.wg', '${res.frictionLossPerMPa} Pa/m'),
                _buildMetricColumn('Velocity Press (Pv)', '${res.velocityPressureInWg} in.wg', '${res.velocityPressurePa} Pa'),
                _buildMetricColumn('Free Area', '${res.areaSqFt} sq ft', '${res.areaSqM} m²'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF222831), borderRadius: BorderRadius.circular(8)),
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
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add to Schedule Table', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _addCurrentToSchedule,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: const Color(0xFF00363F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  isPro ? 'Export PDF Job Sheet (Pro)' : 'Export PDF Job Sheet (Watch Ad)',
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
        Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(val1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        Text(val2, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }
}
