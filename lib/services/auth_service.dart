import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:wishlist_app/services/supabase_storage_service.dart';
import 'package:wishlist_app/services/user_service.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final SupabaseStorageService _supabaseStorageService = SupabaseStorageService();
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
        await _userService.createUserProfile(user.id, {
          'email': email,
          'display_name': displayName,
        });
      }
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  Future<void> signInWithGoogle() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final googleUser = await GoogleSignIn.instance.signIn();
        final googleAuth = await googleUser!.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (accessToken == null) {
          throw 'No Access Token found.';
        }
        if (idToken == null) {
          throw 'No ID Token found.';
        }

        await _supabaseClient.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      } else {
        // Web-specific sign-in
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          scopes: 'email',
        );
      }
    } on AuthException catch (e) {
      throw Exception('Supabase sign-in failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
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
    final existingProfile = await _userService.getUserProfile(user.id);

    if (existingProfile != null) {
      // Profile exists, just update the phone number
      await _userService.updateUserProfile(user.id, {'phone_number': phoneNumber});
    } else {
      // Profile doesn't exist, create it
      await _userService.createUserProfile(user.id, {
        'phone_number': phoneNumber,
        'email': user.email,
        'display_name': user.userMetadata?['display_name'],
      });
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
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final googleUser = await GoogleSignIn.instance.signIn();
        final googleAuth = await googleUser!.authentication;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw 'No ID Token found.';
        }

        await _supabaseClient.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
      } else {
        // Web-specific reauthentication
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          scopes: 'email',
        );
      }
    }
    on AuthException catch (e) {
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
}