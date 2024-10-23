import 'package:duplicate/driver/pages/main_screen.dart';
import 'package:duplicate/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // google sign in
  signInWithGoogle(BuildContext context) async {
    try {
      // begin interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser != null) {
        // obtain auth details
        final GoogleSignInAuthentication gAuth = await gUser.authentication;

        // create new credentials for user
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        // sign in with Firebase credential
        await FirebaseAuth.instance.signInWithCredential(credential);

        // navigate to main screen  after successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(),
            ),
        );
      } else {
        // Handle case where Google sign-in was canceled or failed
        // You can display an error message or handle it according to your app's logic
        print("Google sign-in canceled or failed.");
      }
    } catch (e) {
      // Handle any exceptions that occur during the sign-in process
      print("Error signing in with Google: $e");
      // You can display an error message or handle it according to your app's logic
    }
  }
}
