import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../core/navigation/nav_provider.dart';

class AiTip extends StatefulWidget {
  const AiTip({super.key});

  @override
  State<AiTip> createState() => _AiTipState();
}

class _AiTipState extends State<AiTip> with SingleTickerProviderStateMixin {
  late String _currentTip;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _tips = [
    "Sourdough bread acts as a prebiotic, which means that the fiber in the bread helps feed the 'good' bacteria in your intestines.",
    "Multigrain bread provides complex carbohydrates ensuring a steady release of long-lasting energy throughout your day.",
    "Whole wheat pastries contain more nutrients and fiber than their refined counterparts, keeping you full and satisfied.",
    "Rye bread is incrednsibly dee with nutrients and has a lower glycemic index, preventing sudden blood sugar spikes.",
    "Oatmeal cookies, when made with whole oats, offer a great source of soluble fiber and can be a heart-healthy treat.",
    "Breads with seeds like flax or chia add a massive boost of Omega-3 fatty acids to your daily diet.",
    "Fermented doughs like sourdough break down gluten during fermentation, making it easier to digest for some people.",
    "Artisan whole grain breads are packed with B vitamins which are essential for energy metabolism and nerve health.",
  ];

  NavProvider? _navProvider;

  @override
  void initState() {
    super.initState();
    _currentTip = _tips[Random().nextInt(_tips.length)];
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navProvider ??= context.read<NavProvider>()..addListener(_generateNewTip);
  }

  @override
  void dispose() {
    _navProvider?.removeListener(_generateNewTip);
    _animCtrl.dispose();
    super.dispose();
  }

  void _generateNewTip() {
    if (_animCtrl.isAnimating) return;
    _animCtrl.reverse().then((_) {
      setState(() {
        String newTip;
        do {
          newTip = _tips[Random().nextInt(_tips.length)];
        } while (newTip == _currentTip && _tips.length > 1);
        _currentTip = newTip;
      });
      _animCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _generateNewTip,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.tertiary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Healthy Tip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      _currentTip,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
