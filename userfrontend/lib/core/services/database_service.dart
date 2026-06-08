import '../models/driver_model.dart';
import '../models/ride_model.dart';
import 'api_service.dart';
import 'socket_service.dart';

class DatabaseService {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  Stream<List<RideModel>> streamUserRides(String userId) {
    return Stream.value([]);
  }

  Stream<List<DriverModel>> streamNearbyDrivers() {
    return _socketService.driverLocationStream.map((data) {
      return [DriverModel.fromMap({...data, 'id': data['driverId']})];
    });
  }

  Future<List<DriverModel>> getNearbyDrivers() async {
    final response = await _apiService.getNearbyDrivers();
    if (response.statusCode == 200) {
      List data = response.data['data']['drivers'];
      return data.map((d) => DriverModel.fromMap(d)).toList();
    }
    return [];
  }
}
