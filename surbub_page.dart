import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:duplicate/driver/models/bus_schedule_model.dart';
import 'package:duplicate/driver/pages/routes_page.dart';
import 'package:duplicate/driver/buttons/ReusableButton.dart';

class SuburbsPage extends StatefulWidget {
  const SuburbsPage({Key? key}) : super(key: key);

  @override
  State<SuburbsPage> createState() => _SuburbsPageState();
}

class _SuburbsPageState extends State<SuburbsPage> {
  List<BusSchedule> suburbs = [];
  List<BusSchedule> filteredSuburbs = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    getSuburbs();
  }

  Future<void> getSuburbs() async {
    final url = 'http://102.135.162.160:2003/api/ManageSchedule';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        List<BusSchedule> schedules =
            data.map((item) => BusSchedule.fromJson(item)).toList();

        setState(() {
          suburbs = removeDuplicates(schedules);
          filteredSuburbs = suburbs; // Start with the unique list
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print(e);
    }
  }

  List<BusSchedule> removeDuplicates(List<BusSchedule> list) {
    Set<String> suburbNames = Set();
    List<BusSchedule> uniqueSuburbs = [];

    for (var suburb in list) {
      if (!suburbNames.contains(suburb.surburb.toLowerCase())) {
        suburbNames.add(suburb.surburb.toLowerCase());
        uniqueSuburbs.add(suburb);
      }
    }

    return uniqueSuburbs;
  }

  void filterSuburbs(String query) {
    setState(() {
      searchText = query;
      if (query.isNotEmpty) {
        filteredSuburbs = suburbs
            .where((suburb) =>
                suburb.surburb.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        filteredSuburbs = suburbs; // Reset to the unique list if query is empty
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      "Which suburb are you driving from today?",
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
                          filterSuburbs(value);
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search suburb...',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
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
                    constraints:
                        BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                    child: DataTable(
                      columnSpacing: 32.0,
                      columns: const [
                        DataColumn(
                          label: SizedBox(
                            width: 200,
                            child: Text(
                              'Suburb',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(
                              'Select',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                      rows: filteredSuburbs.map((suburb) {
                        return DataRow(cells: [
                          DataCell(Text(suburb.surburb)),
                          DataCell(
                            ReusableButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MyRoutesPage(
                                      suburb: suburb.surburb,
                                      destination: suburb.destination,
                                      source: suburb.source,
                                      routeNo: suburb.routeNo,
                                      day: suburb.day,
                                      time: suburb.startTime,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Select'),
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
      ),
    );
  }
}
