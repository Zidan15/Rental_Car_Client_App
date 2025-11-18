import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client_app/models/user_model.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';
  static const String _isLoggedInFlagKey = 'isLoggedInFlag'; // NEW key for persistent login flag

  // --- NEW PERSISTENCE METHODS ---
  
  // Saves a flag indicating whether the user is logged in
  Future<void> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInFlagKey, isLoggedIn);
  }

  // Retrieves the persistent login flag for auto-login (used in main.dart)
  Future<bool> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    // Returns true if the flag is set, otherwise false
    return prefs.getBool(_isLoggedInFlagKey) ?? false;
  }
  // ------------------------------

  Future<void> signUp(String fullName, String email, String phoneNumber, String address, DateTime dateOfBirth, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final List<dynamic> usersList = jsonDecode(usersJson);
    
    final existingUser = usersList.firstWhere((u) => u['email'] == email, orElse: () => null);
    if (existingUser != null) {
      throw Exception('User with this email already exists');
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      dateOfBirth: dateOfBirth,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    usersList.add(newUser.toJson());
    await prefs.setString(_usersKey, jsonEncode(usersList));
    await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));
    
    // ACTION: Set the persistent login flag to true after successful sign up
    await saveLoginState(true); 
  }

  Future<void> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final List<dynamic> usersList = jsonDecode(usersJson);
    
    final user = usersList.firstWhere((u) => u['email'] == email, orElse: () => null);
    if (user == null) {
      throw Exception('Invalid email or password');
    }

    await prefs.setString(_currentUserKey, jsonEncode(user));
    
    // ACTION: Set the persistent login flag to true after successful login
    await saveLoginState(true); 
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson == null) return null;
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = jsonDecode(usersJson);
      
      final index = usersList.indexWhere((u) => u['id'] == user.id);
      if (index != -1) {
        final updatedUser = user.copyWith(updatedAt: DateTime.now());
        usersList[index] = updatedUser.toJson();
        await prefs.setString(_usersKey, jsonEncode(usersList));
        await prefs.setString(_currentUserKey, jsonEncode(updatedUser.toJson()));
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    
    // ACTION: Clear the persistent login flag on logout
    await saveLoginState(false);
  }

  // NOTE: The `isLoggedIn` method is now mostly redundant for auto-login,
  // but we keep it here as it was part of your original code.
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}