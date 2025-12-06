import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_api.dart';

/// This file is used to monitor the auth state of a user and ensure
/// users are only able to access features that are allowed to their account.


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

  //Create user profile in firestore
  Future<void> _createUserProfile(User user) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        return;
      }
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
    }
  }

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

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!);
        // initialize push notifications
        await FirebaseApi().initNotifications();
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  //Sign in with github
  Future<UserCredential?> signInWithGitHub() async {
    try{
      GithubAuthProvider githubProvider = GithubAuthProvider();
      UserCredential? userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(githubProvider);
      }
      else{
        userCredential = await _auth.signInWithProvider(githubProvider);
      }

      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail({required String email, required String password, required String displayName}) async{
    try{
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(displayName);
      await userCredential.user!.reload();
      await _createUserProfile(userCredential.user!);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail({required String email, required String password}) async{
    try{
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if(userCredential.user != null){
        await _createUserProfile(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  //password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try{
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try{
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      rethrow;
    }
  }
}
