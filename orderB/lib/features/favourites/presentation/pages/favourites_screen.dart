import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../../../catalogue/data/datasources/catalogue_local_datasource.dart';
import '../providers/favourites_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../catalogue/presentation/widgets/grid_product_card.dart';
import '../../../../shared/widgets/browse_menu_button.dart';
import '../../../../shared/widgets/app_back_button.dart';
import 'package:go_router/go_router.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favProv = context.watch<FavouritesProvider>();
    final cart = context.read<CartProvider>();
    final favs =
        CatalogueLocalDatasource.products.where((p) => favProv.isFavourite(p.id)).toList();

    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: AppBackButton(),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Favourites',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                        '${favs.length} saved item${favs.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: favs.isEmpty
                    ? _EmptyFavourites()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: favs.length,
                        itemBuilder: (_, i) {
                          final p = favs[i];
                          return GridProductCard(
                            product: p,
                            onTap: () =>
                                context.push('/favourites/product', extra: p),
                            onQuickAdd: () => cart.addProduct(p),
                            isFavourite: favProv.isFavourite(p.id),
                            onToggleFavourite: () => favProv.toggle(p.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ));
  }
}

class _EmptyFavourites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Lottie.asset('assets/animations/empty_fav.json',
                  width: 250, repeat: false, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text('No favourites yet',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text("Tap the ♡ on any item to save it here",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            const BrowseMenuButton(),
          ],
        ),
      ),
    );
  }
}
