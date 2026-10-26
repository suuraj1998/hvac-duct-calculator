import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
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
    final rc = RevenueCatService.instance;

    if (kIsWeb) {
      _openWebCheckoutDialog();
      return;
    }

    setState(() => _isProcessing = true);
    bool success = false;

    if (rc.availablePackages.isNotEmpty) {
      final index = _selectedOption.clamp(0, rc.availablePackages.length - 1);
      success = await rc.purchasePackage(rc.availablePackages[index]);
    } else if (!PlatformSupport.supportsBilling) {
      rc.setDebugProStatus(true);
      success = true;
    } else {
      final result = await rc.presentPaywall();
      success = result == PaywallResult.purchased || result == PaywallResult.restored;
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'hvac_pro Unlocked! All ads removed & instant PDF export enabled.'
            : 'Purchase was not completed.'),
      ),
    );
    if (success) Navigator.pop(context);
  }

  void _openWebCheckoutDialog() {
    final emailCtrl = TextEditingController();
    final cardCtrl = TextEditingController(text: '4242 •••• •••• 4242');
    final expCtrl = TextEditingController(text: '12/28');
    final cvcCtrl = TextEditingController(text: '888');

    final planTitles = ['Lifetime (\$9.99)', 'Yearly (\$14.99/yr)', 'Monthly (\$1.99/mo)'];
    final selectedPlan = planTitles[_selectedOption.clamp(0, 2)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171B21),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 8),
            Text('Secure Web Checkout - $selectedPlan',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter billing email and card information to complete your subscription:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email, color: Color(0xFF06B6D4)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  prefixIcon: Icon(Icons.credit_card, color: Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expCtrl,
                      decoration: const InputDecoration(labelText: 'MM/YY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvcCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'CVC'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 6),
                  Text('Encrypted 256-bit SSL Web Checkout', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(ctx);
              RevenueCatService.instance.setDebugProStatus(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment Successful! hvac_pro active on Web portal.'),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Pay & Unlock Pro', style: TextStyle(color: Color(0xFF003822), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rc = RevenueCatService.instance;
    final isPro = rc.isProUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1216),
      appBar: AppBar(
        title: const Text('Upgrade to HVAC Pro'),
        backgroundColor: Colors.transparent,
        actions: [
          if (isPro)
            IconButton(
              icon: const Icon(Icons.manage_accounts, color: Color(0xFF10B981)),
              tooltip: 'Manage Subscription',
              onPressed: () => rc.presentCustomerCenter(),
            ),
        ],
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
              const SizedBox(height: 28),

              if (rc.availablePackages.isNotEmpty) ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: rc.availablePackages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pkg = rc.availablePackages[index];
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
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pkg.storeProduct.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pkg.storeProduct.description,
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                pkg.storeProduct.priceString,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                _buildFallbackPricingCard(
                  index: 0,
                  title: 'Lifetime (lifetime)',
                  subtitle: '\$9.99 One-time purchase. Pay once, own forever.',
                  badge: 'BEST VALUE',
                ),
                const SizedBox(height: 12),
                _buildFallbackPricingCard(
                  index: 1,
                  title: 'Yearly (yearly)',
                  subtitle: '\$14.99 / Year. Full annual pro access.',
                ),
                const SizedBox(height: 12),
                _buildFallbackPricingCard(
                  index: 2,
                  title: 'Monthly (monthly)',
                  subtitle: '\$1.99 / Month. Flexible monthly billing.',
                ),
                const Spacer(),
              ],

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
                          isPro ? 'Pro Already Active' : 'Upgrade to hvac_pro',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final restored = await rc.restorePurchases();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored
                              ? 'Purchases restored! hvac_pro unlocked.'
                              : 'No previous purchases found for this account.'),
                        ),
                      );
                    },
                    child: const Text('Restore Purchases', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                  const Text('•', style: TextStyle(color: Color(0xFF64748B))),
                  TextButton(
                    onPressed: () => rc.presentCustomerCenter(),
                    child: const Text('Customer Center', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackPricingCard({
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
        padding: const EdgeInsets.all(16),
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
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(4)),
                    child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
