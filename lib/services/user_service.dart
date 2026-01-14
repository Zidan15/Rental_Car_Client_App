
import 'package:client_app/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  // --- AUTHENTICATION ---

  // Sign Up (Updated to handle auth + profile creation)
  Future<void> signUp(String fullName, String email, String phoneNumber, String address, DateTime dateOfBirth, String password) async {
    try {
      // 1. Create the user in the auth system
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'contact_number': phoneNumber,
          'address': address,
          'dob': dateOfBirth.toIso8601String(),
          'role': 'renter',
        },
      );

      // 2. IMMEDIATELY create the profile in the public.profiles table
      // This bridges the gap between auth.users and public.profiles
      final User? user = res.user;
      if (user != null) {
        // Try to insert. If it fails (e.g. RLS issue because user not logged in yet),
        // we catch it silently so we don't block the signup flow.
        // The fallback in createProfileIfMissing will handle it later.
        try {
          await _supabase.from('profiles').insert({
            'id': user.id,
            'full_name': fullName,
            'contact_number': phoneNumber,
            'address': address,
            'dob': dateOfBirth.toIso8601String(),
            'role': 'renter',
          });
        } catch (insertError) {
          debugPrint('Error inserting profile immediately: $insertError');
        }
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Create Profile if it doesn't exist (fallback for edge cases)
  Future<void> createProfileIfMissing() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return; // No user logged in
      }

      // Check if a profile already exists
      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      // If no profile, create one from auth metadata
      if (existingProfile == null) {
        final fullName = user.userMetadata?['full_name'] ?? '';
        final contactNumber = user.userMetadata?['contact_number'] ?? '';
        final address = user.userMetadata?['address'] ?? '';
        final dob = user.userMetadata?['dob'] ?? '';

        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': fullName,
          'contact_number': contactNumber,
          'address': address,
          'dob': dob,
          'role': 'renter',
        });
      }
    } catch (e) {
      debugPrint('Error in createProfileIfMissing: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Ensure profile exists (handles users who signed up before fix)
      await createProfileIfMissing();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> updateUser(UserModel user) async {
    try {
      // 1. Update 'profiles' table
      await _supabase.from('profiles').update({
        'full_name': user.fullName,
        'contact_number': user.phoneNumber,
        'address': user.address,
        'dob': user.dateOfBirth.toIso8601String(),
      }).eq('id', user.id);

      // 2. Update Auth Metadata (Address, DOB)
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'address': user.address,
            'dob': user.dateOfBirth.toIso8601String(),
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Checks if a user is currently logged in (valid session)
  Future<bool> getLoginState() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  /// Fetches the current user's profile from Supabase
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('getCurrentUser: No auth user found');
        return null;
      }
      
      debugPrint('getCurrentUser: Auth user ID = ${user.id}');

      // Fetch from profiles table
      try {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        debugPrint('getCurrentUser: Profile fetched successfully');
        
        // Convert to UserModel
        return UserModel(
          id: data['id'],
          fullName: data['full_name'] ?? '',
          email: user.email ?? '',
          phoneNumber: data['contact_number'] ?? '',
          address: data['address'] ?? user.userMetadata?['address'] ?? '',
          dateOfBirth: DateTime.tryParse(data['dob'] ?? user.userMetadata?['dob'] ?? '') ?? DateTime.now(),
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: DateTime.now(),
        );
      } catch (profileError) {
        debugPrint('getCurrentUser: Profile fetch failed - $profileError');
        // Return minimal user model with just auth ID so bookings can still be fetched
        return UserModel(
          id: user.id,
          fullName: user.userMetadata?['full_name'] ?? '',
          email: user.email ?? '',
          phoneNumber: user.userMetadata?['contact_number'] ?? '',
          address: user.userMetadata?['address'] ?? '',
          dateOfBirth: DateTime.tryParse(user.userMetadata?['dob'] ?? '') ?? DateTime.now(),
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }
}