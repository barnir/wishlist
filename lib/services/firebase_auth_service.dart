import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed legacy firebase_database_service usage for profiles
import 'package:wishlist_app/repositories/user_profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/utils/app_logger.dart';

/// Structured result for phone verification (Android only)
/// success: phone linked / verified
/// alreadyLinked: provider already linked (idempotent success)
/// invalidCode: wrong or expired SMS code
/// codeExpired: session / code expired (request resend)
/// phoneInUse: phone already linked to different account
/// internalError: unexpected failure
enum PhoneVerificationResult {
  success,
  alreadyLinked,
  invalidCode,
  codeExpired,
  phoneInUse,
  internalError,
}

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserProfileRepository _userProfileRepo = UserProfileRepository();
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // Use singleton instance per v7 API
    final signIn = GoogleSignIn.instance;
    await signIn.initialize();
    // Start lightweight auth attempt (may or may not return a Future)
    try {
      final future = signIn.attemptLightweightAuthentication();
      if (future is Future) {
        await future; // Only await if a future was returned (non-web)
      }
    } catch (_) {
      // Non-fatal
    }
    _googleInitialized = true;
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  // Legacy inline logger removed; using centralized appLog helpers.

  /// Google Sign-In with fallback for type casting errors
  Future<UserCredential?> signInWithGoogle() async {
    try {
  logI('Google Sign-In started', tag: 'AUTH');
      
      await _ensureGoogleInitialized();
      final signIn = GoogleSignIn.instance;

      GoogleSignInAccount? googleUser;
      try {
        if (signIn.supportsAuthenticate()) {
          googleUser = await signIn.authenticate();
        } else {
          // attemptLightweightAuthentication already run in initializer; if it returned a user it would have been via Future
          final attempt = signIn.attemptLightweightAuthentication();
          if (attempt is Future<GoogleSignInAccount?>) {
            googleUser = await attempt;
          }
        }
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          logI('Google sign-in cancelled by user', tag: 'AUTH');
          return null;
        }
        rethrow;
      }

      if (googleUser == null) {
        logI('No Google user obtained', tag: 'AUTH');
        return null;
      }

      final tokenData = googleUser.authentication; // Provides idToken only in v7
      final credential = GoogleAuthProvider.credential(
        idToken: tokenData.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
  logI('Google sign-in successful: ${userCredential.user!.email}', tag: 'AUTH');
  logW('Profile NOT created yet - waiting for phone number', tag: 'AUTH');
        
        // Clear any old OTP verification data for fresh start
        await _clearVerificationData();
  logD('Cleared old OTP verification data for fresh user', tag: 'OTP');
      }
      
      return userCredential;
    } catch (e) {
  logE('Google sign-in error', tag: 'AUTH', error: e);
  logD('Current user after error: ${_firebaseAuth.currentUser?.email}', tag: 'AUTH');
      
      // Check if user is actually logged in despite the error
      if (_firebaseAuth.currentUser != null) {
  logW('Error occurred but user is logged in - fallback path', tag: 'AUTH');
        final user = _firebaseAuth.currentUser!;
        
        try {
          logI('Fallback: User authenticated successfully', tag: 'AUTH');
          logI('Fallback Google sign-in successful: ${user.email}', tag: 'AUTH');
          logW('Fallback: Profile NOT created yet - waiting for phone number', tag: 'AUTH');
          
          // Clear any old OTP verification data for fresh start
          await _clearVerificationData();
          logD('Cleared old OTP verification data (fallback)', tag: 'OTP');
          
          // Return null to indicate successful login, auth_service.dart will handle this
          return null;
        } catch (profileError) {
          logE('Fallback profile creation failed', tag: 'AUTH', error: profileError);
          rethrow;
        }
      }
      
      rethrow;
    }
  }

  /// Phone Authentication - Send OTP
  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
  logI('Phone OTP send started', tag: 'OTP');
  logD('Phone number: $phoneNumber | len=${phoneNumber.length}', tag: 'OTP');
      if (_lastOtpSentAt != null) {
        final diff = DateTime.now().difference(_lastOtpSentAt!);
        if (diff < _otpResendMinInterval) {
          final wait = _otpResendMinInterval - diff;
          throw Exception('Aguarde ${wait.inSeconds}s para reenviar o código.');
        }
      }
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 40),
        verificationCompleted: (PhoneAuthCredential credential) async {
          logI('Phone verification auto-complete', tag: 'OTP');
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            if (userCredential.user != null) {
              logI('Auto-verification success: ${userCredential.user!.uid}', tag: 'OTP');
              await _createOrUpdateUserProfile(userCredential.user!, phoneNumber: phoneNumber);
              await _userProfileRepo.update(userCredential.user!.uid, {'phone_verified': true});
              await _clearVerificationData();
            }
          } catch (e) {
            logW('Error in verificationCompleted: $e', tag: 'OTP');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          logE('Phone verification failed: ${e.code} - ${e.message}', tag: 'OTP');
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          logI('SMS code sent', tag: 'OTP');
          logD('verificationId=$verificationId resendToken=$resendToken phone=$phoneNumber', tag: 'OTP');
          _resendToken = resendToken;
          _lastOtpSentAt = DateTime.now();
          _currentVerificationId = verificationId;
          await _storeVerificationId(verificationId, phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) async {
          logW('Auto-retrieval timeout: $verificationId', tag: 'OTP');
          _currentVerificationId = verificationId;
          await _storeVerificationId(verificationId, phoneNumber);
        },
      );
    } catch (e) {
  logE('Phone OTP send error (type ${e.runtimeType})', tag: 'OTP', error: e);
      rethrow;
    }
  }

  String? _currentVerificationId;
  static const String _verificationIdKey = 'phone_verification_id';
  static const String _phoneNumberKey = 'phone_verification_number';
  int? _resendToken; // Firebase resend token (Android)
  DateTime? _lastOtpSentAt; // Timestamp of last OTP sent
  static const Duration _otpResendMinInterval = Duration(seconds: 20);

  /// Phone Authentication - Verify OTP
  Future<UserCredential?> verifyPhoneOtp(String phoneNumber, String smsCode) async {
    try {
  logI('Phone OTP verify started', tag: 'OTP');
  logD('phone=$phoneNumber codeLen=${smsCode.length} verId=$_currentVerificationId', tag: 'OTP');

      if (_currentVerificationId == null) {
        // Try to retrieve from persistent storage
        _currentVerificationId = await _getStoredVerificationId();
        if (_currentVerificationId == null) {
          logE('No verification ID found (memory/storage)', tag: 'OTP');
          throw Exception('No verification ID found. Please request OTP again.');
        }
  logD('Retrieved verification ID from storage: $_currentVerificationId', tag: 'OTP');
      }

  logD('Creating PhoneAuthCredential verId=$_currentVerificationId codeLen=${smsCode.length}', tag: 'OTP');

      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId!,
        smsCode: smsCode,
      );

  logD('Credential created', tag: 'OTP');
      
      final currentUser = _firebaseAuth.currentUser;
      UserCredential? userCredential;
      
      if (currentUser != null) {
  logD('Current user exists - attempting linking (uid=${currentUser.uid})', tag: 'OTP');
  logD('Providers: ${currentUser.providerData.map((p) => p.providerId).join(", ")}', tag: 'OTP');
        
    try {
          userCredential = await currentUser.linkWithCredential(credential);
          logI('Linking successful uid=${userCredential.user?.uid}', tag: 'OTP');
          logD('Updated providers: ${userCredential.user?.providerData.map((p) => p.providerId).join(", ")}', tag: 'OTP');
        } catch (linkError) {
          logW('Linking failed: $linkError', tag: 'OTP');
          
          if (linkError is FirebaseAuthException && linkError.code == 'provider-already-linked') {
            logI('Provider already linked (phone already present)', tag: 'OTP');
            // Continue with profile update using current user
            await _createOrUpdateUserProfile(currentUser, phoneNumber: phoneNumber);
            await _userProfileRepo.update(currentUser.uid, {'phone_verified': true});
            await _clearVerificationData();
            logI('Phone verification success (already linked): ${currentUser.uid}', tag: 'OTP');
            return null;
          } else if (linkError is FirebaseAuthException && linkError.code == 'credential-already-in-use') {
            logW('Phone number in use by another account (merge needed)', tag: 'OTP');
            throw Exception('Este número de telefone já está associado a outra conta. Por favor, use um número diferente ou faça login com a conta existente.');
          }
          
          // Check if linking actually succeeded despite the casting error
          final updatedUser = _firebaseAuth.currentUser;
          if (updatedUser != null && updatedUser.phoneNumber == phoneNumber) {
            logI('Linking fallback succeeded uid=${updatedUser.uid}', tag: 'OTP');
            logD('Updated providers: ${updatedUser.providerData.map((p) => p.providerId).join(", ")}', tag: 'OTP');
            
            // Create user profile for successful linking
            await _createOrUpdateUserProfile(updatedUser, phoneNumber: phoneNumber);
            await _userProfileRepo.update(updatedUser.uid, {'phone_verified': true});
            await _clearVerificationData();
            
            logI('Phone verification success via linking fallback: ${updatedUser.uid}', tag: 'OTP');
            return null; // Return null to indicate success via fallback
          }
          
          rethrow;
        }
      } else {
  logD('No current user - signInWithCredential path', tag: 'OTP');
        
        try {
          userCredential = await _firebaseAuth.signInWithCredential(credential);
          logI('Sign-in success phone-only uid=${userCredential.user?.uid}', tag: 'OTP');
        } catch (credentialError) {
          logW('signInWithCredential error: $credentialError', tag: 'OTP');
          
          // Check if user is actually signed in despite the error (common Firebase plugin issue)
          final nowCurrentUser = _firebaseAuth.currentUser;
          if (nowCurrentUser != null) {
            logI('Fallback: user signed in despite credential error uid=${nowCurrentUser.uid}', tag: 'OTP');
            
            // Create user profile for successful linking
            await _createOrUpdateUserProfile(nowCurrentUser, phoneNumber: phoneNumber);
            await _userProfileRepo.update(nowCurrentUser.uid, {'phone_verified': true});
            await _clearVerificationData();
            
            logI('Phone verification success via fallback: ${nowCurrentUser.uid}', tag: 'OTP');
            return null; // Return null to indicate success via fallback
          }
          
          rethrow; // If user is not signed in, rethrow the original error
        }
      }
      
      if (userCredential.user != null) {
  logI('Phone verification success: ${userCredential.user!.uid}', tag: 'OTP');
        
        // Check if this is completing an email registration
  final profileObj = await _userProfileRepo.fetchById(userCredential.user!.uid);
  if (profileObj != null && profileObj.registrationComplete == false) {
          logD('Completing email registration adding phone', tag: 'OTP');
          await _userProfileRepo.update(userCredential.user!.uid, {
            'phone_number': phoneNumber,
            'registration_complete': true,
            'phone_verified': true,
          });
          logI('Email registration completed (phone added)', tag: 'OTP');
  } else if (profileObj == null) {
          logW('No profile after phone verification – creating new', tag: 'OTP');
          // Create complete profile if missing entirely
          final profileData = {
            'email': userCredential.user!.email,
            'display_name': userCredential.user!.displayName ?? _extractNameFromEmail(userCredential.user!.email),
            'phone_number': phoneNumber,
            'is_private': false,  // Default to public profile
            'registration_complete': true,
            'phone_verified': true,
          };
          await _userProfileRepo.create(userCredential.user!.uid, profileData);
          logI('Created complete profile after phone verification', tag: 'OTP');
        } else {
          // Normal phone verification flow
          await _createOrUpdateUserProfile(userCredential.user!, phoneNumber: phoneNumber);
          await _userProfileRepo.update(userCredential.user!.uid, {'phone_verified': true});
        }
        
        await _clearVerificationData(); // Clear stored verification data after success
      } else {
  logW('User credential null after verification', tag: 'OTP');
      }

      return userCredential;
    } catch (e) {
  logE('Phone verification error (type ${e.runtimeType})', tag: 'OTP', error: e);
      
      if (e is FirebaseAuthException) {
  logD('Auth error code=${e.code} message=${e.message}', tag: 'OTP');
        
        if (e.code == 'invalid-verification-code') {
          logW('Invalid verification code (possible expiry)', tag: 'OTP');
        }
      }
      
      rethrow;
    }
  }

  /// Enhanced phone verification returning a structured enum result
  Future<PhoneVerificationResult> verifyPhoneOtpEnhanced(String phoneNumber, String smsCode) async {
    try {
  await verifyPhoneOtp(phoneNumber, smsCode);
  logD('Enhanced verification success', tag: 'OTP');
  // Any non-exception path is success (including null fallback path)
      return PhoneVerificationResult.success;
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            return PhoneVerificationResult.invalidCode;
          case 'session-expired':
          case 'code-expired':
            return PhoneVerificationResult.codeExpired;
          case 'credential-already-in-use':
            return PhoneVerificationResult.phoneInUse;
        }
      }
      return PhoneVerificationResult.internalError;
    }
  }

  /// Resend OTP using stored forceResendingToken (Android only optimization)
  Future<void> resendPhoneOtp(String phoneNumber) async {
    // If no token yet, fallback to normal send
    if (_resendToken == null) {
      await sendPhoneOtp(phoneNumber);
      return;
    }
    if (_lastOtpSentAt != null) {
      final diff = DateTime.now().difference(_lastOtpSentAt!);
      if (diff < _otpResendMinInterval) {
        final wait = _otpResendMinInterval - diff;
        throw Exception('Aguarde ${wait.inSeconds}s para reenviar o código.');
      }
    }
    try {
  logI('Phone OTP resend started (force token)', tag: 'OTP');
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 40),
        verificationCompleted: (PhoneAuthCredential credential) async {
          logI('Auto verification triggered on resend', tag: 'OTP');
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _createOrUpdateUserProfile(userCredential.user!, phoneNumber: phoneNumber);
              await _userProfileRepo.update(userCredential.user!.uid, {'phone_verified': true});
              await _clearVerificationData();
            }
          } catch (e) {
            logW('Auto verification (resend) error: $e', tag: 'OTP');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          logE('Phone verification resend failed: ${e.code} - ${e.message}', tag: 'OTP');
          throw Exception('Falha no reenvio: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          logI('Resend SMS code sent', tag: 'OTP');
          _currentVerificationId = verificationId;
          _resendToken = resendToken ?? _resendToken;
          _lastOtpSentAt = DateTime.now();
          await _storeVerificationId(verificationId, phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) async {
          _currentVerificationId = verificationId;
          await _storeVerificationId(verificationId, phoneNumber);
        },
      );
    } catch (e) {
  logE('Phone OTP resend error', tag: 'OTP', error: e);
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
  logI('Email Sign-Up started', tag: 'AUTH');
  logD('Email: $email', tag: 'AUTH');

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
  logI('Email sign-up success: ${userCredential.user!.email}', tag: 'AUTH');
        
        // Create a temporary minimal user profile to prevent orphaned account detection
        // This profile will be updated when phone verification is completed
  await _userProfileRepo.create(userCredential.user!.uid, {
          'email': email,
            // Nome inicial já fornecido no ecrã de registo, pode ser ajustado depois
          'display_name': displayName,
          'phone_number': null, // Explicita ausência até verificação
          'phone_verified': false,
          'registration_complete': false,  // Fluxo ainda não terminado (aguarda telefone)
          'is_private': false,  // Perfil público por default (padrão atual da app)
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        
  logD('Temporary user profile created (awaiting phone)', tag: 'AUTH');
      }

      return userCredential;
    } catch (e, stackTrace) {
  logE('Email sign-up error (type ${e.runtimeType})', tag: 'AUTH', error: e, stackTrace: stackTrace);
      
      if (e is FirebaseAuthException) {
  logD('Auth error code=${e.code} message=${e.message}', tag: 'AUTH');
      }
      
      rethrow;
    }
  }

  /// Email/Password Sign-In
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
  logI('Email Sign-In started', tag: 'AUTH');
  logD('Email: $email', tag: 'AUTH');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
  logI('Email sign-in success: ${userCredential.user!.email}', tag: 'AUTH');
  logW('Profile NOT created yet - waiting for phone number', tag: 'AUTH');
      }

      return userCredential;
    } catch (e) {
  logE('Email sign-in error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
  logI('Firebase Sign Out started', tag: 'AUTH');
  try { await GoogleSignIn.instance.signOut(); } catch (_) {}
      await _firebaseAuth.signOut();
  logI('Firebase sign out success', tag: 'AUTH');
    } catch (e) {
  logE('Firebase sign out error', tag: 'AUTH', error: e);
      rethrow;
    }
  }

  /// Create or update user profile in Firebase database
  Future<void> _createOrUpdateUserProfile(
    User user, {
    String? phoneNumber,
    String? displayName,
  }) async {
    try {
  logI('Sync user to DB (enhanced)', tag: 'PROFILE');
  logD('uid=${user.uid} email=${user.email} phone=${user.phoneNumber ?? phoneNumber}', tag: 'PROFILE');

  logD('Check existing profile', tag: 'PROFILE');
  final existingProfileProfile = await _userProfileRepo.fetchById(user.uid);
  final existingProfile = existingProfileProfile?.toMap();
  logD('Existing profile found=${existingProfile != null}', tag: 'PROFILE');
      
      final profileData = <String, dynamic>{
        'email': user.email,
        'display_name': displayName ?? user.displayName ?? _extractNameFromEmail(user.email),
        'phone_number': phoneNumber ?? user.phoneNumber,
        'is_private': false,  // Default to public profile
        'registration_complete': true,  // Mark registration as complete
      };
  logD('Profile sync data prepared', tag: 'PROFILE');

      if (existingProfile != null) {
  logD('Profile exists - evaluating updates', tag: 'PROFILE');
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
        
  logD('Update diff: $updateData', tag: 'PROFILE');
        
        if (updateData.isNotEmpty) {
          logD('Calling updateUserProfile', tag: 'PROFILE');
          await _userProfileRepo.update(user.uid, updateData);
          logI('Profile updated', tag: 'PROFILE');
        } else {
          logD('No profile changes needed', tag: 'PROFILE');
        }
      } else {
  logD('No existing profile - creating new', tag: 'PROFILE');
  await _userProfileRepo.create(user.uid, profileData);
  logI('New profile created', tag: 'PROFILE');
      }
      
  logI('Profile sync complete', tag: 'PROFILE');
    } catch (e, stackTrace) {
  logE('Profile sync error (type ${e.runtimeType})', tag: 'PROFILE', error: e, stackTrace: stackTrace);
      // Não voltamos a lançar a exceção para não quebrar o fluxo de OTP / login.
      // Se for necessário reativar comportamento anterior em debug:
      if (kDebugMode) {
  logD('Erro ignorado para não interromper fluxo (debug mode)', tag: 'PROFILE');
      }
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
    
    // Check Firebase database
  final profile = await _userProfileRepo.fetchById(user.uid);
  return profile != null && profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty;
  }

  /// Check if user has email
  bool hasEmail() {
    final user = currentUser;
    return user?.email != null && user!.email!.isNotEmpty;
  }

  /// Store verification ID persistently
  Future<void> _storeVerificationId(String verificationId, String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_verificationIdKey, verificationId);
      await prefs.setString(_phoneNumberKey, phoneNumber);
  logD('Verification ID stored', tag: 'OTP');
    } catch (e) {
  logW('Error storing verification ID: $e', tag: 'OTP');
    }
  }

  /// Retrieve verification ID from persistent storage
  Future<String?> _getStoredVerificationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_verificationIdKey);
    } catch (e) {
  logW('Error retrieving verification ID: $e', tag: 'OTP');
      return null;
    }
  }

  /// Sync existing Firebase user to Firebase database
  /// This is used when user already has both Google + Phone providers but no Firebase profile
  Future<void> syncExistingUserProfile() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
  logW('No current Firebase user to sync', tag: 'PROFILE');
      return;
    }

    try {
  logI('Sync existing Firebase user', tag: 'PROFILE');
  logD('uid=${currentUser.uid} providers=${currentUser.providerData.map((p) => p.providerId).join(", ")}', tag: 'PROFILE');
      
      await _createOrUpdateUserProfile(currentUser);
  logI('Existing user profile synced', tag: 'PROFILE');
    } catch (e) {
  logE('Error syncing existing user profile', tag: 'PROFILE', error: e);
      rethrow;
    }
  }

  /// Get stored phone number
  Future<String?> getStoredPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_phoneNumberKey);
    } catch (e) {
  logW('Error retrieving stored phone number: $e', tag: 'OTP');
      return null;
    }
  }

  /// Clear stored verification data
  Future<void> _clearVerificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_verificationIdKey);
      await prefs.remove(_phoneNumberKey);
      _currentVerificationId = null;
  _resendToken = null;
  _lastOtpSentAt = null;
  logD('Verification data cleared', tag: 'OTP');
    } catch (e) {
  logW('Error clearing verification data: $e', tag: 'OTP');
    }
  }

  /// Clear all stored authentication data (for canceling registration)
  Future<void> clearAllStoredData() async {
    try {
      await _clearVerificationData();
  logD('All stored authentication data cleared', tag: 'OTP');
    } catch (e) {
  logW('Error clearing all stored data: $e', tag: 'OTP');
    }
  }
}