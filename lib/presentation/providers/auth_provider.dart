import 'package:flutter/material.dart';

class LocalUser {
  final String uid;
  final String email;
  final String name;
  LocalUser({required this.uid, required this.email, required this.name});
}

class AuthProvider extends ChangeNotifier {
  LocalUser? _user = LocalUser(uid: 'default_user', name: 'Smart User', email: 'user@smartspend.ai');

  AuthProvider() {
    // No initialization needed as we use a hardcoded user
  }

  LocalUser? get user => _user;
  bool get isLoading => false;
  bool get isAuthenticated => true;

  Future<String?> createProfile(String email, String name) async {
    return null;
  }

  Future<void> signOut() async {
    // Logout removed
  }
}
