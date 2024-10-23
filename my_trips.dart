import 'package:flutter/material.dart';

class PassengerTripsPage extends StatelessWidget {
  const PassengerTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("My Trips", 
          style: TextStyle(
            fontSize: 20.0,
          ),),
        ),
      )
    );
  }
}