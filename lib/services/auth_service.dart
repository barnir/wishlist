import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart';
import 'package:wishlist_app/services/user_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final UserService _userService = UserService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      final userProfile = await _userService.getUserProfile(user.uid);
      if (!userProfile.exists) {
        await _userService.createUserProfile(user.uid, {
          'email': user.email,
          'displayName': user.displayName ?? '',
          'isPrivate': false,
        });
      }
    }
    return userCredential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'USER_CANCELLED');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign in failed to provide an ID token.',
      );
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken!,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final userProfile = await _userService.getUserProfile(user.uid);
      if (!userProfile.exists) {
        await _userService.createUserProfile(user.uid, {
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL,
          'isPrivate': false,
        });
      }
    }

    return userCredential;
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      await _userService.createUserProfile(user.uid, {
        'email': user.email,
        'displayName': user.displayName ?? '',
        'isPrivate': false,
      });
    }
    return userCredential;
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) {
    return _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<void> signInWithPhoneCredential(AuthCredential credential) {
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> linkPhoneNumber(PhoneAuthCredential credential) async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para vincular o telefone.',
      );
    }
    try {
      await currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'Este número de telemóvel já está associado a outra conta.',
        );
      }
      rethrow;
    }
  }

  Future<void> linkEmailAndPassword(String email, String password) async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para vincular o email.',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'Este email já está associado a outra conta.',
        );
      }
      rethrow;
    }
  }

  Future<void> linkGoogle() async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para vincular o Google.',
      );
    }
    try {
      final googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'USER_CANCELLED');
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: 'Google sign in failed to provide an ID token.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken!,
      );
      await currentUser!.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'Esta conta Google já está associada a outra conta.',
        );
      }
      rethrow;
    }
  }

  Future<void> updateProfilePicture(File image) async {
    final imageUrl = await _cloudinaryService.uploadImage(image);
    if (imageUrl != null) {
      await currentUser?.updatePhotoURL(imageUrl);
      await reloadUser();
    }
  }

  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  Future<void> reauthenticateWithPassword(String password) async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para reautenticar.',
      );
    }
    if (currentUser?.email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'Usuário não possui e-mail para reautenticação com senha.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: currentUser!.email!,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para reautenticar.',
      );
    }
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
      if (kDebugMode) {
        print('Type of googleUser: ${googleUser.runtimeType}');
        print('googleUser: $googleUser');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during Google authentication: $e');
      }
      throw FirebaseAuthException(code: 'google-auth-failed', message: e.toString());
    }

    if (googleUser == null) {
      throw FirebaseAuthException(code: 'USER_CANCELLED');
    }
    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign in failed to provide an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken!,
    );
    await currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> deleteAccount() async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para deletar a conta.',
      );
    }
    await _userService.deleteUserData(currentUser!.uid);
    await currentUser!.delete();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}