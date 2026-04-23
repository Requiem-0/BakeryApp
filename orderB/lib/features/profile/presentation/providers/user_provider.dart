import 'package:flutter/foundation.dart';

/// Manages current user profile state.
class UserProvider extends ChangeNotifier {
  String _name = 'Sophie Martin';
  String _email = 'sophie.martin@email.com';
  String _phone = '+44 7700 900 123';
  String _birthday = 'March 14, 1990';
  String _bio = 'Bread enthusiast & weekend baker 🍞';
  final String _membershipTier = 'Croissant Member';
  String _initials = 'S';

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String get birthday => _birthday;
  String get bio => _bio;
  String get membershipTier => _membershipTier;
  String get initials => _initials;

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? birthday,
    String? bio,
  }) {
    if (name != null) {
      _name = name;
      _initials = name.isNotEmpty ? name[0].toUpperCase() : '';
    }
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    if (birthday != null) _birthday = birthday;
    if (bio != null) _bio = bio;
    notifyListeners();
  }
}
