import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user's favourite product IDs with persistence.
class FavouritesProvider extends ChangeNotifier {
  static const _key = 'favourite_ids';
  final Set<int> _favourites = {};

  FavouritesProvider() {
    _load();
  }

  Set<int> get favourites => Set.unmodifiable(_favourites);

  bool isFavourite(int productId) => _favourites.contains(productId);

  void toggle(int productId) {
    if (_favourites.contains(productId)) {
      _favourites.remove(productId);
    } else {
      _favourites.add(productId);
    }
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key);
    if (ids != null) {
      _favourites.addAll(ids.map(int.parse));
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, _favourites.map((id) => id.toString()).toList());
  }
}
