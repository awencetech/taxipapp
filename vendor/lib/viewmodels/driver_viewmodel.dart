import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class DriverViewModel extends ChangeNotifier {
  final ApiService _apiService;
  IO.Socket? _socket;

  bool _isLoading = false;
  bool _isFetching = false;
  List<Driver> _drivers = [];
  List<Driver> _pendingDrivers = [];
  String? _errorMessage;

  // Filter and search
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedVehicleTypeFilter = 'All';
  String _selectedCityFilter = 'All';
  String _sortBy = 'newest';

  // Auto refresh timer
  Timer? _refreshTimer;

  DriverViewModel({required ApiService apiService}) : _apiService = apiService {
    startAutoRefresh();
    initSocket();
  }

  // Initialize Socket.IO connection for realtime updates
  void initSocket() {
    try {
      _socket = IO.io(
        AppConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Use websocket transport
            .disableAutoConnect() // Don't auto connect
            .build(),
      );

      // Listen for connection
      _socket?.onConnect((_) async {
        debugPrint('Vendor connected to Socket.io');
        // Get vendor id from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final vendorId = prefs.getString(AppConstants.vendorIdKey);
        if (vendorId != null) {
          joinVendorRoom(vendorId);
        }
      });

      // Listen for driver status changes
      _socket?.on('driverStatusChanged', (data) {
        debugPrint('Received driverStatusChanged event: $data');
        _handleDriverStatusChange(data);
      });

      // Listen for errors
      _socket?.on('connect_error', (error) {
        debugPrint('Socket connection error: $error');
      });

      _socket?.connect();
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  // Join vendor room after getting vendor id
  void joinVendorRoom(String vendorId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('joinVendor', vendorId);
      debugPrint('Joined vendor room for $vendorId');
    } else {
      debugPrint('Socket not connected, cannot join vendor room');
    }
  }

  // Handle driver status change
  Future<void> _handleDriverStatusChange(dynamic data) async {
    try {
      final String driverId = data['driverId'];
      final bool isOnline = data['isOnline'] ?? false;
      final String status = data['status'] ?? 'offline';
      final bool isBusy = data['isBusy'] ?? false;

      debugPrint('Handling driverStatusChanged: driverId=$driverId, isOnline=$isOnline, status=$status, isBusy=$isBusy');

      // Find the driver in our list and update their status
      final index = _drivers.indexWhere((d) => d.id == driverId);
      if (index != -1) {
        final existingDriver = _drivers[index];
        _drivers[index] = existingDriver.copyWith(
          isOnline: isOnline,
          status: status,
          isBusy: isBusy,
        );
        notifyListeners();
        debugPrint('Updated driver $driverId status: online=$isOnline, busy=$isBusy');
        return;
      }

      // Driver not present locally — fetch single driver and insert/update
      debugPrint('Driver $driverId not found locally. Attempting single-driver fetch.');
      final fetched = await fetchDriverById(driverId);
      if (fetched != null) {
        final updated = fetched.copyWith(
          isOnline: isOnline,
          status: status,
          isBusy: isBusy,
        );
        final existingIndex = _drivers.indexWhere((d) => d.id == updated.id);
        if (existingIndex != -1) {
          _drivers[existingIndex] = updated;
        } else {
          _drivers.insert(0, updated);
        }
        notifyListeners();
        debugPrint('Inserted/updated driver $driverId into local list');
        return;
      }

      // If single fetch didn't succeed, fallback to full refresh
      debugPrint('Single-driver fetch failed for $driverId; falling back to fetchDrivers()');
      fetchDrivers();
    } catch (e) {
      debugPrint('Error handling driver status change: $e');
    }
  }

  // Fetch a single driver by id from vendor API
  Future<Driver?> fetchDriverById(String driverId) async {
    try {
      final path = AppConstants.vendorDriverByIdUrl.replaceFirst(':id', driverId);
      debugPrint('Fetching single driver from $path');
      final response = await _apiService.get(path);
      if (response.statusCode == 200) {
        final data = response.data;
        // Backend returns the driver object directly or nested — handle both
        final driverJson = (data is Map && data['driver'] != null) ? data['driver'] : data;
        if (driverJson != null) {
          final driver = Driver.fromJson(Map<String, dynamic>.from(driverJson));
          debugPrint('Fetched driver ${driver.id} successfully');
          return driver;
        }
      }
    } catch (e) {
      debugPrint('Error fetching driver by id $driverId: $e');
    }
    return null;
  }

  bool get isLoading => _isLoading;
  List<Driver> get drivers => _filteredDrivers;
  List<Driver> get pendingDrivers => _pendingDrivers;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedVehicleTypeFilter => _selectedVehicleTypeFilter;
  String get selectedCityFilter => _selectedCityFilter;
  String get sortBy => _sortBy;

  // Get filtered drivers
  List<Driver> get _filteredDrivers {
    List<Driver> filtered = List.from(_drivers);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((d) {
        return (d.name.toLowerCase().contains(q)) ||
            (d.driverId?.toLowerCase().contains(q) ?? false) ||
            (d.phone.contains(q)) ||
            (d.vehicleNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != 'All') {
      filtered = filtered.where((d) {
        final status = d.status.toLowerCase();
        final approvalStatus = d.approvalStatus?.toLowerCase() ?? '';
        final accountStatus = d.accountStatus?.toLowerCase() ?? '';
        final isApproved = d.isApproved == true;
        final isOnline = d.isOnline == true;
        final isBusy = d.isBusy == true;

        switch (_selectedStatusFilter) {
          case 'Pending Approval':
            return !isApproved &&
                status != 'rejected' &&
                approvalStatus != 'rejected' &&
                accountStatus != 'rejected';
          case 'Approved':
            return isApproved;
          case 'Rejected':
            return status == 'rejected' ||
                approvalStatus == 'rejected' ||
                accountStatus == 'rejected';
          case 'Online':
            return isApproved && isOnline && !isBusy;
          case 'Offline':
            return isApproved && !isOnline;
          case 'Busy':
            return isApproved && isBusy;
          case 'Suspended':
            return accountStatus == 'suspended' || status == 'suspended';
          default:
            return true;
        }
      }).toList();
    }

    // Apply vehicle type filter
    if (_selectedVehicleTypeFilter != 'All') {
      filtered = filtered
          .where((d) => d.vehicleType == _selectedVehicleTypeFilter)
          .toList();
    }

    // Apply city filter
    if (_selectedCityFilter != 'All') {
      filtered = filtered.where((d) => d.city == _selectedCityFilter).toList();
    }

    // Apply sort
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highestRating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'mostTrips':
        filtered.sort((a, b) => b.totalRides.compareTo(a.totalRides));
        break;
      case 'highestEarnings':
        filtered.sort(
          (a, b) => (b.totalEarnings ?? 0).compareTo(a.totalEarnings ?? 0),
        );
        break;
      case 'nameAsc':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return filtered;
  }

  // Get available vehicle types from drivers
  Set<String> get availableVehicleTypes {
    final types = <String>{'All'};
    for (final d in _drivers) {
      if (d.vehicleType != null) {
        types.add(d.vehicleType!);
      }
    }
    return types;
  }

  // Get available cities from drivers
  Set<String> get availableCities {
    final cities = <String>{'All'};
    for (final d in _drivers) {
      if (d.city != null) {
        cities.add(d.city!);
      }
    }
    return cities;
  }

  // Dashboard stats
  int get totalDriversCount => _drivers.length;
  int get approvedDriversCount =>
      _drivers.where((d) => d.isApproved == true).length;
  int get pendingDriversCount => _drivers
      .where(
        (d) =>
            d.isApproved != true &&
            d.status.toLowerCase() != 'rejected' &&
            (d.accountStatus?.toLowerCase() != 'rejected') &&
            (d.approvalStatus?.toLowerCase() != 'rejected'),
      )
      .length;
  int get onlineDriversCount => _drivers
      .where(
        (d) => d.isApproved == true && d.isOnline == true && d.isBusy != true,
      )
      .length;
  int get offlineDriversCount =>
      _drivers.where((d) => d.isApproved == true && d.isOnline != true).length;
  int get busyDriversCount =>
      _drivers.where((d) => d.isApproved == true && d.isBusy == true).length;
  int get suspendedDriversCount => _drivers
      .where(
        (d) =>
            (d.accountStatus?.toLowerCase() == 'suspended') ||
            (d.status.toLowerCase() == 'suspended'),
      )
      .length;

  // Set search
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set status filter
  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  // Set vehicle type filter
  void setVehicleTypeFilter(String type) {
    _selectedVehicleTypeFilter = type;
    notifyListeners();
  }

  // Set city filter
  void setCityFilter(String city) {
    _selectedCityFilter = city;
    notifyListeners();
  }

  // Set sort
  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedStatusFilter = 'All';
    _selectedVehicleTypeFilter = 'All';
    _selectedCityFilter = 'All';
    notifyListeners();
  }

  // Auto refresh
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchDrivers(),
    );
  }

  // Fetch drivers
  Future<void> fetchDrivers() async {
    if (_isFetching) return;

    _isFetching = true;
    _isLoading = _drivers.isEmpty;
    _errorMessage = null;
    if (_isLoading) notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorDriversUrl);
      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          _drivers = data.map((json) => Driver.fromJson(json)).toList();
        } else {
          _errorMessage = 'Invalid response format';
          _drivers = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      _errorMessage = e.toString();
      _drivers = [];
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingDrivers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        AppConstants.vendorPendingDriversUrl,
      );
      if (response.statusCode == 200) {
        // Safely check nested structure
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true && data['data'] is Map<String, dynamic>) {
            final innerData = data['data'] as Map<String, dynamic>;
            if (innerData['drivers'] is List) {
              final List<dynamic> driversList = innerData['drivers'];
              _pendingDrivers = driversList
                  .map((json) => Driver.fromJson(json))
                  .toList();
            } else {
              _errorMessage = 'Invalid response format: drivers not a list';
              _pendingDrivers = [];
            }
          } else {
            _errorMessage = 'Invalid response format: missing data';
            _pendingDrivers = [];
          }
        } else {
          _errorMessage = 'Invalid response format';
          _pendingDrivers = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending drivers: $e');
      _errorMessage = e.toString();
      _pendingDrivers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDriver(Map<String, dynamic> driverData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.vendorAddDriverUrl,
        data: driverData,
      );
      if (response.statusCode == 201) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDriver(String driverId) async {
    try {
      final response = await _apiService.delete(
        '${AppConstants.vendorDriversUrl}/$driverId',
      );
      if (response.statusCode == 200) {
        _drivers.removeWhere((d) => d.id == driverId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> approveDriver(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        AppConstants.vendorApproveDriverUrl.replaceFirst(':id', driverId),
      );
      if (response.statusCode == 200) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectDriver(String driverId, String rejectionReason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        AppConstants.vendorRejectDriverUrl.replaceFirst(':id', driverId),
        data: {'rejectionReason': rejectionReason},
      );
      if (response.statusCode == 200) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> suspendDriver(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${AppConstants.vendorDriversUrl}/$driverId/suspend',
      );
      if (response.statusCode == 200) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activateDriver(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${AppConstants.vendorDriversUrl}/$driverId/activate',
      );
      if (response.statusCode == 200) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDriver(String driverId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.put(
        AppConstants.vendorUpdateDriverUrl.replaceFirst(':id', driverId),
        data: data,
      );
      if (response.statusCode == 200) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
