import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../shared/widgets/browse_menu_button.dart';

class EmptyCartView extends StatelessWidget {
  final VoidCallback? onBack;

  const EmptyCartView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 250,
              height: 220,
              child: Lottie.asset(
                'assets/animations/empty_cart.json',
                width: 250,
                repeat: false,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if Lottie fails or asset is missing
                  return Icon(Icons.shopping_basket_outlined,
                      size: 100,
                      color: Theme.of(context).colorScheme.onSurfaceVariant);
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Looks like you haven't added anything yet",
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            BrowseMenuButton(onTap: onBack),
          ],
        ),
      ),
    );
  }
}
