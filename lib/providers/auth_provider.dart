import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isBootstrapping = true;
  String _role = '';
  String _email = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isBootstrapping => _isBootstrapping;
  String get role => _role;
  String get email => _email;

  Future<void> bootstrapSession() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      _isBootstrapping = false;
      notifyListeners();
      return;
    }

    try {
      final me = await ApiService.getMe();
      _isAuthenticated = true;
      _role = me['role']?.toString() ?? 'customer';
      _email = me['email']?.toString() ?? '';
    } catch (_) {
      await ApiService.clearToken();
      _isAuthenticated = false;
      _role = '';
      _email = '';
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final data = await ApiService.login(email, password);
      if (data.containsKey('access')) {
        await ApiService.saveToken(data['access']);
        _isAuthenticated = true;
        // Получаем роль с сервера
        final me = await ApiService.getMe();
        _role = me['role'] ?? 'customer';
        _email = me['email']?.toString() ?? email;
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
