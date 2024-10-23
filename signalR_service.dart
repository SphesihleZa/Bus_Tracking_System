import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;
  final String _hubUrl = 'http://102.135.162.160:2003/routeHub';

  void connect(Function(Trips?) onMessageReceived) {
    print('Initializing SignalR connection...');
    _connection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .build();

    final connection = _connection;

    if (connection != null) {
      connection.on('ReceiveCoordinate', (args) {
        print('Received data from SignalR: $args');
        if (args != null && args.isNotEmpty) {
          print('First argument from SignalR: ${args[0]}');
          final coordinate = args[0] as Map<String, dynamic>;
          try {
            final trips = Trips.fromJson(coordinate);
            print('Parsed trips data: $trips');
            onMessageReceived(trips);
          } catch (e) {
            print('Error parsing received data: $e');
          }
        } else {
          print('Received empty or null data from SignalR.');
        }
      });

      connection.start()?.then((_) {
        print('SignalR connection established');
      }).catchError((error) {
        print('SignalR connection failed: $error');
      });
    } else {
      print('Connection is not initialized.');
    }
  }

  void disconnect() {
    final connection = _connection;

    if (connection != null) {
      connection.stop().then((_) {
        print('Connection stopped');
      }).catchError((error) {
        print('Disconnection failed: $error');
      });
    } else {
      print('No active connection to disconnect.');
    }
  }
}

class Trips {
  final String latitude;
  final String longitude;
  final String routeNo;

  Trips({
    required this.latitude,
    required this.longitude,
    required this.routeNo,
  });

  factory Trips.fromJson(Map<String, dynamic> json) {
    return Trips(
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      routeNo: json['routeNo'] as String,
    );
  }

  @override
  String toString() {
    return 'Trips(latitude: $latitude, longitude: $longitude, routeNo: $routeNo)';
  }
}
