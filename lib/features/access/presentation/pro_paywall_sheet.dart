import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../data/account_access_service.dart';
import '../data/revenuecat_service.dart';

Future<bool> showOwnzithPaywall(BuildContext context) async {
  final upgraded = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainer,
    builder: (_) => const _ProPaywallSheet(),
  );
  return upgraded ?? false;
}

class _ProPaywallSheet extends StatefulWidget {
  const _ProPaywallSheet();

  @override
  State<_ProPaywallSheet> createState() => _ProPaywallSheetState();
}

class _ProPaywallSheetState extends State<_ProPaywallSheet> {
  late final Future<List<Package>> _packages = RevenueCatService.packages();
  bool _busy = false;
  String? _error;

  Future<void> _purchase(Package package) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final customer = await RevenueCatService.purchase(package);
      final active = customer.entitlements.active.containsKey(
        RevenueCatService.entitlementId,
      );
      await AccountAccessService.instance.refresh();
      if (mounted && active) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'The purchase could not be completed.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ownzith Pro',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text('Built for large personal collections.'),
            const SizedBox(height: AppSpacing.lg),
            const _Benefit(
              icon: Icons.inventory_2_outlined,
              text: 'Archive up to 10,000 collectibles',
            ),
            const _Benefit(
              icon: Icons.auto_awesome_outlined,
              text: '50 PhotoID requests each month',
            ),
            const _Benefit(
              icon: Icons.qr_code_scanner_rounded,
              text: '100 catalog barcode lookups each month',
            ),
            const _Benefit(
              icon: Icons.lock_outline_rounded,
              text: 'Your collection stays preserved if you cancel',
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<List<Package>>(
              future: _packages,
              builder: (context, snapshot) {
                final packages = [...?snapshot.data];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (packages.isEmpty) {
                  return const Text(
                    'Subscriptions are being prepared for this build. Your current access is unchanged.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  );
                }
                packages.sort(
                  (a, b) => a.packageType == PackageType.annual ? -1 : 1,
                );
                return Column(
                  children: [
                    for (final package in packages)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : () => _purchase(package),
                            child: Text(_packageLabel(package)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.sm),
            const Text(
              r'$7.99/month or $59.99/year. Subscriptions renew automatically unless canceled in Apple account settings.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _packageLabel(Package package) {
    final period = package.packageType == PackageType.annual
        ? 'Annual'
        : 'Monthly';
    return '$period • ${package.storeProduct.priceString}';
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
