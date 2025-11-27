import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

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
        print('User profile already exists');
        return;
      }
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User profile created for ${user.email}');
    } catch (e) {
      print('Error creating user profile: $e');
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
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
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
      print('Error signing in with Github: $e');
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
      print('Error signing up with email: $e');
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
