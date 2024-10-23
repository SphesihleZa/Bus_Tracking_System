import 'package:duplicate/driver/pages/main_screen.dart';
import 'package:duplicate/pages/login.dart';
import 'package:duplicate/pages/login_or_register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator if the auth state is still being determined
            return CircularProgressIndicator();
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in
            return MainScreen();
          } else {
            // User is not logged in
            return LoginOrRegister(
              onTap: () {},
            );
          }
        },
      ),
    );
  }
}
