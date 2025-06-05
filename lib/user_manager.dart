import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class User {
  final String email;
  final String? nom;
  final String? prenom;
  final int? id;

  User({
    required this.email,
    this.nom,
    this.prenom,
    this.id,
  });
}

class UserManager {
  static final ValueNotifier<User?> _currentUser = ValueNotifier<User?>(null);

  static ValueNotifier<User?> get currentUser => _currentUser;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final id = prefs.getInt('user_id');
    if (email != null && id != null) {
      _currentUser.value = User(email: email, id: id);
    }
  }

  static void setUser(User user) async {
    if (user.id == null) {
      print('⚠️ Attention : User sans ID !');
    }
    _currentUser.value = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user.email);
    if (user.id != null) await prefs.setInt('user_id', user.id!);
  }

  static void clear() async {
    _currentUser.value = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_id');
  }

  static Future<User?> getUser() async {
    return _currentUser.value;
  }
}
