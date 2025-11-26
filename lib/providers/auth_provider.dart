import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

//provider that streams the current authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

//provider for authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  //Sign in with google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  //Sign in with github
  Future<UserCredential?> signInWithGitHub() async {
    try{
      GithubAuthProvider githubProvider = GithubAuthProvider();
      if (kIsWeb) {
        return await _auth.signInWithPopup(githubProvider);
      }
      else{
        return await _auth.signInWithProvider(githubProvider);
      }
    } catch (e) {
      print('Error signing in with Github: $e');
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail({required String email, required String password, required String displayName}) async{
    try{
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(displayName);
      await userCredential.user!.reload();
      return userCredential;
    } catch (e) {
      print('Error signing up with email: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail({required String email, required String password}) async{
    try{
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  //password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try{
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try{
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      print('Error signing out:');
      rethrow;
    }
  }
}
