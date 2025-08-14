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

  Future<void> signInWithGoogle() async {
    // Supabase Google Sign-In usually involves a redirect or deep link.
    // This will require platform-specific setup.
    // For now, a basic OAuth call:
    try {
      await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.example.wishlist_app://login-callback/',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
        phone: phoneNumber,
        channel: OtpChannel.whatsapp,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<AuthResponse> verifyPhoneOtp(String phoneNumber, String otp) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // This method is now simplified to use verifyPhoneOtp directly
  Future<void> signInWithPhoneCredential(String phoneNumber, String otp) async {
    await verifyPhoneOtp(phoneNumber, otp);
  }

  Future<void> linkPhoneNumber(String phoneNumber, String otp) async {
    // Supabase does not have a direct 'link' method for phone like Firebase.
    // You would typically sign in the user with phone, and then update their profile
    // in your 'users' table with the phone number.
    await verifyPhoneOtp(phoneNumber, otp);
    if (currentUser != null) {
      await _userService.updateUserProfile(currentUser!.id, {'phone_number': phoneNumber});
    }
  }

  Future<void> linkEmailAndPassword(String email, String password) async {
    if (currentUser == null) {
      throw Exception('Nenhum usuário logado para vincular o email.');
    }
    try {
      // Supabase's updateUser can change email and password.
      // This effectively 'links' an email/password if they didn't have one, or changes it.
      await _supabaseClient.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
        ),
      );
      // Optionally, update the email in the public.users table if it's stored there
      await _userService.updateUserProfile(currentUser!.id, {'email': email});
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> linkGoogle() async {
    // Supabase does not have a direct 'link' method for OAuth providers like Firebase.
    // If a user is already signed in with another method and then signs in with Google,
    // Supabase will create a new user entry for the Google account.
    // To truly 'link' them, you would need to:
    // 1. Identify that the user is already logged in (currentUser != null).
    // 2. Perform the Google OAuth (signInWithOAuth).
    // 3. If a new user is created by Google OAuth, you would then need to:
    //    a. Decide how to merge these accounts (e.g., transfer data from the new Google user's profile to the existing user's profile in your public.users table).
    //    b. Delete the newly created Google-linked user from auth.users (requires admin privileges, so an Edge Function is recommended).
    //    c. Update the existing user's user_metadata to include the Google provider information (e.g., Google ID, email).
    // This is a complex scenario that typically requires server-side logic (e.g., a Supabase Edge Function).
    throw UnimplementedError('Linking Google is a complex operation that typically requires server-side logic for proper account merging.');
  }

  Future<void> updateProfilePicture(File image) async {
    final imageUrl = await _supabaseStorageService.uploadImage(image, 'avatars');
    if (imageUrl != null) {
      await _supabaseClient.auth.updateUser(UserAttributes(data: {'photoURL': imageUrl}));
    }
  }

  // New method to update user metadata (e.g., display name)
  Future<void> updateUser({String? displayName, String? photoURL}) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(
        data: {
          if (displayName != null) 'display_name': displayName,
          if (photoURL != null) 'photoURL': photoURL,
        },
      ),
    );
  }

  Future<void> reloadUser() async {
    // Supabase user object is usually up-to-date after an auth event.
    // No direct equivalent for Firebase's reloadUser.
  }

  Future<void> reauthenticateWithPassword(String password) async {
    if (currentUser == null || currentUser!.email == null) {
      throw Exception('Usuário não logado ou sem e-mail para reautenticação.');
    }
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: currentUser!.email!,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> reauthenticateWithGoogle() async {
    if (currentUser == null) {
      throw Exception('Nenhum usuário logado para reautenticação.');
    }
    try {
      await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.example.wishlist_app://login-callback/',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteAccount() async {
    if (currentUser == null) {
      throw Exception('Nenhum usuário logado para deletar a conta.');
    }
    // Supabase does not have a direct client-side delete user method for security reasons.
    // This operation typically requires admin privileges and should be handled by a server-side function (e.g., a Supabase Edge Function).
    // The Edge Function would:
    // 1. Verify the user's identity (e.g., by checking their JWT).
    // 2. Delete the user from auth.users.
    // 3. Delete associated data from public tables (e.g., users, wishlists, wish_items) - this can be handled by RLS and cascading deletes if set up correctly.
    throw UnimplementedError('Account deletion requires a server-side function for security reasons.');
  }
}