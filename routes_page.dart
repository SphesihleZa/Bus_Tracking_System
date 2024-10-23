import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:duplicate/driver/models/bus_schedule_model.dart';
import 'package:duplicate/driver/pages/route_navigation_page.dart';
import 'package:duplicate/driver/buttons/ReusableButton.dart';

class MyRoutesPage extends StatefulWidget {
  final String suburb;
  final String source;
  final String destination;
  final String routeNo;
  final String day;
  final String time;

  const MyRoutesPage({
    Key? key,
    required this.suburb,
    required this.source,
    required this.destination,
    required this.routeNo,
    required this.day,
    required this.time,
  }) : super(key: key);

  @override
  State<MyRoutesPage> createState() => _MyRoutesPageState();
}

class _MyRoutesPageState extends State<MyRoutesPage> {
  List<BusSchedule> suburbs = [];
  List<BusSchedule> filteredRoutes = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    final url = 'http://102.135.162.160:2003/api/ManageSchedule';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          suburbs = data.map((item) => BusSchedule.fromJson(item)).toList();
          suburbs = suburbs.where((schedule) {
            final sourceLower = schedule.source.toLowerCase();
            final destinationLower = schedule.destination.toLowerCase();
            final suburbLower = widget.suburb.toLowerCase();
            final dayLower = widget.day.toLowerCase();
            final timeLower = widget.time.toLowerCase();

            return sourceLower.contains(suburbLower) || destinationLower.contains(suburbLower);
          }).toList();

          filteredRoutes = suburbs;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void filterRoutes(String query) {
    setState(() {
      searchText = query;
      if (query.isNotEmpty) {
        filteredRoutes = suburbs.where((route) =>
            route.routeNo.toString().contains(query) ||
            route.source.toLowerCase().contains(query.toLowerCase()) ||
            route.destination.toLowerCase().contains(query.toLowerCase())).toList();
      } else {
        filteredRoutes = suburbs;
      }
    });
  }

  void _showConfirmationDialog(BuildContext context, String source, String destination, String routeNo, String day, String time) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: Text("You are driving $routeNo from $source  to the $destination. Click the Start trip button to confirm or click the Back button to re-select your route."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RouteNavigationPage(
                      source: source,
                      destination: destination,
                      routeNo: routeNo,
                      day: day,
                      time: time,
                    ),
                  ),
                );
              },
              child: const Text("Start trip"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Routes for ${widget.suburb}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
const Padding(
  padding: EdgeInsets.all(30.0), 
  child: Center( 
    child: Row(
      children: [
        Flexible(
          child: Text(
            "Which route will you be driving via today?",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center, 
          ),
        ),
      ],
    ),
  ),
),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextField(
                      onChanged: (value) {
                        filterRoutes(value); // Call filter method on text change
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search route...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.fromLTRB(0, 15, 0, 5),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                  child: DataTable(
                    columnSpacing: 32.0,
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text(
                            'Route no.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text(
                            'Source',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text(
                            'Dest.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text(
                            'Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text(
                            'Select',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    rows: filteredRoutes.map((schedule) {
                      String timeOnly = schedule.startTime.substring(0, 5);

                      return DataRow(cells: [
                        DataCell(Text(schedule.routeNo.toString())),
                        DataCell(Text(schedule.source)),
                        DataCell(Text(schedule.destination)),
                        DataCell(Text(timeOnly)),
                        DataCell(
                          ReusableButton(
                            onPressed: () {
                              _showConfirmationDialog(
                                context,
                                schedule.source,
                                schedule.destination,
                                schedule.routeNo.toString(),
                                widget.day,
                                schedule.startTime,
                              );
                            },
                            child: const Text('Go now'),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
