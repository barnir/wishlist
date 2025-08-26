import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wishlist_app/services/firebase_auth_service.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/services/user_service.dart';
import 'package:wishlist_app/services/supabase_functions_service.dart';
import 'package:wishlist_app/services/notification_service.dart';

enum GoogleSignInResult {
  success,
  missingPhoneNumber,
  cancelled,
  failed,
}

/// Wrapper around FirebaseAuthService to maintain compatibility
/// Firebase for Auth, Supabase for Database, Cloudinary for Images
class AuthService {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final UserService _userService = UserService();
  final SupabaseFunctionsService _supabaseFunctionsService = SupabaseFunctionsService();

  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  firebase_auth.User? get currentUser => _firebaseAuthService.currentUser;

  /// Helper method to get current Firebase user ID (for other services)
  static String? getCurrentUserId() {
    return firebase_auth.FirebaseAuth.instance.currentUser?.uid;
  }

  /// Email/Password Sign-In (Firebase)
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('=== AuthService: Email Sign-In ===');
      return await _firebaseAuthService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      debugPrint('AuthService email sign-in error: $e');
      rethrow;
    }
  }

  Future<void> _validatePassword(String password) async {
    if (password.length < 6) {
      throw Exception('A senha deve ter no mínimo 6 caracteres.');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      throw Exception('A senha deve conter pelo menos uma letra minúscula.');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw Exception('A senha deve conter pelo menos uma letra maiúscula.');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw Exception('A senha deve conter pelo menos um número.');
    }
    if (!password.contains(RegExp(r'[!@#\\$%^&*(),.?\":{}|<>]'))) {
      throw Exception('A senha deve conter pelo menos um símbolo.');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      debugPrint('=== AuthService: Email Registration ===');
      await _validatePassword(password);
      
      if (!_isValidEmail(email)) {
        throw Exception('Formato de email inválido.');
      }
      
      return await _firebaseAuthService.createUserWithEmailAndPassword(email, password, displayName);
    } catch (e) {
      debugPrint('AuthService email registration error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('=== AuthService: Sign Out ===');
      
      final userId = currentUser?.uid;
      if (userId != null) {
        await _userService.updateFCMToken(userId, null);
        await NotificationService().unsubscribeFromUserTopic(userId);
      }
      
      await _firebaseAuthService.signOut();
    } catch (e) {
      debugPrint('AuthService sign out error: $e');
      rethrow;
    }
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      debugPrint('=== AuthService: Google Sign-In ===');
      
      final userCredential = await _firebaseAuthService.signInWithGoogle();
      if (userCredential == null) {
        // Check if user is actually logged in (fallback scenario)
        final user = currentUser;
        if (user == null) {
          return GoogleSignInResult.cancelled;
        }
        
        // User is logged in via fallback, proceed with validation
        final profile = await _userService.getUserProfile(user.uid);
        if (profile == null || 
            profile['phone_number'] == null || 
            profile['phone_number'].toString().isEmpty) {
          return GoogleSignInResult.missingPhoneNumber;
        }
        
        await _updateFCMTokenOnSignIn(user.uid);
        return GoogleSignInResult.success;
      }
      
      final user = userCredential.user;
      if (user == null) {
        return GoogleSignInResult.failed;
      }
      
      final profile = await _userService.getUserProfile(user.uid);
      if (profile == null || 
          profile['phone_number'] == null || 
          profile['phone_number'].toString().isEmpty) {
        return GoogleSignInResult.missingPhoneNumber;
      }
      
      await _updateFCMTokenOnSignIn(user.uid);
      return GoogleSignInResult.success;
    } catch (e) {
      debugPrint('AuthService Google sign-in error: $e');
      return GoogleSignInResult.failed;
    }
  }

  Future<void> _updateFCMTokenOnSignIn(String userId) async {
    try {
      final fcmToken = await NotificationService().getDeviceToken();
      if (fcmToken != null) {
        await _userService.updateFCMToken(userId, fcmToken);
        debugPrint('AuthService: FCM token updated on sign in');
      }
    } catch (e) {
      debugPrint('AuthService: FCM token update error: $e');
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      debugPrint('=== AuthService: Send Phone OTP ===');
      await _firebaseAuthService.sendPhoneOtp(phoneNumber);
    } catch (e) {
      debugPrint('AuthService send phone OTP error: $e');
      rethrow;
    }
  }

  Future<firebase_auth.UserCredential?> verifyPhoneOtp(String phoneNumber, String otp) async {
    try {
      debugPrint('=== AuthService: Verify Phone OTP ===');
      
      return await _firebaseAuthService.verifyPhoneOtp(phoneNumber, otp);
    } catch (e) {
      debugPrint('AuthService verify phone OTP error: $e');
      rethrow;
    }
  }

  Future<void> linkEmailAndPassword(String email, String password) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para vincular o email.');
    }
    try {
      debugPrint('=== AuthService: Link Email/Password ===');
      
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email, 
        password: password
      );
      
      await user.linkWithCredential(credential);
      await _userService.updateUserProfile(user.uid, {'email': email});
    } catch (e) {
      debugPrint('AuthService link email/password error: $e');
      rethrow;
    }
  }

  Future<void> linkGoogle() async {
    throw UnimplementedError('Linking Google is a complex operation that typically requires server-side logic for proper account merging.');
  }

  Future<void> updateProfilePicture(File image) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para atualizar foto de perfil.');
    }
    
    try {
      debugPrint('=== AuthService: Update Profile Picture ===');
      
      final imageUrl = await _cloudinaryService.uploadProfileImage(image, user.uid);
      if (imageUrl != null) {
        await user.updatePhotoURL(imageUrl);
        await _userService.updateUserProfile(user.uid, {'photo_url': imageUrl});
      }
    } catch (e) {
      debugPrint('AuthService update profile picture error: $e');
      rethrow;
    }
  }

  Future<void> updateUser({String? displayName, String? photoURL}) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para atualizar.');
    }
    
    try {
      debugPrint('=== AuthService: Update User ===');
      
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['display_name'] = displayName;
      if (photoURL != null) updateData['photo_url'] = photoURL;
      
      if (updateData.isNotEmpty) {
        await _userService.updateUserProfile(user.uid, updateData);
      }
    } catch (e) {
      debugPrint('AuthService update user error: $e');
      rethrow;
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('Usuário não logado ou sem e-mail para reautenticação.');
    }
    try {
      debugPrint('=== AuthService: Reauthenticate with Password ===');
      
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      debugPrint('AuthService reauthenticate with password error: $e');
      rethrow;
    }
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para reautenticação.');
    }
    try {
      debugPrint('=== AuthService: Reauthenticate with Google ===');
      
      // Android-only Google reauthentication
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('A reautenticação com o Google foi cancelada.');
      }
      
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      debugPrint('AuthService reauthenticate with Google error: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para deletar a conta.');
    }
    
    try {
      debugPrint('=== AuthService: Complete Account Deletion ===');
      debugPrint('User ID: ${user.uid}');
      
      // Step 1: Log Cloudinary images that need cleanup (client-side can't delete)
      try {
        final cloudinaryResult = await _cloudinaryService.deleteUserImages(user.uid);
        debugPrint('Cloudinary cleanup result: $cloudinaryResult');
      } catch (e) {
        debugPrint('Warning: Cloudinary cleanup logging failed: $e');
        // Continue anyway
      }
      
      // Step 2: Delete all Supabase data using edge function
      try {
        final supabaseResult = await _supabaseFunctionsService.deleteUser();
        debugPrint('Supabase cleanup result: $supabaseResult');
        
        if (!supabaseResult['success']) {
          debugPrint('Warning: Supabase cleanup failed: ${supabaseResult['error']}');
          // Continue with Firebase deletion anyway to avoid user being stuck
        }
      } catch (e) {
        debugPrint('Warning: Supabase cleanup failed: $e');
        // Fallback: try basic profile deletion
        try {
          await _userService.deleteUserProfile(user.uid);
        } catch (fallbackError) {
          debugPrint('Fallback deletion also failed: $fallbackError');
        }
      }
      
      // Step 3: Finally delete Firebase user (this cannot be undone)
      debugPrint('Deleting Firebase user...');
      await user.delete();
      
      debugPrint('Account deletion completed successfully');
    } catch (e) {
      debugPrint('AuthService delete account error: $e');
      rethrow;
    }
  }

  /// Validates if the current user has a phone number configured
  Future<bool> hasPhoneNumber() async {
    final user = currentUser;
    if (user == null) return false;
    
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return true;
    }
    
    final profile = await _userService.getUserProfile(user.uid);
    return profile != null && 
           profile['phone_number'] != null && 
           profile['phone_number'].toString().isNotEmpty;
  }

  /// Validates if the current user has an email configured
  Future<bool> hasEmail() async {
    final user = currentUser;
    if (user == null) return false;
    
    if (user.email != null && user.email!.isNotEmpty) {
      return true;
    }
    
    final profile = await _userService.getUserProfile(user.uid);
    return profile != null && 
           profile['email'] != null && 
           profile['email'].toString().isNotEmpty;
  }
}