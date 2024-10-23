import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:duplicate/constants.dart';
import 'package:duplicate/driver/buttons/ReusableButton.dart';
import 'package:duplicate/driver/pages/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as Location;
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong;



class RouteNavigationPage extends StatefulWidget {
  final String source;
  final String destination;
  final String routeNo;
  final String day;
  final String time;

  const RouteNavigationPage({
    Key? key,
    required this.source,
    required this.destination,
    required this.routeNo,
    required this.day,
    required this.time,
  }) : super(key: key);

  @override
  State<RouteNavigationPage> createState() => _RouteNavigationPageState();
}

class _RouteNavigationPageState extends State<RouteNavigationPage> {
  final Completer<GoogleMapController> _controller = Completer();
  late BitmapDescriptor customIcon;

  LatLng sourceLocation = const LatLng(-29.8611, 31.0266);
  LatLng destinationCoords = const LatLng(-29.8608, 31.0305);

  List<LatLng> polyLineCoordinates = [];

    List<Map<String, dynamic>> busStops = [];

  Location.LocationData? currentLocation;
  FlutterTts flutterTts = FlutterTts();

  Set<Marker> _markers = {};

  late Timer timer;
  bool isTripActive = true; 
   LatLng? lastSpokenPoint;

  @override
  void initState() {
    super.initState();

    getCurrentLocation();

    fetchBusStops();

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (isTripActive) {
        _updateCoordinates();

        getPolyPoints();
        // provideVoiceNavigation(context);
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

void getCurrentLocation() async {
  Location.Location location = Location.Location();

  bool _serviceEnabled;
  Location.PermissionStatus _permissionGranted;

  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == Location.PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != Location.PermissionStatus.granted) {
      return;
    }
  }

  Location.LocationData? initialLocation = await location.getLocation();
  setState(() {
    currentLocation = initialLocation;
  });

  timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
    if (isTripActive) {
      Location.LocationData? newLocation = await location.getLocation();
      setState(() {
        currentLocation = newLocation;
      });

      _updateCameraPosition();
      getPolyPoints(); 
      _updateMarkers(); 
    }
  });
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
  



 void _updateCoordinates() async {
    if (currentLocation == null) return;

    final url = Uri.parse('http://102.135.162.160:2003/api/Coordinates');
    final body = jsonEncode({
      'source': widget.source,
      'destination': widget.destination,
      'routeNo': widget.routeNo,
      'longitude': currentLocation!.longitude.toString(),
      'latitude': currentLocation!.latitude.toString(),
      'day': widget.day,
      'time' : widget.time
    });
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('Coordinates updated successfully.');
      } else if (response.statusCode == 404) {
        print('Route not found. Creating new entry...');
        // Handle creating a new entry if needed
      } else {
        print('Failed to update coordinates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating coordinates: $e');
    }
  }

  void _updateCameraPosition() async {
    GoogleMapController googleMapController = await _controller.future;
    if (currentLocation != null) {
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentLocation!.latitude!,
              currentLocation!.longitude!,
            ),
            zoom: 19.5,
            tilt: 90,
            bearing: currentLocation!.heading ?? 0,
          ),
        ),
      );
    }
  }

  Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    if (currentLocation != null) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        google_api_key,
        PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        PointLatLng(destinationCoords.latitude, destinationCoords.longitude),
      );

      if (result.points.isNotEmpty) {
        setState(() {
          polyLineCoordinates.clear();
          result.points.forEach((PointLatLng point) {
            polyLineCoordinates.add(LatLng(point.latitude, point.longitude));
          });
        });
      }
    }
  }

void _updateMarkers() {
  if (currentLocation != null) {
    _loadMarkerImage('lib/images/travel_icon.png').then((BitmapDescriptor currentLocationIcon) {
      _loadMarkerImage('lib/images/bus_source_icon_new.png').then((BitmapDescriptor sourceIcon) {
        _loadMarkerImage('lib/images/bus_destination.png').then((BitmapDescriptor destinationIcon) {
          _loadMarkerImage('lib/images/bus_stop_new.png').then((BitmapDescriptor busStopIcon) {
            List<Marker> markers = [];

            Marker currentLocationMarker = Marker(
              markerId: const MarkerId('currentLocation'),
              icon: currentLocationIcon,
              position: LatLng(
                currentLocation!.latitude!,
                currentLocation!.longitude!,
              ),
              flat: true,
              anchor: const Offset(0.5, 0.5),
              rotation: currentLocation!.heading ?? 0,
            );
            markers.add(currentLocationMarker);

            Marker sourceMarker = Marker(
              markerId: const MarkerId('source'),
              icon: sourceIcon,
              position: LatLng(
                sourceLocation.latitude,
                sourceLocation.longitude,
              ),
              infoWindow: const InfoWindow(title: 'Source'),
            );
            markers.add(sourceMarker);

            Marker destinationMarker = Marker(
              markerId: const MarkerId('destination'),
              icon: destinationIcon,
              position: LatLng(
                destinationCoords.latitude,
                destinationCoords.longitude,
              ),
              infoWindow: InfoWindow(title: 'Destination', snippet: widget.destination),
            );
            markers.add(destinationMarker);

            for (Map<String, dynamic> busStop in busStops) {
              Marker busStopMarker = Marker(
                markerId: MarkerId(busStop['stopName']),
                icon: busStopIcon,
                position: LatLng(
                  busStop['latitude'],
                  busStop['longitude'],
                ),
                infoWindow: InfoWindow(title: busStop['stopName']),
              );
              markers.add(busStopMarker);
            }

            setState(() {
              _markers = Set<Marker>.of(markers);
            });
          }).catchError((e) {
            print('Error loading bus stop marker icon: $e');
          });
        }).catchError((e) {
          print('Error loading destination marker icon: $e');
        });
      }).catchError((e) {
        print('Error loading source marker icon: $e');
      });
    });
  }
}

// void provideVoiceNavigation(BuildContext context) async {
//   if (polyLineCoordinates.isEmpty || currentLocation == null) return;

//   final currentPoint = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);

//   const double thresholdDistance = 15; 
//   const double hysteresis = 2; 

//   if (lastSpokenPoint == null ||
//       calculateDistance(currentPoint.latitude, currentPoint.longitude, lastSpokenPoint!.latitude, lastSpokenPoint!.longitude) > thresholdDistance + hysteresis) {
    

//     final nearestPoint = _findNearestPolylinePoint(currentPoint);

//     if (nearestPoint != null) {
//       double turnAngle = calculateTurnAngle(currentPoint.latitude, currentPoint.longitude, nearestPoint.latitude, nearestPoint.longitude);
//       String direction = "";

//       if (turnAngle >= 60 && turnAngle <= 150) {
//         direction = "Turn right in 5 meters";
//       } else if (turnAngle <= 300 && turnAngle >= 210) {
//         direction = "Turn left in 5 meters";
//       } else {
//         direction = "Go straight";
//       }

//       await flutterTts.speak(direction);
//       lastSpokenPoint = nearestPoint; 
//     }
//   }
// }

// LatLng? _findNearestPolylinePoint(LatLng currentPoint) {
//   if (polyLineCoordinates.isEmpty) return null;

//   double minDistance = double.infinity;
//   LatLng? nearestPoint;

//   for (LatLng point in polyLineCoordinates) {
//     double distance = calculateDistance(currentPoint.latitude, currentPoint.longitude, point.latitude, point.longitude);
//     if (distance < minDistance) {
//       minDistance = distance;
//       nearestPoint = point;
//     }
//   }

//   return nearestPoint;
// }


// double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
//   const double earthRadius = 6371; 

//   double dLat = (endLatitude - startLatitude) * (pi / 180);
//   double dLon = (endLongitude - startLongitude) * (pi / 180);

//   double a = sin(dLat / 2) * sin(dLat / 2) +
//       cos(startLatitude * (pi / 180)) * cos(endLatitude * (pi / 180)) *
//       sin(dLon / 2) * sin(dLon / 2);

//   double c = 2 * atan2(sqrt(a), sqrt(1 - a));

//   return earthRadius * c * 1000; 
// }

// double calculateBearing(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
//   double dLon = (endLongitude - startLongitude) * (pi / 180);
//   double y = sin(dLon) * cos(endLatitude * (pi / 180));
//   double x = cos(startLatitude * (pi / 180)) * sin(endLatitude * (pi / 180)) -
//       sin(startLatitude * (pi / 180)) * cos(endLatitude * (pi / 180)) * cos(dLon);
//   return atan2(y, x) * (180 / pi); 
// }

// double calculateTurnAngle(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
//   double bearing = calculateBearing(startLatitude, startLongitude, endLatitude, endLongitude);
//   double distance = calculateDistance(startLatitude, startLongitude, endLatitude, endLongitude);

//   double turnAngle = 0;
//   if (distance < 50 && bearing > 30 && bearing < 150) {
//     turnAngle = 45; 
//   } else if (distance < 50 && bearing > 210 && bearing < 330) {
//     turnAngle = 135;
//   } else {
//     turnAngle = bearing; 
//   }

//   return turnAngle;
// }

Future<BitmapDescriptor> _loadMarkerImage(String imagePath, {int width = 170, int height = 170}) async {
  ByteData bytes = await rootBundle.load(imagePath);
  ui.Codec codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List(), targetHeight: height, targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return BitmapDescriptor.fromBytes((await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
}

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Are you sure you want to end your current trip?"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isTripActive = false; // Set flag to false to stop posting coordinates
                  timer.cancel(); // Cancel the timer
                });
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MainScreen(),
                  ),
                );
              },
              child: const Text("End trip"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 30),
                  height: 80,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      "${widget.routeNo}: ${widget.source} to ${widget.destination}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentLocation!.latitude!,
                        currentLocation!.longitude!,
                      ),
                      zoom: 19.5,
                      tilt: 90,
                    ),
                    mapType: MapType.normal,
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId("route"),
                        points: polyLineCoordinates,
                        color: Colors.blue,
                        width: 20,
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    markers: _markers,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 16.0),
                        child: ReusableButton(
                          onPressed: () {
                            _showConfirmationDialog(context);
                          },
                          child: const Text("End Trip"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}