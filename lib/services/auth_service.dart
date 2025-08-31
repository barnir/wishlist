import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wishlist_app/services/firebase_auth_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart'; // legacy profile updates gradually migrating
import 'package:wishlist_app/repositories/user_profile_repository.dart';
import 'package:wishlist_app/services/firebase_functions_service.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/services/notification_service.dart';
import 'package:wishlist_app/utils/app_logger.dart';

enum GoogleSignInResult {
  success,
  missingPhoneNumber,
  cancelled,
  failed,
}

/// Firebase-only Auth Service
/// Firebase for Auth, Database, and Cloud Functions, Cloudinary for Images
class AuthService {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();
  final UserProfileRepository _userProfileRepo = UserProfileRepository();
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  firebase_auth.User? get currentUser => _firebaseAuthService.currentUser;

  /// Helper method to get current Firebase user ID (for other services)
  static String? getCurrentUserId() {
    return firebase_auth.FirebaseAuth.instance.currentUser?.uid;
  }

  /// Email/Password Sign-In (Firebase)
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
  logI('Email Sign-In', tag: 'AUTH');
      return await _firebaseAuthService.signInWithEmailAndPassword(email, password);
    } catch (e) {
  logE('Email sign-in error', tag: 'AUTH', error: e);
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
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
  logI('Email Registration', tag: 'AUTH');
      await _validatePassword(password);
      
      if (!_isValidEmail(email)) {
        throw Exception('Formato de email inválido.');
      }
      
      return await _firebaseAuthService.createUserWithEmailAndPassword(email, password, displayName);
    } catch (e) {
  logE('Email registration error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
  logI('Sign Out', tag: 'AUTH');
      
      final userId = currentUser?.uid;
      if (userId != null) {
        await _databaseService.updateUserProfile(userId, {'fcm_token': null});
        await NotificationService().unsubscribeFromUserTopic(userId);
      }
      
      await _firebaseAuthService.signOut();
    } catch (e) {
  logE('Sign out error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  /// Sync existing Firebase user to Firebase database
  Future<void> syncExistingUserProfile() async {
    await _firebaseAuthService.syncExistingUserProfile();
  }

  /// Cancel registration - sign out and clear all stored data
  Future<void> cancelRegistration() async {
    try {
  logI('Cancel Registration', tag: 'AUTH');
      
      // Clear stored data first
      await _firebaseAuthService.clearAllStoredData();
      
      // Then sign out
      await signOut();
      
  logI('Registration cancelled successfully', tag: 'AUTH');
    } catch (e) {
  logE('Cancel registration error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
  logI('Google Sign-In', tag: 'AUTH');
      
      final userCredential = await _firebaseAuthService.signInWithGoogle();
      if (userCredential == null) {
        // Check if user is actually logged in (fallback scenario)
        final user = currentUser;
        if (user == null) {
          return GoogleSignInResult.cancelled;
        }
        
        // User is logged in via fallback, proceed with validation
    final profile = await _userProfileRepo.fetchById(user.uid);
    if (profile == null || 
      profile.phoneNumber == null || 
      profile.phoneNumber!.isEmpty) {
          return GoogleSignInResult.missingPhoneNumber;
        }
        
        await _updateFCMTokenOnSignIn(user.uid);
        return GoogleSignInResult.success;
      }
      
      final user = userCredential.user;
      if (user == null) {
        return GoogleSignInResult.failed;
      }
      
    final profile = await _userProfileRepo.fetchById(user.uid);
    if (profile == null || 
      profile.phoneNumber == null || 
      profile.phoneNumber!.isEmpty) {
        return GoogleSignInResult.missingPhoneNumber;
      }
      
      await _updateFCMTokenOnSignIn(user.uid);
      return GoogleSignInResult.success;
    } catch (e) {
  logE('Google sign-in error', tag: 'AUTH', error: e);
      return GoogleSignInResult.failed;
    }
  }

  Future<void> _updateFCMTokenOnSignIn(String userId) async {
    try {
      final fcmToken = await NotificationService().getDeviceToken();
      if (fcmToken != null) {
        await _databaseService.updateUserProfile(userId, {'fcm_token': fcmToken});
  logD('FCM token updated on sign in', tag: 'AUTH');
      }
    } catch (e) {
  logW('FCM token update error: $e', tag: 'AUTH');
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
  logI('Send Phone OTP', tag: 'AUTH');
      await _firebaseAuthService.sendPhoneOtp(phoneNumber);
    } catch (e) {
  logE('Send phone OTP error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<firebase_auth.UserCredential?> verifyPhoneOtp(String phoneNumber, String otp) async {
    try {
  logI('Verify Phone OTP', tag: 'AUTH');
      
      return await _firebaseAuthService.verifyPhoneOtp(phoneNumber, otp);
    } catch (e) {
  logE('Verify phone OTP error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<void> linkEmailAndPassword(String email, String password) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para vincular o email.');
    }
    try {
  logI('Link Email/Password', tag: 'AUTH');
      
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email, 
        password: password
      );
      
      await user.linkWithCredential(credential);
      await _databaseService.updateUserProfile(user.uid, {'email': email});
    } catch (e) {
  logE('Link email/password error', tag: 'AUTH', error: e);
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
  logI('Update Profile Picture', tag: 'AUTH');
      
      // Get current photo URL before uploading new one for cleanup
      String? oldPhotoUrl;
      try {
        final userDoc = await _databaseService.getUserProfile(user.uid);
        oldPhotoUrl = userDoc?['photo_url'] as String?;
  logD('Current photo URL for cleanup: $oldPhotoUrl', tag: 'AUTH');
      } catch (e) {
  logW('Could not retrieve current photo URL: $e', tag: 'AUTH');
      }
      
      final imageUrl = await _cloudinaryService.uploadProfileImage(
        image, 
        user.uid, 
        oldImageUrl: oldPhotoUrl,
      );
      
      if (imageUrl != null) {
        try {
          // Try to update Firebase Auth profile photo - catch any type cast errors
          await user.updatePhotoURL(imageUrl);
          logI('Firebase Auth photo URL updated successfully', tag: 'AUTH');
        } catch (authError) {
          logW('Firebase Auth photo update failed (continuing anyway): $authError', tag: 'AUTH');
          // Continue execution even if Firebase Auth update fails
        }
        
        // Always update Firestore profile regardless of Firebase Auth result
        await _databaseService.updateUserProfile(user.uid, {'photo_url': imageUrl});
  logI('Profile photo URL saved to Firestore', tag: 'AUTH');
  logD('Old image scheduled for cleanup: $oldPhotoUrl', tag: 'AUTH');
      }
    } catch (e) {
  logE('Update profile picture error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<void> updateUser({String? displayName, String? photoURL}) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para atualizar.');
    }
    
    try {
  logI('Update User', tag: 'AUTH');
      
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
        await _databaseService.updateUserProfile(user.uid, updateData);
      }
    } catch (e) {
  logE('Update user error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('Usuário não logado ou sem e-mail para reautenticação.');
    }
    try {
  logI('Reauthenticate with Password', tag: 'AUTH');
      
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
  logE('Reauthenticate with password error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para reautenticação.');
    }
    try {
  logI('Reauthenticate with Google', tag: 'AUTH');
      
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
  logE('Reauthenticate with Google error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para deletar a conta.');
    }
    
    try {
  logI('Complete Account Deletion', tag: 'AUTH');
  logD('User ID: ${user.uid}', tag: 'AUTH');
      
      // Step 1: Log Cloudinary images that need cleanup (client-side can't delete)
      try {
        final cloudinaryResult = await _cloudinaryService.deleteUserImages(user.uid);
  logI('Cloudinary cleanup result: $cloudinaryResult', tag: 'AUTH');
      } catch (e) {
  logW('Cloudinary cleanup logging failed: $e', tag: 'AUTH');
        // Continue anyway
      }
      
      // Step 2: Delete all Firebase data using Cloud Function
      try {
        await _functionsService.deleteUserAccount();
  logI('Firebase data cleanup completed successfully', tag: 'AUTH');
      } catch (e) {
  logW('Firebase data cleanup failed: $e', tag: 'AUTH');
        // Fallback: try basic profile deletion
        try {
          await _databaseService.deleteUserProfile(user.uid);
        } catch (fallbackError) {
          logW('Fallback deletion also failed: $fallbackError', tag: 'AUTH');
        }
      }
      
      // Step 3: Finally delete Firebase user (this cannot be undone)
  logI('Deleting Firebase user...', tag: 'AUTH');
      await user.delete();
      
  logI('Account deletion completed successfully', tag: 'AUTH');
    } catch (e) {
  logE('Delete account error', tag: 'AUTH', error: e);
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
    
  final profile = await _userProfileRepo.fetchById(user.uid);
  return profile != null && profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty;
  }

  /// Validates if the current user has an email configured
  Future<bool> hasEmail() async {
    final user = currentUser;
    if (user == null) return false;
    
    if (user.email != null && user.email!.isNotEmpty) {
      return true;
    }
    
  final profile = await _userProfileRepo.fetchById(user.uid);
  return profile != null && profile.email != null && profile.email!.isNotEmpty;
  }

  /// Check if a user's registration is complete based on the profile flag
  Future<bool> isRegistrationComplete() async {
    final user = currentUser;
    if (user == null) return false;
    
    try {
  final profile = await _userProfileRepo.fetchById(user.uid);
  final map = profile?.toMap();
  return map != null && map['registration_complete'] == true;
    } catch (e) {
      debugPrint('Error checking registration status: $e');
      return false;
    }
  }

  /// Detects and handles orphaned Firebase Auth accounts (exist in Auth but not in Firestore)
  /// 
  /// Improved to differentiate between accounts in registration process and truly orphaned accounts.
  Future<bool> isOrphanedAccount() async {
    final user = currentUser;
    if (user == null) return false;
    
    try {
  final profile = await _userProfileRepo.fetchById(user.uid);
  if (profile != null) return false; // exists
      
      // Special case: Email registration in progress (< 10 minutes old)
      if (user.email != null && user.metadata.creationTime != null) {
        final accountAge = DateTime.now().difference(user.metadata.creationTime!);
        // If account was created less than 10 minutes ago and has email, 
        // it's likely in the registration flow (waiting for phone verification)
        if (accountAge.inMinutes < 10) {
              logD('New email registration in progress (${accountAge.inMinutes}m old), not orphaned', tag: 'AUTH');
              logD('User ID: ${user.uid}', tag: 'AUTH');
              logD('Email: ${user.email}', tag: 'AUTH');
              logD('Created: ${user.metadata.creationTime}', tag: 'AUTH');
          return false;
        }
      }
      
      // Otherwise, truly orphaned
  logW('Orphaned account detected: Auth user exists but no Firestore profile', tag: 'AUTH');
  logD('User ID: ${user.uid}', tag: 'AUTH');
  logD('Email: ${user.email}', tag: 'AUTH');
  logD('Phone: ${user.phoneNumber}', tag: 'AUTH');
      
      return true;
    } catch (e) {
  logE('Error checking orphaned account', tag: 'AUTH', error: e);
      return true; // Assume orphaned if we can't check
    }
  }

  /// Cleans up orphaned Firebase Auth account by deleting it
  Future<void> cleanupOrphanedAccount() async {
    final user = currentUser;
    if (user == null) return;
    
    try {
  logI('Cleaning up orphaned Firebase Auth account', tag: 'AUTH');
  logD('User ID: ${user.uid}', tag: 'AUTH');
  logD('Email: ${user.email}', tag: 'AUTH');
      
      await user.delete();
  logI('Orphaned Firebase Auth account deleted successfully', tag: 'AUTH');
      
    } catch (e) {
  logE('Error cleaning up orphaned account', tag: 'AUTH', error: e);
      rethrow;
    }
  }
}