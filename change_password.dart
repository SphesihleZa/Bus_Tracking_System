import 'package:duplicate/driver/toogles%20pages/profile.dart';
import 'package:duplicate/passenger/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package for API calls
import 'dart:convert'; // For JSON encoding
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'dart:async'; // For Timer

// ReusableButton widget
class ReusableButton extends StatelessWidget {
  const ReusableButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width = double.infinity, // Full width by default
  });

  final Widget child;
  final void Function() onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _oldPasswordError;

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Retrieve the userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        // Handle case when userId is not available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found')),
        );
        return;
      }

      // API call to change password
      final response = await http.post(
        Uri.parse('http://102.135.162.160:2003/api/Auth/change-password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'id': userId, // Include the userId in the request body
          'oldPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {

        Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => ProfilePage(
      successMessage: 'Password changed successfully!',
    ),
  ),
);


      } else if (response.statusCode == 400) {
        // Handle Bad Request error
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['']?.first ?? 'Invalid request';

        if (errorMessage.contains('Incorrect password')) {
          setState(() {
            _oldPasswordError = 'The old password you entered is incorrect. Please try again.';
          });

          // Automatically hide the error message after 5 seconds
          Timer(const Duration(seconds: 5), () {
            setState(() {
              _oldPasswordError = null;
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        // Handle other errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred. Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shield Icon
            const Icon(
              Icons.shield,
              size: 50,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            // Recommendation Text
            const Text(
              'To ensure the security of your account, we recommend that you change your password regularly. Regular updates help protect your account from unauthorized access and keep your personal information safe. Choose a strong and unique password each time to enhance security.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Error message for old password
                  if (_oldPasswordError != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9), 
                        borderRadius: BorderRadius.circular(5), 
                      ),
                      child: Text(
                        _oldPasswordError!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Old Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your old password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your new password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ReusableButton(
                    onPressed: _changePassword,
                    child: const Text('Change Password'),
                    width: MediaQuery.of(context).size.width - 20, // Full width with 10px margin on each side
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
