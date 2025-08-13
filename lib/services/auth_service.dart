import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/services/supabase_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:wishlist_app/services/user_service.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final SupabaseStorageService _supabaseStorageService = SupabaseStorageService();
  final UserService _userService = UserService();

  Stream<User?> get authStateChanges => _supabaseClient.auth.onAuthStateChange.map((data) => data.session?.user);

  User? get currentUser => _supabaseClient.auth.currentUser;

  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        // TODO: Handle user profile creation/update in Supabase database
        // For now, assuming user profile is handled by Supabase's default user management
      }
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<AuthResponse> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        // TODO: Handle user profile creation/update in Supabase database
      }
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  // --- Methods to be refactored or re-evaluated for Supabase --- 

  Future<AuthResponse> signInWithGoogle() async {
    // Supabase Google Sign-In usually involves a redirect or deep link.
    // This will require platform-specific setup.
    // For now, a basic OAuth call:
    try {
      final AuthResponse response = await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(AuthCredential) verificationCompleted,
    required void Function(AuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    // Supabase phone auth uses signInWithOtp and verifyOtp
    // This method needs significant refactoring.
    throw UnimplementedError('Phone number verification not yet implemented for Supabase.');
  }

  Future<void> signInWithPhoneCredential(AuthCredential credential) async {
    throw UnimplementedError('Phone sign-in not yet implemented for Supabase.');
  }

  Future<void> linkPhoneNumber(AuthCredential credential) async {
    throw UnimplementedError('Linking phone number not yet implemented for Supabase.');
  }

  Future<void> linkEmailAndPassword(String email, String password) async {
    throw UnimplementedError('Linking email and password not yet implemented for Supabase.');
  }

  Future<void> linkGoogle() async {
    throw UnimplementedError('Linking Google not yet implemented for Supabase.');
  }

  Future<void> updateProfilePicture(File image) async {
    final imageUrl = await _supabaseStorageService.uploadImage(image, 'avatars');
    if (imageUrl != null) {
      await _supabaseClient.auth.updateUser(UserAttributes(data: {'photoURL': imageUrl}));
    }
  }

  Future<void> reloadUser() async {
    // Supabase user object is usually up-to-date after an auth event.
    // No direct equivalent for Firebase's reloadUser.
  }

  Future<void> reauthenticateWithPassword(String password) async {
    throw UnimplementedError('Reauthentication with password not yet implemented for Supabase.');
  }

  Future<void> reauthenticateWithGoogle() async {
    throw UnimplementedError('Reauthentication with Google not yet implemented for Supabase.');
  }

  Future<void> deleteAccount() async {
    // This will involve deleting the user from Supabase Auth and then deleting their data from the Supabase database.
    // Supabase does not have a direct client-side delete user method for security reasons.
    // This usually requires a server-side function or RLS policies.
    throw UnimplementedError('Account deletion not yet implemented for Supabase.');
  }
}