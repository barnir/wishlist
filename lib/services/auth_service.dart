import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:wishlist_app/config.dart';
import 'package:wishlist_app/services/supabase_storage_service_secure.dart';
import 'package:wishlist_app/services/user_service.dart';

enum GoogleSignInResult {
  success,
  missingPhoneNumber,
  cancelled,
  failed,
}

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: Config.googleSignInServerClientId,
  );
  final SupabaseStorageServiceSecure _supabaseStorageService = SupabaseStorageServiceSecure();
  final UserService _userService = UserService();

  Stream<User?> get authStateChanges => _supabaseClient.auth.onAuthStateChange.map((data) => data.session?.user);

  User? get currentUser => _supabaseClient.auth.currentUser;

  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
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
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      throw Exception('A senha deve conter pelo menos um símbolo.');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<AuthResponse> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      await _validatePassword(password);

      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      final user = response.user;
      if (user != null) {
        // Create profile but phone_number will be required later
        // Validate email format before saving
        String? emailToSave = email;
        if (emailToSave != null && !_isValidEmail(emailToSave)) {
          throw Exception('Formato de email inválido.');
        }
        
        await _userService.createUserProfile(user.id, {
          'email': emailToSave,
          'display_name': displayName,
          'phone_number': null, // Will be required to be set later
        });
      }
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabaseClient.auth.signOut();
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web implementation - does not support phone number check directly
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.example.wishlist_app://login-callback',
        );
        // On web, we can't immediately know the result. Assume success for now.
        // A more robust solution would involve handling the redirect and then checking.
        return GoogleSignInResult.success;
      } else if (Platform.isAndroid || Platform.isIOS) {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return GoogleSignInResult.cancelled;
        }
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (accessToken == null || idToken == null) {
          return GoogleSignInResult.failed;
        }

        await _supabaseClient.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        final user = _supabaseClient.auth.currentUser;
        if (user == null) {
          return GoogleSignInResult.failed;
        }

        final profile = await _userService.getUserProfile(user.id);
        if (profile == null) {
          // Create profile for Google user but require phone number
          // Validate email format before saving
          String? emailToSave = user.email;
          if (emailToSave != null && !_isValidEmail(emailToSave)) {
            emailToSave = null; // Don't save invalid email
          }
          
          await _userService.createUserProfile(user.id, {
            'email': emailToSave,
            'display_name': user.userMetadata?['display_name'] ?? user.email?.split('@')[0],
            'phone_number': null, // Will be required to be set
          });
          return GoogleSignInResult.missingPhoneNumber;
        }
        
        if (profile['phone_number'] == null || profile['phone_number'].toString().isEmpty) {
          return GoogleSignInResult.missingPhoneNumber;
        }

        return GoogleSignInResult.success;
      }
      return GoogleSignInResult.failed; // Should not be reached
    } catch (e) {
      // Catch any other exception
      return GoogleSignInResult.failed;
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
        phone: phoneNumber,
        channel: OtpChannel.sms,
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
      final user = response.user;
      if (user != null) {
        await _createOrUpdateUserProfileForPhone(user, phoneNumber);
      }
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> _createOrUpdateUserProfileForPhone(User user, String phoneNumber) async {
    try {
      final existingProfile = await _userService.getUserProfile(user.id);

      if (existingProfile != null) {
        // Profile exists, just update the phone number
        await _userService.updateUserProfile(user.id, {'phone_number': phoneNumber});
      } else {
        // Profile doesn't exist, create it with phone number
        // Validate email format before saving
        String? emailToSave = user.email;
        if (emailToSave != null && !_isValidEmail(emailToSave)) {
          emailToSave = null; // Don't save invalid email
        }
        
        await _userService.createUserProfile(user.id, {
          'phone_number': phoneNumber,
          'email': emailToSave,
          'display_name': user.userMetadata?['display_name'] ?? 'User',
        });
      }
    } catch (e) {
      // Log the error and rethrow with more context
      if (kDebugMode) {
        print('Error creating/updating user profile for phone: $e');
        print('User email: ${user.email}');
        print('Phone number: $phoneNumber');
      }
      rethrow;
    }
  }

  Future<void> linkEmailAndPassword(String email, String password) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para vincular o email.');
    }
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
        ),
      );
      await _userService.updateUserProfile(user.id, {'email': email});
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> linkGoogle() async {
    throw UnimplementedError('Linking Google is a complex operation that typically requires server-side logic for proper account merging.');
  }

  Future<void> updateProfilePicture(File image) async {
    final imageUrl = await _supabaseStorageService.uploadImage(image, 'avatars');
    if (imageUrl != null) {
      await _supabaseClient.auth.updateUser(UserAttributes(data: {'photoURL': imageUrl}));
    }
  }

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
      if (kIsWeb) {
        // Web implementation
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.example.wishlist_app://login-callback',
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw 'A reautenticação com o Google foi cancelada.';
        }
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw 'Nenhum token de ID encontrado.';
        }

        await _supabaseClient.auth.reauthenticate(
        );
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteAccount() async {
    if (currentUser == null) {
      throw Exception('Nenhum usuário logado para deletar a conta.');
    }
    throw UnimplementedError('Account deletion requires a server-side function for security reasons.');
  }

  /// Validates if the current user has a phone number configured
  Future<bool> hasPhoneNumber() async {
    final user = currentUser;
    if (user == null) return false;
    
    final profile = await _userService.getUserProfile(user.id);
    return profile != null && 
           profile['phone_number'] != null && 
           profile['phone_number'].toString().isNotEmpty;
  }

  /// Validates if the current user has an email configured
  Future<bool> hasEmail() async {
    final user = currentUser;
    if (user == null) return false;
    
    final profile = await _userService.getUserProfile(user.id);
    return profile != null && 
           profile['email'] != null && 
           profile['email'].toString().isNotEmpty;
  }
}