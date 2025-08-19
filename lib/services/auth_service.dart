import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:wishlist_app/config.dart';
import 'package:wishlist_app/services/supabase_storage_service.dart';
import 'package:wishlist_app/services/user_service.dart';

/// Enum representing the possible outcomes of a Google Sign-In attempt.
enum GoogleSignInResult {
  /// The sign-in was successful.
  success,

  /// The user's profile is missing a phone number.
  missingPhoneNumber,

  /// The user cancelled the sign-in process.
  cancelled,

  /// The sign-in process failed for an unknown reason.
  failed
}

/// Service responsible for handling all authentication-related logic.
///
/// This includes email/password, Google, and phone number authentication,
/// as well as user profile management and account linking.
class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: kIsWeb ? null : Config.googleSignInServerClientId,
    clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' : null, // TODO: Replace with your web client ID
  );
  final SupabaseStorageService _supabaseStorageService =
      SupabaseStorageService();
  final UserService _userService = UserService();

  /// A stream that notifies listeners of changes to the user's authentication state.
  Stream<User?> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange.map((data) => data.session?.user);

  /// The currently signed-in user, or null if no user is signed in.
  User? get currentUser => _supabaseClient.auth.currentUser;

  /// Signs in a user with their email and password.
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Validates a password against a set of security rules.
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

  /// Creates a new user with the given email, password, and display name.
  Future<AuthResponse> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
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

  /// Signs out the current user from both Supabase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabaseClient.auth.signOut();
  }

  /// Initiates the Google Sign-In flow.
  ///
  /// On mobile platforms, it checks if the user has a phone number linked to their account.
  /// On web, it uses OAuth with a redirect.
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web implementation
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.example.wishlist_app://login-callback',
        );
        return GoogleSignInResult.success;
      }

      // Mobile implementation
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
      if (profile == null ||
          profile['phone_number'] == null ||
          profile['phone_number'].toString().isEmpty) {
        return GoogleSignInResult.missingPhoneNumber;
      }

      return GoogleSignInResult.success;
    } catch (e) {
      return GoogleSignInResult.failed;
    }
  }

  /// Sends a one-time password (OTP) to the given phone number.
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

  /// Verifies the OTP sent to the user's phone and signs them in.
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

  /// Creates or updates a user's profile after a successful phone authentication.
  Future<void> _createOrUpdateUserProfileForPhone(
    User user,
    String phoneNumber,
  ) async {
    final existingProfile = await _userService.getUserProfile(user.id);

    if (existingProfile != null) {
      // Profile exists, just update the phone number
      await _userService.updateUserProfile(user.id, {
        'phone_number': phoneNumber,
      });
    } else {
      // Profile doesn't exist, create it
      await _userService.createUserProfile(user.id, {
        'phone_number': phoneNumber,
        'email': user.email,
        'display_name': user.userMetadata?['display_name'],
      });
    }
  }

  /// Links an email and password to the currently signed-in user's account.
  Future<void> linkEmailAndPassword(String email, String password) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para vincular o email.');
    }
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(email: email, password: password),
      );
      await _userService.updateUserProfile(user.id, {'email': email});
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Links a Google account to the currently signed-in user's account.
  ///
  /// **Note:** This is a complex operation that is not fully implemented.
  Future<void> linkGoogle() async {
    if (currentUser == null) {
      throw Exception('Nenhum usuário logado para vincular a conta do Google.');
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'O vínculo com o Google foi cancelado.';
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Nenhum token de ID encontrado.';
      }

      // Manually link the account by updating the user's metadata.
      // This is not the most secure approach, but it is a common workaround.
      // A more secure solution would involve a server-side function.
      await _supabaseClient.auth.updateUser(
        UserAttributes(
          data: {
            'google_provider_token': idToken,
          },
        ),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Updates the user's profile picture.
  Future<void> updateProfilePicture(File image) async {
    final imageUrl = await _supabaseStorageService.uploadImage(
      image,
      'avatars',
    );
    if (imageUrl != null) {
      await _supabaseClient.auth.updateUser(
        UserAttributes(data: {'photoURL': imageUrl}),
      );
    }
  }

  /// Updates the user's display name and/or photo URL.
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

  /// Re-authenticates the user with their password.
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

  /// Re-authenticates the user with their Google account.
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
        return;
      }

      // Mobile implementation
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'A reautenticação com o Google foi cancelada.';
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Nenhum token de ID ou de acesso encontrado.';
      }

      await _supabaseClient.auth.reauthenticate();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Deletes the current user's account.
  ///
  /// **Note:** This is a placeholder and is not fully implemented for security reasons.
  Future<void> deleteAccount() async {
    if (currentUser == null) {
      throw Exception('Nenhum usuário logado para deletar a conta.');
    }
    throw UnimplementedError(
      'Account deletion requires a server-side function for security reasons.',
    );
  }
}
