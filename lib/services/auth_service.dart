import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wishlist_app/config.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'USER_CANCELLED');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Ensure idToken is not null
    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(code: 'id-token-missing', message: 'ID Token is missing from Google authentication.');
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken!,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
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

  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) {
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> linkPhoneNumber(PhoneAuthCredential credential) async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para vincular o telefone.',
      );
    }
    await currentUser!.linkWithCredential(credential);
  }

  Future<void> updateProfilePicture(File image) async {
    final imageUrl = await _cloudinaryService.uploadImage(image);
    if (imageUrl != null) {
      await currentUser?.updatePhotoURL(imageUrl);
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado para reautenticar.',
      );
    }
    if (currentUser!.email == null) {
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
    final googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'USER_CANCELLED');
    }
    final googleAuth = await googleUser.authentication;

    // Ensure idToken is not null
    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(code: 'id-token-missing', message: 'ID Token is missing from Google authentication.');
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
    await currentUser!.delete();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
