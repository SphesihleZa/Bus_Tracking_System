import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:duplicate/passenger/change_password.dart';

class ProfilePage extends StatefulWidget {
  final String? successMessage;

  const ProfilePage({Key? key, this.successMessage}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final cellphoneController = TextEditingController();
  final emailController = TextEditingController();

  bool isEditingFirstName = false;
  bool isEditingLastName = false;
  bool isEditingCellphone = false;
  bool isEditingEmail = false;
  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();

    if (widget.successMessage != null) {
      Future.delayed(Duration.zero, () {
        setState(() {
          _showSuccessMessage = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            _showSuccessMessage = false;
          });
        });
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final response = await http.get(
        Uri.parse('http://102.135.162.160:2003/api/User/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          firstNameController.text = responseData['firstName'];
          lastNameController.text = responseData['lastName'];
          emailController.text = responseData['email'];
          cellphoneController.text = responseData['phoneNumber'];
        });
      } else {
        print('Failed to load profile data');
      }
    } else {
      print('User ID not found');
    }
  }

  Future<void> _updateField(String field, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final response = await http.get(
        Uri.parse('http://102.135.162.160:2003/api/User/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final updatedUser = {
          'id': responseData['id'],
          'firstName': field == 'firstName' ? value : responseData['firstName'],
          'lastName': field == 'lastName' ? value : responseData['lastName'],
          'userName': responseData['userName'],
          'email': field == 'email' ? value : responseData['email'],
          'phoneNumber': field == 'cellphone' ? value : responseData['phoneNumber'],
          'passwordHash': responseData['passwordHash'],
        };

        final updateResponse = await http.put(
          Uri.parse('http://102.135.162.160:2003/api/User/$userId'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(updatedUser),
        );

        if (updateResponse.statusCode == 200) {
          print('$field updated successfully');
        } else {
          print('Failed to update $field: ${updateResponse.reasonPhrase}');
        }
      } else {
        print('Failed to fetch profile data');
      }
    } else {
      print('User ID not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showSuccessMessage && widget.successMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  width: double.infinity,
                  child: Text(
                    widget.successMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your account security is our priority. Regularly updating your profile information and managing your password effectively helps to protect your personal data and ensures a safer experience. Make sure your password is strong and unique, and review your profile details frequently to keep them accurate and secure.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ProfileField(
                label: 'First Name',
                controller: firstNameController,
                isEditing: isEditingFirstName,
                onEdit: () {
                  setState(() {
                    isEditingFirstName = !isEditingFirstName;
                  });
                  if (!isEditingFirstName) {
                    _updateField('firstName', firstNameController.text);
                  }
                },
              ),
              const SizedBox(height: 10),
              ProfileField(
                label: 'Last Name',
                controller: lastNameController,
                isEditing: isEditingLastName,
                onEdit: () {
                  setState(() {
                    isEditingLastName = !isEditingLastName;
                  });
                  if (!isEditingLastName) {
                    _updateField('lastName', lastNameController.text);
                  }
                },
              ),
              const SizedBox(height: 10),
              ProfileField(
                label: 'Cellphone Number',
                controller: cellphoneController,
                isEditing: isEditingCellphone,
                onEdit: () {
                  setState(() {
                    isEditingCellphone = !isEditingCellphone;
                  });
                  if (!isEditingCellphone) {
                    _updateField('cellphone', cellphoneController.text);
                  }
                },
              ),
              const SizedBox(height: 10),
              ProfileField(
                label: 'Email',
                controller: emailController,
                isEditing: isEditingEmail,
                onEdit: () {
                  setState(() {
                    isEditingEmail = !isEditingEmail;
                  });
                  if (!isEditingEmail) {
                    _updateField('email', emailController.text);
                  }
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onEdit;

  const ProfileField({
    Key? key,
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isEditing)
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                )
              else
                Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 16.0,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          onPressed: onEdit,
        ),
      ],
    );
  }
}
