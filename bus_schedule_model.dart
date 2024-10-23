class BusSchedule {
  final String routeNo;
  final String surburb;
  final String source;
  final String destination;
  final String startTime;
  final String day;

  BusSchedule({
    required this.routeNo,
    required this.source,
    required this.surburb,
    required this.destination,
    required this.startTime,
    required this.day,
  });

 factory BusSchedule.fromJson(Map<String, dynamic> json) {
  return BusSchedule(
    surburb: json['suburb'],
    routeNo: json['routeNo'].toString(),
    source: json['source'],
    destination: json['destination'],
    startTime: json['startTime'],
    day: json['day'],
  );
}
}
