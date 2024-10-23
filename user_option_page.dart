import 'package:duplicate/driver/buttons/ReusableButton.dart';
import 'package:duplicate/driver/pages/main_screen.dart';
import 'package:duplicate/passenger/pages/main_screen.dart';
import 'package:flutter/material.dart';

class Driver_App_Use_Option extends StatelessWidget {
  const Driver_App_Use_Option({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Text(
                "How would you like to proceed?",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            ReusableButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainScreen()),
                );
              },
              child: Text('Bus Driver'),
            ),
            SizedBox(height: 10.0),
            ReusableButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PassengerDashBoard()),
                );
              },
              child: Text('Passenger'),
            ),
          ],
        ),
      ),
    );
  }
}
