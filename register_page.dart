import 'package:duplicate/driver/buttons/ReusableButton.dart';
import 'package:flutter/material.dart';
import 'package:duplicate/components/mytextfield.dart';
import 'package:duplicate/pages/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({Key? key, required this.onTap}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController(); 


  final String apiUrl = 'http://102.135.162.160:2003/api/Auth/register';


  void signUserUp() async {

    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      if (passwordController.text == confirmPasswordController.text) {

        if (!isPasswordValid(passwordController.text)) {
          Navigator.pop(context); 
          showErrorMessage('Password must contain at least one uppercase letter, one lowercase letter, one digit, one special character, and be at least 8 characters long');
          return;
        }


        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userName': emailController.text,
            'email': emailController.text,
            'passwordHash': passwordController.text,
            'firstName': nameController.text,
            'lastName': surnameController.text,
            'discriminator': 'Passenger',
            'phoneNumber': phoneNumberController.text,
            'emailConfirmed': true,
            'passwordConfirmed': true,
            'phoneNumberConfirmed': true,
            'loginCount': 0
          }),
        );

        Navigator.pop(context); 

        if (response.statusCode == 200) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(onTap: () {}),
            ),
          );
        } else {

          final responseData = jsonDecode(response.body);
          showErrorMessage(responseData['message'] ?? 'Failed to register user');
        }
      } else {
        Navigator.pop(context);  
        showErrorMessage("Passwords don't match");
      }
    } catch (e) {
      Navigator.pop(context);  
      showErrorMessage('An error occurred. Please try again.');
    }
  }


  bool isPasswordValid(String password) {
    final pattern = RegExp(
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#$%^&*()_+{}|:"<>?~]).{8,}$');
    return pattern.hasMatch(password);
  }


  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // Logo
                const Icon(
                  Icons.lock,
                  size: 100,
                ),

                const SizedBox(height: 50),


                Text(
                  'Welcome! Let\'s create an account for you',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 25),


                MyTextField(
                  controller: nameController,
                  hintText: 'First Name',
                  obscureText: false,
                ),

                const SizedBox(height: 10),


                MyTextField(
                  controller: surnameController,
                  hintText: 'Last Name',
                  obscureText: false,
                ),

                const SizedBox(height: 10),


                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),

                const SizedBox(height: 10),


                MyTextField(
                  controller: phoneNumberController,
                  hintText: 'Phone Number',
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: passwordController,
                  hintText: 'Password (at least one uppercase, one lowercase, one digit, one special character, and minimum 8 characters)',
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Re-enter Password',
                  obscureText: true,
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ReusableButton(
                          onPressed: signUserUp,
                          child: Text("Sign Up"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(onTap: () {}),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
