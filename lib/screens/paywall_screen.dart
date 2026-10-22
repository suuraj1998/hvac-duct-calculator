import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/platform_support.dart';
import '../services/revenue_cat_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedOption = 0;
  bool _isProcessing = false;

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);
    final rc = RevenueCatService.instance;
    bool success = false;
    if (rc.availablePackages.isNotEmpty) {
      final index = _selectedOption.clamp(0, rc.availablePackages.length - 1);
      success = await rc.purchasePackage(rc.availablePackages[index]);
    } else if (!PlatformSupport.supportsBilling || kDebugMode) {
      // Web and demo mode grant instant Pro status
      rc.setDebugProStatus(true);
      success = true;
    }
    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Pro Unlocked! All ads removed & instant PDF export enabled.'
            : 'Purchases are not available on this platform or device right now.'),
      ),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPro = RevenueCatService.instance.isProUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1216),
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 56),
              const SizedBox(height: 16),
              const Text(
                'Unlock HVAC Pro Field Suite',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ad-free calculation workflow, unlimited PDF job sheet exports, and full offline SMACNA / DW144 reference charts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 32),

              _buildPricingCard(
                index: 0,
                title: '\$9.99 Lifetime Pro Unlock',
                subtitle: 'Pay once, own forever. Best value for professional technicians.',
                badge: 'RECOMMENDED',
              ),
              const SizedBox(height: 14),
              _buildPricingCard(
                index: 1,
                title: '\$1.99 / Month Subscription',
                subtitle: 'Flexible monthly billing. Cancel anytime via your app store.',
              ),

              const Spacer(),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF003822),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _handlePurchase,
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : Text(
                          isPro ? 'Pro Already Active' : 'Upgrade Now',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  RevenueCatService.instance.restorePurchases();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restoring previous purchases...')),
                  );
                },
                child: const Text('Restore Previous Purchases', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required int index,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final isSelected = _selectedOption == index;
    return InkWell(
      onTap: () => setState(() => _selectedOption = index),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(4)),
                    child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
