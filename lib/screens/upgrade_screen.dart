import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/purchase_service.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    if (app.isProUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pro Unlocked')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded, color: Colors.green, size: 72),
              const SizedBox(height: 20),
              Text(
                'You have Pro!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All features are unlocked.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ).animate().scale(
                      curve: Curves.elasticOut,
                      duration: 600.ms,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'KyoReader Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 8),
                    const Text(
                      'One-time purchase. No subscriptions.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 20),
                    // Price badge
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '${PurchaseService.displayPrice} only',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .scale(begin: const Offset(0.9, 0.9)),
                  ],
                ),
              ),

              // Features list
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What you get',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._features.asMap().entries.map(
                      (e) => _FeatureRow(
                        icon: e.value.$1,
                        title: e.value.$2,
                        subtitle: e.value.$3,
                        index: e.key,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      child: app.isPurchasing
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () => _purchase(context, app),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                'Unlock for ${PurchaseService.displayPrice}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 12),

                    // Restore button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: app.isPurchasing
                            ? null
                            : () => _restore(context, app),
                        child: const Text('Restore Purchase'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms note
                    Text(
                      '· One-time non-consumable purchase\n'
                      '· Works across reinstalls via Restore\n'
                      '· No recurring charges',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _features = [
    (
      Icons.description_rounded,
      'DOCX & Word Files',
      'Open and preview Word documents',
    ),
    (
      Icons.folder_zip_rounded,
      'ZIP Archive Viewer',
      'Browse archive contents instantly',
    ),
    (Icons.search_rounded, 'PDF Search', 'Full-text search inside PDFs'),
    (Icons.bookmark_rounded, 'Bookmarks', 'Bookmark pages across all files'),
    (Icons.bolt_rounded, 'Priority Support', 'Get help faster from the team'),
    (Icons.update_rounded, 'Lifetime Updates', 'All future features included'),
  ];

  Future<void> _purchase(BuildContext context, AppProvider app) async {
    final result = await app.purchasePro();
    if (!context.mounted) return;
    if (result.success) {
      _showSuccessDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Purchase failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restore(BuildContext context, AppProvider app) async {
    final result = await app.restorePurchase();
    if (!context.mounted) return;
    if (result.success) {
      _showSuccessDialog(context, restored: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'No purchase found to restore.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, {bool restored = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.verified_rounded, color: Colors.green, size: 40),
        title: Text(restored ? 'Purchase Restored!' : 'Welcome to Pro!'),
        content: const Text('All features are now unlocked. Thank you!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Start Using Pro'),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int index;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Animate(
      delay: Duration(milliseconds: 200 + index * 60),
      effects: [
        FadeEffect(duration: 300.ms),
        SlideEffect(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          duration: 300.ms,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
