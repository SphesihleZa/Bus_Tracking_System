
import 'package:duplicate/passenger/toogles_pages/my_trips.dart';
import 'package:duplicate/passenger/toogles_pages/select_desination_page.dart';
import 'package:flutter/material.dart';


class PassengerDashBoard extends StatefulWidget {
  const PassengerDashBoard({Key? key}) : super(key: key);

  @override
  _PassengerDashBoardState createState() => _PassengerDashBoardState();
}

class _PassengerDashBoardState extends State<PassengerDashBoard> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DestinationPage(),
    PassengerTripsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Container(
        color: Colors.white,
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Track Bus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Trips',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
