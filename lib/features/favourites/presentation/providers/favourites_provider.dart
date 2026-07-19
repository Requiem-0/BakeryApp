import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user's favourite product IDs with persistence.
///
/// Product IDs are Mongo ObjectId strings (live API) or numeric-string
/// fallbacks for legacy mock data — both stored as plain strings.
class FavouritesProvider extends ChangeNotifier {
  static const _key = 'favourite_ids';
  final Set<String> _favourites = {};

  FavouritesProvider() {
    _load();
  }

  Set<String> get favourites => Set.unmodifiable(_favourites);

  bool isFavourite(String productId) => _favourites.contains(productId);

  void toggle(String productId) {
    if (_favourites.contains(productId)) {
      _favourites.remove(productId);
    } else {
      _favourites.add(productId);
    }
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key);
      if (ids != null) {
        _favourites.addAll(ids);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('🚨 FavouritesProvider._load failed: $e\n$st');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _favourites.toList());
    } catch (e, st) {
      debugPrint('🚨 FavouritesProvider._save failed: $e\n$st');
    }
  }
}
