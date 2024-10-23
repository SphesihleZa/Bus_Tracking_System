import 'dart:async';
import 'dart:convert';
import 'package:duplicate/constants.dart';
import 'package:duplicate/driver/buttons/ReusableButton.dart';
import 'package:duplicate/passenger/pages/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui' as ui;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class BusRouteNavigationPage extends StatefulWidget {
  final String routeNo;
  final String longitude;
  final String latitude;
  final String source;
  final String destination;
  final latlong.LatLng nearestBusStopCoordinates;

  const BusRouteNavigationPage({
    Key? key,
    required this.routeNo,
    required this.longitude,
    required this.latitude,
    required this.source,
    required this.destination,
    required this.nearestBusStopCoordinates,
  }) : super(key: key);

  @override
  State<BusRouteNavigationPage> createState() => _BusRouteNavigationPageState();
}

class _BusRouteNavigationPageState extends State<BusRouteNavigationPage> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? currentLocation;
  Set<Marker> _markers = {};
    List<LatLng> polyLineCoordinates = [];
  bool isMapVisible = true;
  late Timer timer;
  bool isDisposed = false;
  double rotationAngle = 0.0;
  String timeLeft = '';
  late TextEditingController _timeLeftController;
  late FlutterTts flutterTts;
  DateTime lastAnnouncementTime = DateTime.now();
  MapType mapType = MapType.normal; 

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _timeLeftController = TextEditingController();
    _timeLeftController.addListener(_announceTimeLeft);
    initializeLocation();
    startTimer();
    getPolyPoints();
  }

  @override
  void dispose() {
    _timeLeftController.removeListener(_announceTimeLeft);
    _timeLeftController.dispose();
    flutterTts.stop();
    timer.cancel();
    isDisposed = true;
    super.dispose();
  }

  void initializeLocation() {
    currentLocation = LatLng(double.parse(widget.latitude), double.parse(widget.longitude));
    updateMarkers();
    _updateCameraPosition();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isDisposed) {
        getLocationUpdate();
      }
    });
  }

  Future<void> getLocationUpdate() async {
    final response = await http.get(Uri.parse(
        'http://102.135.162.160:2003/api/Coordinates?routeNo=${widget.routeNo}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final firstBus = data[0];
        String latitude = firstBus['latitude'];
        String longitude = firstBus['longitude'];
        String source = firstBus ['source'];
        String destination = firstBus ['destination'];

        if (!isDisposed) {
          setState(() {
            currentLocation = LatLng(double.parse(latitude), double.parse(longitude));
            calculateTimeLeft();
          });
          updateMarkers();
          _updateCameraPosition();
        }
      } else {
        print("No data received");
      }
    } else {
      if (!isDisposed) {
        print("Error getting location: ${response.statusCode}");
      }
    }
  }

    Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    if (currentLocation != null) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        google_api_key,
        PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        PointLatLng(widget.nearestBusStopCoordinates.latitude, widget.nearestBusStopCoordinates.longitude),
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

  void calculateTimeLeft() {
    if (currentLocation != null) {
      final nearestBusStop = widget.nearestBusStopCoordinates;

      final distance = const latlong.Distance().as(
        latlong.LengthUnit.Kilometer,
        latlong.LatLng(currentLocation!.latitude, currentLocation!.longitude),
        nearestBusStop,
      );

      const double averageSpeed = 40.0;
      final double timeInHours = distance / averageSpeed;

      final int timeInMinutes = (timeInHours * 60).round();

      setState(() {
        _timeLeftController.text = '$timeInMinutes minutes';
      });

      String numericString = _timeLeftController.text.split(' ')[0];

      if (DateTime.now().difference(lastAnnouncementTime).inMinutes >= 1) {
        if (timeInMinutes > 1 && timeInMinutes == int.parse(numericString)) {
          _announceSlowRoute();
          lastAnnouncementTime = DateTime.now();
        }
      }
    }
  }

  void _announceTimeLeft() async {
    if (_timeLeftController.text.isNotEmpty) {
      String message = "Route ${widget.routeNo} will arrive in ${_timeLeftController.text}";
      await flutterTts.speak(message);
    }
  }

  void _announceSlowRoute() async {
    String message = "Route ${widget.routeNo} is a bit slow, please be patient.";
    await flutterTts.speak(message);
  }

  void _updateCameraPosition() async {
  if (currentLocation != null) {
    final GoogleMapController googleMapController = await _controller.future;
    if (!isDisposed) {
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation!,
            zoom: 18.0,
            tilt: 0,
            bearing: rotationAngle, 
          ),
        ),
      );
    }
  }
}

Future<void> updateMarkers() async {
  BitmapDescriptor busMarker = await _loadMarkerImage('lib/images/bus_curr.png');
  BitmapDescriptor busStopMarker = await _loadBusStopMarkerImage('lib/images/bus_stop.png'); 

  if (currentLocation != null) {
    Marker currentLocationMarker = Marker(
      markerId: const MarkerId('currentLocation'),
      icon: busMarker,
      position: currentLocation!,
      flat: false,
      anchor: const Offset(0.5, 0.5),
      rotation: rotationAngle,
      zIndex: 100,
    );

    Marker nearestBusStopMarker = Marker(
      markerId: const MarkerId('nearestBusStop'),
      icon: busStopMarker,
      position: LatLng(widget.nearestBusStopCoordinates.latitude, widget.nearestBusStopCoordinates.longitude),
      flat: false,
      anchor: const Offset(0.5, 0.5),
      zIndex: 99,
    );

    setState(() {
      _markers = {currentLocationMarker, nearestBusStopMarker};
    });
  }
}



  Future<BitmapDescriptor> _loadMarkerImage(String imagePath, {int width = 120, int height = 90, }) async {
    ByteData bytes = await rootBundle.load(imagePath);
    ui.Codec codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetHeight: height,
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return BitmapDescriptor.fromBytes(
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List());
  }


  Future<BitmapDescriptor> _loadBusStopMarkerImage(String imagePath, {int width = 90, int height = 90}) async {
  ByteData bytes = await rootBundle.load(imagePath);
  ui.Codec codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
      targetHeight: height,
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return BitmapDescriptor.fromBytes(
      (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List());
}


  void navigateToHomePage() {
    if (!isDisposed) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PassengerDashBoard()), 
        (Route<dynamic> route) => false,
      );
    }
  }

void toggleMapVisibility() {
    if (!isDisposed) {
      setState(() {
        switch (mapType) {
          case MapType.normal:
            mapType = MapType.hybrid;
            break;
          case MapType.hybrid:
            mapType = MapType.terrain;
            break;
          case MapType.terrain:
            mapType = MapType.normal;
            break;
          default:
            mapType = MapType.normal;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: currentLocation != null
                ? CameraPosition(
                    target: currentLocation!,
                    zoom: 18.0,
                    tilt: 0,
                  )
                : const CameraPosition(
                    target: LatLng(0, 0),
                    zoom: 18.0,
                    tilt: 0,
                  ),
                    mapType: mapType, 
                                polylines: {
                      Polyline(
                        polylineId: const PolylineId("routeLine"),
                        points: polyLineCoordinates,
                        color: Colors.blue,
                        width: 8,
                      ),
                    },
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(30.0, 12.0, 30.0, 12.0),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Route ${widget.routeNo} will arrive in ${_timeLeftController.text}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 55,
              height: 80,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 20.0, 12.0),
                child: ReusableButton(
                  onPressed: navigateToHomePage,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.stop_circle_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Stop tracking"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 10,
            child: FloatingActionButton(
              onPressed: toggleMapVisibility,
              child: const Icon(Icons.map),
            ),
          ),
        ],
      ),
    );
  }
}
