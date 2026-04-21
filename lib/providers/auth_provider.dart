import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _role = '';
  String _email = '';

  bool get isAuthenticated => _isAuthenticated;
  String get role => _role;
  String get email => _email;

  Future<bool> login(String email, String password) async {
    try {
      final data = await ApiService.login(email, password);
      if (data.containsKey('access')) {
        await ApiService.saveToken(data['access']);
        _isAuthenticated = true;
        _email = email;
        // Получаем роль с сервера
        final me = await ApiService.getMe();
        _role = me['role'] ?? 'customer';
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changeRole(String newRole) async {
    try {
      final data = await ApiService.changeRole(newRole);
      if (data.containsKey('role')) {
        _role = data['role'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _isAuthenticated = false;
    _email = '';
    _role = '';
    notifyListeners();
  }
}