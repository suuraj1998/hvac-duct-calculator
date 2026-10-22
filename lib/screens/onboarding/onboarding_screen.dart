import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../models/hvac_models.dart';
import '../calculator_screen.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  RegionType _selectedRegion = RegionType.usCanada;
  MeasurementStandard _selectedStandard = MeasurementStandard.imperial;

  void _onRegionSelected(RegionType region) {
    setState(() {
      _selectedRegion = region;
      if (region == RegionType.usCanada) {
        _selectedStandard = MeasurementStandard.imperial;
      } else {
        _selectedStandard = MeasurementStandard.metric;
      }
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefSelectedRegion, _selectedRegion.name);
    await prefs.setString(kPrefSelectedStandard, _selectedStandard.name);
    await prefs.setBool(kPrefIsFirstLaunch, false);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CalculatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1216),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 2,
                      backgroundColor: const Color(0xFF222831),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Step ${_currentStep + 1} of 2',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildRegionStep(),
                  _buildStandardStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.public, color: Color(0xFF10B981), size: 40),
          const SizedBox(height: 16),
          const Text(
            'Select Your Region',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'We configure local HVAC design codes, standard duct sizes, and units for your area.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: RegionType.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final region = RegionType.values[index];
                final isSelected = _selectedRegion == region;
                return InkWell(
                  onTap: () => _onRegionSelected(region),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF064E3B) : const Color(0xFF171B21),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF2A323D),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                region.displayName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(region.description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Confirm Units & Standards',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Recommended standard for ${_selectedRegion.displayName}. You can toggle this on any calculation screen with one tap.',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 28),
          ...MeasurementStandard.values.map((std) {
            final isSelected = _selectedStandard == std;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: InkWell(
                onTap: () => setState(() => _selectedStandard = std),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF064E3B) : const Color(0xFF171B21),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFF2A323D),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(std.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(std.unitsSummary, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF003822),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _completeOnboarding,
              child: const Text('Start Sizing Ducts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
