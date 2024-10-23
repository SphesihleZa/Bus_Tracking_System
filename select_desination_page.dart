import 'dart:convert';
import 'package:duplicate/driver/splush_screen/splash%20screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as location;
import 'package:duplicate/driver/buttons/ReusableButton.dart';
import 'package:duplicate/passenger/pages/profile_page.dart';
import 'package:duplicate/passenger/pages/settings_page.dart';
import 'package:duplicate/passenger/select_route_page.dart';

class DestinationPage extends StatefulWidget {
  const DestinationPage({Key? key}) : super(key: key);

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  String nearestBusStop = '';
  latlong.LatLng? nearestBusStopCoordinates;
  late location.Location _location;
  late TextEditingController _nearestBusStopController;
  late TextEditingController _destinationController;
  List<Map<String, dynamic>> busStops = [];
  List<String> activeRoutes = [];
  
  String source = ''; 
  String destination = ''; 
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _location = location.Location();
    _nearestBusStopController = TextEditingController();
    _destinationController = TextEditingController();
    checkLocationPermission();
    fetchBusStops();
    getUserLocation();
  }

  Future<void> checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    location.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == location.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != location.PermissionStatus.granted) {
        return; 
      }
    }
  }

  Future<void> getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String nearestStop = await getNearestBusStop(position);
      setState(() {
        nearestBusStop = nearestStop;
        _nearestBusStopController.text = nearestStop;
        source = nearestStop; // Assigning nearest stop to source
        fetchActiveRoutes(nearestStop); // Fetch active routes based on nearest bus stop
      });
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  Future<void> fetchBusStops() async {
    try {
      final response = await http.get(
        Uri.parse('http://102.135.162.160:2003/api/BusStopCoordinates'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          busStops = data.map((item) {
            return {
              'stopName': item['stopName'],
              'longitude': double.parse(item['longitude'].toString()),
              'latitude': double.parse(item['latitude'].toString()),
              'coordinates': latlong.LatLng(double.parse(item['latitude'].toString()), double.parse(item['longitude'].toString())),
            };
          }).toList();
        });
      } else {
        print('Failed to load bus stops: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bus stops: $e');
    }
  }

   Future<void> fetchActiveRoutes(String nearestStop) async {
    try {
      final response = await http.get(
        Uri.parse('http://102.135.162.160:2003/api/ManageSchedule'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!_isDisposed) {
          setState(() {
            activeRoutes = data
                .where((item) => item['source'].toString().toLowerCase().contains(nearestStop.toLowerCase()) ||
                                item['destination'].toString().toLowerCase().contains(nearestStop.toLowerCase()))
                .map<String>((item) => item['destination'].toString())
                .toList();
          });
        }
      } else {
        print('Failed to load active routes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching active routes: $e');
    }
  }

  Future<String> getNearestBusStop(Position userPosition) async {
    double minDistance = double.infinity;
    String nearestStop = '';

    for (var busStop in busStops) {
      double distance = const latlong.Distance().distance(
        latlong.LatLng(userPosition.latitude, userPosition.longitude),
        busStop['coordinates'],
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestStop = busStop['stopName'];
        nearestBusStopCoordinates = busStop['coordinates'];
      }
    }

    return nearestStop;
  }

  void signout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken != null) {
      try {
        final response = await http.post(
          Uri.parse('http://102.135.162.160:2003/api/Auth/logout'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'refreshToken': refreshToken,
          }),
        );

        if (response.statusCode == 200) {
          await prefs.clear();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MySplashScreen()),
            (route) => false,
          );
        } else {
          print('Failed to logout: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error during logout: $e');
      }
    } else {
      print('No refresh token found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Track Bus",
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        actions: <Widget>[
          Transform.translate(
            offset: const Offset(0, 10),
            child: PopupMenuButton<String>(
              onSelected: (String result) {
                switch (result) {
                  case 'Account':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                    break;
                  case 'Sign out':
                    signout(context);
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Account',
                  child: ListTile(
                    leading: Icon(Icons.account_circle),
                    title: Text('Account'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Sign out',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 90.0),
              child: Text(
                'Track your bus arrival time',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Nearest Bus Stop',
                  border: OutlineInputBorder(),
                ),
                controller: _nearestBusStopController,
                onChanged: (value) {
                  setState(() {
                    source = value;
                    fetchActiveRoutes(value);
                  });
                },
              ),
            ),
           Padding(
  padding: const EdgeInsets.all(8.0),
  child: Autocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return const Iterable<String>.empty();
      } else {
        return activeRoutes.where((route) => route.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      }
    },
    onSelected: (String selection) {
      setState(() {
        destination = selection;
      });
    },
    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
      return Align(
        alignment: Alignment.topLeft,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100], 
            borderRadius: BorderRadius.circular(10.0), 
          ),
          padding: const  EdgeInsets.only(left:8.0, right:10.0),
          child: Material(
            child: ListView(
              shrinkWrap: true,
              children: options.map((String option) => Container(
                color: Colors.grey[100], 
                child: ListTile(
                  title: Text(option),
                  onTap: () {
                    onSelected(option);
                  },
                ),
              )).toList(),
            ),
          ),
        ),
      );
    },
    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
      return TextField(
        controller: textEditingController,
        focusNode: focusNode,
        decoration: const InputDecoration(
          labelText: 'Enter Destination',
          border: OutlineInputBorder(),
        ),
      );
    },
  ),
),

            Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ReusableButton(
                    child: const Text("Track Bus"),
                    onPressed: () {
                      if (!_isDisposed) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectRoutePage(
                              source: source,
                              destination: destination,
                              nearestBusStopCoordinates: nearestBusStopCoordinates !,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            ]
        ),
      ),
    );
  }
}