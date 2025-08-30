import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  // Unified Android-focused auth logging helper (used selectively)
  void _log(String tag, String message) {
    if (kDebugMode) debugPrint('[AUTH][$tag] $message');
  }

  /// Google Sign-In with fallback for type casting errors
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('=== Firebase Google Sign-In Started ===');
      
      // Android-only Google Sign-In
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
        debugPrint('Google sign-in successful: ${userCredential.user!.email}');
        debugPrint('⚠️ Profile NOT created yet - waiting for phone number');
        
        // Clear any old OTP verification data for fresh start
        await _clearVerificationData();
        debugPrint('🧹 Cleared old OTP verification data for fresh user');
      }
      
      return userCredential;
    } catch (e) {
      debugPrint('Firebase Google sign-in error: $e');
      debugPrint('Current user after error: ${_firebaseAuth.currentUser?.email}');
      
      // Check if user is actually logged in despite the error
      if (_firebaseAuth.currentUser != null) {
        debugPrint('🎯 ERROR OCCURRED BUT USER IS LOGGED IN - Using fallback!');
        final user = _firebaseAuth.currentUser!;
        
        try {
          debugPrint('✅ Fallback: User authenticated successfully');
          debugPrint('Fallback Google sign-in successful: ${user.email}');
          debugPrint('⚠️ Profile NOT created yet - waiting for phone number');
          
          // Clear any old OTP verification data for fresh start
          await _clearVerificationData();
          debugPrint('🧹 Cleared old OTP verification data for fresh user (fallback)');
          
          // Return null to indicate successful login, auth_service.dart will handle this
          return null;
        } catch (profileError) {
          debugPrint('❌ Fallback: Profile creation failed: $profileError');
          rethrow;
        }
      }
      
      rethrow;
    }
  }

  /// Phone Authentication - Send OTP
  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      debugPrint('=== Firebase Phone OTP Send Started ===');
      debugPrint('Phone number: $phoneNumber');
      debugPrint('Phone number length: ${phoneNumber.length}');
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
          debugPrint('📱 Phone verification completed automatically');
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            if (userCredential.user != null) {
              debugPrint('✅ Auto-verification successful: ${userCredential.user!.uid}');
              await _createOrUpdateUserProfile(userCredential.user!, phoneNumber: phoneNumber);
              await _databaseService.updateUserProfile(userCredential.user!.uid, {'phone_verified': true});
              await _clearVerificationData();
            }
          } catch (e) {
            debugPrint('❌ Error in verificationCompleted: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.code} - ${e.message}');
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          debugPrint('🎯 SMS code sent successfully!');
          debugPrint('Verification ID: $verificationId');
          debugPrint('Phone number: $phoneNumber');
          debugPrint('Resend token: $resendToken');
          _resendToken = resendToken;
          _lastOtpSentAt = DateTime.now();
          _currentVerificationId = verificationId;
          await _storeVerificationId(verificationId, phoneNumber);
        },
        codeAutoRetrievalTimeout: (String verificationId) async {
          debugPrint('⏰ Auto-retrieval timeout: $verificationId');
          _currentVerificationId = verificationId;
          await _storeVerificationId(verificationId, phoneNumber);
        },
      );
    } catch (e) {
      debugPrint('❌ Firebase phone OTP error: $e');
      debugPrint('Error type: ${e.runtimeType}');
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
      debugPrint('=== Firebase Phone OTP Verify Started ===');
      debugPrint('Phone number: $phoneNumber');
      debugPrint('SMS Code: $smsCode');
      debugPrint('SMS Code length: ${smsCode.length}');
      debugPrint('Verification ID: $_currentVerificationId');

      if (_currentVerificationId == null) {
        // Try to retrieve from persistent storage
        _currentVerificationId = await _getStoredVerificationId();
        if (_currentVerificationId == null) {
          debugPrint('❌ ERROR: No verification ID found in memory or storage');
          throw Exception('No verification ID found. Please request OTP again.');
        }
        debugPrint('✅ Retrieved verification ID from storage: $_currentVerificationId');
      }

      debugPrint('🔐 Creating PhoneAuthCredential...');
      debugPrint('   - Verification ID: $_currentVerificationId');
      debugPrint('   - SMS Code: $smsCode');

      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId!,
        smsCode: smsCode,
      );

      debugPrint('📱 Credential created...');
      
      final currentUser = _firebaseAuth.currentUser;
      UserCredential? userCredential;
      
      if (currentUser != null) {
        debugPrint('🔗 Current user exists - attempting LINKING...');
        debugPrint('   - Current User UID: ${currentUser.uid}');
        debugPrint('   - Current User Email: ${currentUser.email}');
        debugPrint('   - Current User Providers: ${currentUser.providerData.map((p) => p.providerId).join(", ")}');
        
    try {
          userCredential = await currentUser.linkWithCredential(credential);
          debugPrint('✅ LINKING SUCCESSFUL!');
          debugPrint('   - Same UID maintained: ${userCredential.user?.uid}');
          debugPrint('   - Updated Providers: ${userCredential.user?.providerData.map((p) => p.providerId).join(", ")}');
          debugPrint('   - Now has phone: ${userCredential.user?.phoneNumber}');
        } catch (linkError) {
          debugPrint('❌ LINKING FAILED: $linkError');
          
          if (linkError is FirebaseAuthException && linkError.code == 'provider-already-linked') {
            debugPrint('🔍 Provider already linked - user probably already has phone number');
            // Continue with profile update using current user
            await _createOrUpdateUserProfile(currentUser, phoneNumber: phoneNumber);
      await _databaseService.updateUserProfile(currentUser.uid, {'phone_verified': true});
            await _clearVerificationData();
            debugPrint('✅ Phone verification successful (already linked): ${currentUser.uid}');
            return null;
          } else if (linkError is FirebaseAuthException && linkError.code == 'credential-already-in-use') {
            debugPrint('🔍 Phone number already in use by another account');
            debugPrint('   - This suggests there are multiple accounts that need merging');
            throw Exception('Este número de telefone já está associado a outra conta. Por favor, use um número diferente ou faça login com a conta existente.');
          }
          
          // Check if linking actually succeeded despite the casting error
          final updatedUser = _firebaseAuth.currentUser;
          if (updatedUser != null && updatedUser.phoneNumber == phoneNumber) {
            debugPrint('🎯 LINKING FALLBACK: Linking succeeded despite error');
            debugPrint('   - User UID: ${updatedUser.uid}');
            debugPrint('   - User phone: ${updatedUser.phoneNumber}');
            debugPrint('   - Updated Providers: ${updatedUser.providerData.map((p) => p.providerId).join(", ")}');
            
            // Create user profile for successful linking
            await _createOrUpdateUserProfile(updatedUser, phoneNumber: phoneNumber);
            await _databaseService.updateUserProfile(updatedUser.uid, {'phone_verified': true});
            await _clearVerificationData();
            
            debugPrint('✅ Phone verification successful via linking fallback: ${updatedUser.uid}');
            return null; // Return null to indicate success via fallback
          }
          
          rethrow;
        }
      } else {
        debugPrint('📱 No current user - attempting signInWithCredential...');
        
        try {
          userCredential = await _firebaseAuth.signInWithCredential(credential);
          debugPrint('✅ Sign-in successful for phone-only user: ${userCredential.user?.uid}');
        } catch (credentialError) {
          debugPrint('🔍 signInWithCredential error: $credentialError');
          
          // Check if user is actually signed in despite the error (common Firebase plugin issue)
          final nowCurrentUser = _firebaseAuth.currentUser;
          if (nowCurrentUser != null) {
            debugPrint('🎯 FALLBACK: User is signed in despite credential error');
            debugPrint('User UID: ${nowCurrentUser.uid}');
            debugPrint('User phone: ${nowCurrentUser.phoneNumber}');
            
            // Create user profile for successful linking
            await _createOrUpdateUserProfile(nowCurrentUser, phoneNumber: phoneNumber);
            await _databaseService.updateUserProfile(nowCurrentUser.uid, {'phone_verified': true});
            await _clearVerificationData();
            
            debugPrint('✅ Phone verification successful via fallback: ${nowCurrentUser.uid}');
            return null; // Return null to indicate success via fallback
          }
          
          rethrow; // If user is not signed in, rethrow the original error
        }
      }
      
      if (userCredential.user != null) {
        debugPrint('✅ Phone verification successful: ${userCredential.user!.uid}');
        
        // Check if this is completing an email registration
        final profile = await _databaseService.getUserProfile(userCredential.user!.uid);
        if (profile != null && profile['registration_complete'] == false) {
          debugPrint('📝 Completing email registration process by adding phone number');
          await _databaseService.updateUserProfile(userCredential.user!.uid, {
            'phone_number': phoneNumber,
            'registration_complete': true,
            'phone_verified': true,
          });
          debugPrint('✅ Email registration completed successfully with phone number');
        } else if (profile == null) {
          debugPrint('⚠️ No profile found after phone verification, creating complete profile');
          // Create complete profile if missing entirely
          final profileData = {
            'email': userCredential.user!.email,
            'display_name': userCredential.user!.displayName ?? _extractNameFromEmail(userCredential.user!.email),
            'phone_number': phoneNumber,
            'is_private': false,  // Default to public profile
            'registration_complete': true,
            'phone_verified': true,
          };
          await _databaseService.createUserProfile(userCredential.user!.uid, profileData);
          debugPrint('✅ Created complete profile after phone verification');
        } else {
          // Normal phone verification flow
          await _createOrUpdateUserProfile(userCredential.user!, phoneNumber: phoneNumber);
          await _databaseService.updateUserProfile(userCredential.user!.uid, {'phone_verified': true});
        }
        
        await _clearVerificationData(); // Clear stored verification data after success
      } else {
        debugPrint('⚠️ WARNING: User credential is null after successful verification');
      }

      return userCredential;
    } catch (e) {
      debugPrint('❌ Firebase phone verification error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      
      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
        
        if (e.code == 'invalid-verification-code') {
          debugPrint('🔍 INVALID VERIFICATION CODE ERROR');
          debugPrint('   - Please check the OTP code entered');
          debugPrint('   - Verification code may have expired');
        }
      }
      
      rethrow;
    }
  }

  /// Enhanced phone verification returning a structured enum result
  Future<PhoneVerificationResult> verifyPhoneOtpEnhanced(String phoneNumber, String smsCode) async {
    try {
  await verifyPhoneOtp(phoneNumber, smsCode);
  _log('OTP','Enhanced verification success');
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
      debugPrint('=== Firebase Phone OTP RESEND Started (forceResendingToken) ===');
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 40),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('📱 Auto verification triggered on resend');
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _createOrUpdateUserProfile(userCredential.user!, phoneNumber: phoneNumber);
              await _databaseService.updateUserProfile(userCredential.user!.uid, {'phone_verified': true});
              await _clearVerificationData();
            }
          } catch (e) {
            debugPrint('❌ Error in auto verification (resend): $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification resend failed: ${e.code} - ${e.message}');
          throw Exception('Falha no reenvio: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) async {
          debugPrint('🎯 RESEND SMS code sent successfully!');
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
      debugPrint('❌ Firebase phone OTP resend error: $e');
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
        debugPrint('Email sign-up successful: ${userCredential.user!.email}');
        
        // Create a temporary minimal user profile to prevent orphaned account detection
        // This profile will be updated when phone verification is completed
        await _databaseService.createUserProfile(userCredential.user!.uid, {
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
        
        debugPrint('✅ Temporary user profile created - waiting for phone verification');
      }

      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('Firebase email sign-up error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      
      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
      }
      
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
        debugPrint('Email sign-in successful: ${userCredential.user!.email}');
        debugPrint('⚠️ Profile NOT created yet - waiting for phone number');
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

  /// Create or update user profile in Firebase database
  Future<void> _createOrUpdateUserProfile(
    User user, {
    String? phoneNumber,
    String? displayName,
  }) async {
    try {
      debugPrint('=== 🔄 ENHANCED: Syncing Firebase User to Firebase Database ===');
      debugPrint('Firebase UID: ${user.uid}');
      debugPrint('Email: ${user.email}');
      debugPrint('Display Name: ${user.displayName}');
      debugPrint('Phone: ${user.phoneNumber ?? phoneNumber}');
      debugPrint('Phone Number param: $phoneNumber');
      debugPrint('User.phoneNumber: ${user.phoneNumber}');

      debugPrint('🔍 Step 1: Checking existing profile...');
      final existingProfile = await _databaseService.getUserProfile(user.uid);
      debugPrint('Existing profile result: $existingProfile');
      
      final profileData = <String, dynamic>{
        'email': user.email,
        'display_name': displayName ?? user.displayName ?? _extractNameFromEmail(user.email),
        'phone_number': phoneNumber ?? user.phoneNumber,
        'is_private': false,  // Default to public profile
        'registration_complete': true,  // Mark registration as complete
      };
      debugPrint('Profile data to sync: $profileData');

      if (existingProfile != null) {
        debugPrint('🔍 Step 2: Profile exists, updating...');
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
        
        debugPrint('Update data: $updateData');
        
        if (updateData.isNotEmpty) {
          debugPrint('📝 Calling updateUserProfile...');
          await _databaseService.updateUserProfile(user.uid, updateData);
          debugPrint('✅ Updated existing profile with: $updateData');
        } else {
          debugPrint('ℹ️  No updates needed - profile is up to date');
        }
      } else {
        debugPrint('🔍 Step 2: No existing profile, creating new...');
        debugPrint('📝 Calling createUserProfile...');
        await _databaseService.createUserProfile(user.uid, profileData);
        debugPrint('✅ Created new profile: $profileData');
      }
      
      debugPrint('🎉 Profile sync completed successfully!');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR syncing user profile to database: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      // Não voltamos a lançar a exceção para não quebrar o fluxo de OTP / login.
      // Se for necessário reativar comportamento anterior em debug:
      if (kDebugMode) {
        debugPrint('ℹ️ (Debug mode) Erro ignorado para não interromper fluxo.');
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
    final profile = await _databaseService.getUserProfile(user.uid);
    return profile != null && 
           profile['phone_number'] != null && 
           profile['phone_number'].toString().isNotEmpty;
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
      debugPrint('Verification ID stored successfully');
    } catch (e) {
      debugPrint('Error storing verification ID: $e');
    }
  }

  /// Retrieve verification ID from persistent storage
  Future<String?> _getStoredVerificationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_verificationIdKey);
    } catch (e) {
      debugPrint('Error retrieving verification ID: $e');
      return null;
    }
  }

  /// Sync existing Firebase user to Firebase database
  /// This is used when user already has both Google + Phone providers but no Firebase profile
  Future<void> syncExistingUserProfile() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No current Firebase user to sync');
      return;
    }

    try {
      debugPrint('=== 🔄 Syncing Existing Firebase User to Firebase ===');
      debugPrint('User UID: ${currentUser.uid}');
      debugPrint('Providers: ${currentUser.providerData.map((p) => p.providerId).join(", ")}');
      
      await _createOrUpdateUserProfile(currentUser);
      debugPrint('✅ Existing user profile synced successfully');
    } catch (e) {
      debugPrint('❌ Error syncing existing user profile: $e');
      rethrow;
    }
  }

  /// Get stored phone number
  Future<String?> getStoredPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_phoneNumberKey);
    } catch (e) {
      debugPrint('Error retrieving phone number: $e');
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
      debugPrint('Verification data cleared');
    } catch (e) {
      debugPrint('Error clearing verification data: $e');
    }
  }

  /// Clear all stored authentication data (for canceling registration)
  Future<void> clearAllStoredData() async {
    try {
      await _clearVerificationData();
      debugPrint('All stored authentication data cleared');
    } catch (e) {
      debugPrint('Error clearing all stored data: $e');
    }
  }
}