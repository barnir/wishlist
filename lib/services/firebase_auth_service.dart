import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wishlist_app/services/user_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  /// Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('=== Firebase Google Sign-In Started ===');
      
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
        return await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint('Google sign-in cancelled by user');
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          await _createOrUpdateUserProfile(userCredential.user!);
          debugPrint('Google sign-in successful: ${userCredential.user!.email}');
        }
        
        return userCredential;
      }
    } catch (e) {
      debugPrint('Firebase Google sign-in error: $e');
      rethrow;
    }
  }

  /// Phone Authentication - Send OTP
  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      debugPrint('=== Firebase Phone OTP Send Started ===');
      debugPrint('Phone number: $phoneNumber');
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Phone verification completed automatically');
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.message}');
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('SMS code sent, verification ID: $verificationId');
          // Store verification ID for later use
          _currentVerificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto-retrieval timeout: $verificationId');
          _currentVerificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('Firebase phone OTP error: $e');
      rethrow;
    }
  }

  String? _currentVerificationId;

  /// Phone Authentication - Verify OTP
  Future<UserCredential?> verifyPhoneOtp(String phoneNumber, String smsCode) async {
    try {
      debugPrint('=== Firebase Phone OTP Verify Started ===');
      debugPrint('SMS Code: $smsCode');
      debugPrint('Verification ID: $_currentVerificationId');

      if (_currentVerificationId == null) {
        throw Exception('No verification ID found. Please request OTP again.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!, phoneNumber: phoneNumber);
        debugPrint('Phone verification successful: ${userCredential.user!.uid}');
      }

      return userCredential;
    } catch (e) {
      debugPrint('Firebase phone verification error: $e');
      rethrow;
    }
  }

  /// Email/Password Sign-Up
  Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      debugPrint('=== Firebase Email Sign-Up Started ===');
      debugPrint('Email: $email');

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await _createOrUpdateUserProfile(userCredential.user!, displayName: displayName);
        debugPrint('Email sign-up successful: ${userCredential.user!.email}');
      }

      return userCredential;
    } catch (e) {
      debugPrint('Firebase email sign-up error: $e');
      rethrow;
    }
  }

  /// Email/Password Sign-In
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('=== Firebase Email Sign-In Started ===');
      debugPrint('Email: $email');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _createOrUpdateUserProfile(userCredential.user!);
        debugPrint('Email sign-in successful: ${userCredential.user!.email}');
      }

      return userCredential;
    } catch (e) {
      debugPrint('Firebase email sign-in error: $e');
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      debugPrint('=== Firebase Sign Out Started ===');
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
      rethrow;
    }
  }

  /// Create or update user profile in Supabase database
  Future<void> _createOrUpdateUserProfile(
    User user, {
    String? phoneNumber,
    String? displayName,
  }) async {
    try {
      debugPrint('=== Syncing Firebase User to Supabase Database ===');
      debugPrint('Firebase UID: ${user.uid}');
      debugPrint('Email: ${user.email}');
      debugPrint('Display Name: ${user.displayName}');
      debugPrint('Phone: ${user.phoneNumber ?? phoneNumber}');

      final existingProfile = await _userService.getUserProfile(user.uid);
      
      final profileData = <String, dynamic>{
        'email': user.email,
        'display_name': displayName ?? user.displayName ?? _extractNameFromEmail(user.email),
        'phone_number': phoneNumber ?? user.phoneNumber,
      };

      if (existingProfile != null) {
        // Update existing profile, preserving existing data
        final updateData = <String, dynamic>{};
        
        // Only update if new data is provided
        if (profileData['email'] != null && profileData['email'] != existingProfile['email']) {
          updateData['email'] = profileData['email'];
        }
        if (profileData['display_name'] != null && profileData['display_name'] != existingProfile['display_name']) {
          updateData['display_name'] = profileData['display_name'];
        }
        if (profileData['phone_number'] != null && profileData['phone_number'] != existingProfile['phone_number']) {
          updateData['phone_number'] = profileData['phone_number'];
        }
        
        if (updateData.isNotEmpty) {
          await _userService.updateUserProfile(user.uid, updateData);
          debugPrint('Updated existing profile with: $updateData');
        }
      } else {
        // Create new profile
        await _userService.createUserProfile(user.uid, profileData);
        debugPrint('Created new profile: $profileData');
      }
    } catch (e) {
      debugPrint('Error syncing user profile to database: $e');
      // Don't rethrow - authentication should succeed even if profile sync fails
    }
  }

  /// Extract display name from email
  String? _extractNameFromEmail(String? email) {
    if (email == null) return null;
    return email.split('@')[0];
  }

  /// Check if user has phone number
  Future<bool> hasPhoneNumber() async {
    final user = currentUser;
    if (user == null) return false;
    
    // Check Firebase user first
    if (user.phoneNumber != null) return true;
    
    // Check Supabase database
    final profile = await _userService.getUserProfile(user.uid);
    return profile != null && 
           profile['phone_number'] != null && 
           profile['phone_number'].toString().isNotEmpty;
  }

  /// Check if user has email
  bool hasEmail() {
    final user = currentUser;
    return user?.email != null && user!.email!.isNotEmpty;
  }
}