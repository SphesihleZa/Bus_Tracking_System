import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:duplicate/driver/buttons/ReusableButton.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:duplicate/passenger/pages/route_loc_mpa_page.dart'; // Assuming this import is necessary

class SelectRoutePage extends StatefulWidget {
  final latlong.LatLng nearestBusStopCoordinates;
  final String source;
  final String destination;

  const SelectRoutePage({
    Key? key,
    required this.nearestBusStopCoordinates,
    required this.source,
    required this.destination,
  }) : super(key: key);

  @override
  _SelectRoutePageState createState() => _SelectRoutePageState();
}

class _SelectRoutePageState extends State<SelectRoutePage> {
  Map<String, dynamic>? _selectedRoute;
  List<dynamic> _routes = [];
  bool _loading = true;
  bool _noRoutesFound = false;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    try {
      final source = Uri.encodeComponent(widget.source);
      final destination = Uri.encodeComponent(widget.destination);

      final response = await http.get(Uri.parse('http://102.135.162.160:2003/api/Coordinates/Route?source=$source&destination=$destination'));

      if (response.statusCode == 200) {
        setState(() {
          _routes = json.decode(response.body);
          _loading = false;
          _noRoutesFound = _routes.isEmpty;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _loading = false;
         _noRoutesFound = true;
        });
      } else {
        setState(() {
          _loading = false;
          _noRoutesFound = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to the server')),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select your bus"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _noRoutesFound
              ? const Center(child: Text('There are no active routes for your search.'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: _routes.map((route) {
                            return RadioListTile<Map<String, dynamic>>(
                              title: Text(route['routeNo'].toString()),
                              value: route,
                              groupValue: _selectedRoute,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRoute = value;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(right: 20, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ReusableButton(
                            onPressed: () {
                              if (_selectedRoute != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BusRouteNavigationPage(
                                      routeNo: _selectedRoute!['routeNo'].toString(),
                                      longitude: _selectedRoute!['longitude'].toString(),
                                      latitude: _selectedRoute!['latitude'].toString(),
                                      source: _selectedRoute!['source'].toString(),
                                      destination: _selectedRoute!['destination'].toString(),
                                      nearestBusStopCoordinates: widget.nearestBusStopCoordinates,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Track Bus'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
