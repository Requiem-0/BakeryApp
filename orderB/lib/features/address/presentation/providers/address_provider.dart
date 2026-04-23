import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/address.dart';
import '../../../catalogue/data/datasources/catalogue_local_datasource.dart';

/// Manages the currently selected delivery/pickup address with persistence.
class AddressProvider extends ChangeNotifier {
  static const _key = 'selected_address_id';
  int _selectedId = 1;

  AddressProvider() {
    _load();
  }

  int get selectedId => _selectedId;

  Address get selected => CatalogueLocalDatasource.savedAddresses.firstWhere(
        (a) => a.id == _selectedId,
        orElse: () => CatalogueLocalDatasource.savedAddresses.first,
      );

  void select(int id) {
    _selectedId = id;
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_key);
    if (id != null) {
      _selectedId = id;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _selectedId);
  }
}
