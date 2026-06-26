import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/place_details_model.dart';

class KeepAliveMap extends StatefulWidget {
  final PlaceDetails? pickupLocation;
  final PlaceDetails? dropLocation;
  final List<LatLng> polylinePoints;
  final Function(GoogleMapController)? onMapCreated;

  const KeepAliveMap({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.polylinePoints,
    this.onMapCreated,
  });

  @override
  State<KeepAliveMap> createState() => _KeepAliveMapState();
}

class _KeepAliveMapState extends State<KeepAliveMap>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  LatLng? _lastPickupLatLng;
  LatLng? _lastDropLatLng;

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  
  Timer? _pickupTimer;
  Timer? _dropTimer;
  Timer? _cameraFitTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initCustomMarkers().then((_) {
      _updateMapData(forceAnimate: true);
    });
  }

  @override
  void dispose() {
    _pickupTimer?.cancel();
    _dropTimer?.cancel();
    _cameraFitTimer?.cancel();
    super.dispose();
  }

  Future<void> _initCustomMarkers() async {
    _pickupIcon = await _createMarkerIcon(Colors.green, 'P');
    _dropIcon = await _createMarkerIcon(Colors.red, 'D');
  }

  Future<BitmapDescriptor> _createMarkerIcon(Color color, String label) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double width = 120.0;
    const double height = 120.0;

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(const Offset(60, 95), 12, shadowPaint);

    // Draw main pin shape
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(60, 110);
    path.cubicTo(85, 80, 95, 65, 95, 45);
    path.arcToPoint(
      const Offset(25, 45),
      radius: const Radius.circular(35),
      clockwise: false,
    );
    path.cubicTo(25, 65, 35, 80, 60, 110);
    path.close();
    canvas.drawPath(path, paint);

    // Draw white border for inner circle
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(60, 45), 20, borderPaint);

    // Draw inner colored dot
    final Paint innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(60, 45), 12, innerPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  @override
  void didUpdateWidget(covariant KeepAliveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final pickupChanged = widget.pickupLocation?.latitude != oldWidget.pickupLocation?.latitude ||
        widget.pickupLocation?.longitude != oldWidget.pickupLocation?.longitude;
    final dropChanged = widget.dropLocation?.latitude != oldWidget.dropLocation?.latitude ||
        widget.dropLocation?.longitude != oldWidget.dropLocation?.longitude;
    final polylineChanged = widget.polylinePoints.length != oldWidget.polylinePoints.length ||
        (widget.polylinePoints.isNotEmpty && oldWidget.polylinePoints.isNotEmpty && 
         widget.polylinePoints.first != oldWidget.polylinePoints.first);

    if (pickupChanged || dropChanged || polylineChanged) {
      _updateMapData(
        pickupChanged: pickupChanged,
        dropChanged: dropChanged,
        polylineChanged: polylineChanged,
      );
    }
  }

  void _updateMapData({
    bool pickupChanged = false,
    bool dropChanged = false,
    bool polylineChanged = false,
    bool forceAnimate = false,
  }) {
    if (_pickupIcon == null || _dropIcon == null) return;

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    final isAnimatingPickup = pickupChanged || forceAnimate || _lastPickupLatLng == null;
    final isAnimatingDrop = dropChanged || forceAnimate || _lastDropLatLng == null;

    // Handle Pickup Marker & Slide-down Animation
    if (widget.pickupLocation != null) {
      final targetLatLng = LatLng(
        widget.pickupLocation!.latitude,
        widget.pickupLocation!.longitude,
      );

      if (isAnimatingPickup) {
        _lastPickupLatLng = targetLatLng;
        _pickupTimer?.cancel();
        
        // Remove immediately to avoid duplicate/overlapping marker states
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'pickup');
        });

        // Start slide-down drop animation
        const steps = 15;
        double currentStep = 0;
        final startLat = targetLatLng.latitude + 0.008; // Start slightly above

        _pickupTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
          if (currentStep >= steps || !mounted) {
            timer.cancel();
            _setMarker(targetLatLng, true);
            _fitCameraBounds();
            return;
          }
          final progress = currentStep / steps;
          final currentLat = startLat + (targetLatLng.latitude - startLat) * progress;
          _setMarker(LatLng(currentLat, targetLatLng.longitude), true);
          currentStep++;
        });
      } else {
        markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: targetLatLng,
          icon: _pickupIcon!,
          anchor: const Offset(0.5, 0.92),
        ));
      }
    }

    // Handle Drop Marker & Slide-down Animation
    if (widget.dropLocation != null) {
      final targetLatLng = LatLng(
        widget.dropLocation!.latitude,
        widget.dropLocation!.longitude,
      );

      if (isAnimatingDrop) {
        _lastDropLatLng = targetLatLng;
        _dropTimer?.cancel();

        // Remove immediately to avoid duplicate/overlapping marker states
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'drop');
        });
        
        // Start slide-down drop animation
        const steps = 15;
        double currentStep = 0;
        final startLat = targetLatLng.latitude + 0.008; // Start slightly above

        _dropTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
          if (currentStep >= steps || !mounted) {
            timer.cancel();
            _setMarker(targetLatLng, false);
            _fitCameraBounds();
            return;
          }
          final progress = currentStep / steps;
          final currentLat = startLat + (targetLatLng.latitude - startLat) * progress;
          _setMarker(LatLng(currentLat, targetLatLng.longitude), false);
          currentStep++;
        });
      } else {
        markers.add(Marker(
          markerId: const MarkerId('drop'),
          position: targetLatLng,
          icon: _dropIcon!,
          anchor: const Offset(0.5, 0.92),
        ));
      }
    }

    // Draw Polyline
    if (widget.polylinePoints.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: widget.polylinePoints,
        color: const Color(0xFF1976D2),
        width: 7,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ));
    }

    setState(() {
      _polylines.clear();
      _polylines.addAll(polylines);
      
      // Update markers that are not being animated
      if (!isAnimatingPickup && widget.pickupLocation != null) {
        _markers.removeWhere((m) => m.markerId.value == 'pickup');
        _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLocation!.latitude, widget.pickupLocation!.longitude),
          icon: _pickupIcon!,
          anchor: const Offset(0.5, 0.92),
        ));
      }
      if (!isAnimatingDrop && widget.dropLocation != null) {
        _markers.removeWhere((m) => m.markerId.value == 'drop');
        _markers.add(Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(widget.dropLocation!.latitude, widget.dropLocation!.longitude),
          icon: _dropIcon!,
          anchor: const Offset(0.5, 0.92),
        ));
      }
    });

    if (polylineChanged || forceAnimate) {
      _fitCameraBounds();
    }
  }

  void _setMarker(LatLng position, bool isPickup) {
    if (!mounted) return;
    setState(() {
      final markerId = MarkerId(isPickup ? 'pickup' : 'drop');
      _markers.removeWhere((m) => m.markerId == markerId);
      _markers.add(Marker(
        markerId: markerId,
        position: position,
        icon: isPickup ? _pickupIcon! : _dropIcon!,
        anchor: const Offset(0.5, 0.92),
      ));
    });
  }

  void _fitCameraBounds() {
    if (_mapController == null) return;
    
    final List<LatLng> boundsPoints = [];
    if (widget.pickupLocation != null) {
      boundsPoints.add(LatLng(widget.pickupLocation!.latitude, widget.pickupLocation!.longitude));
    }
    if (widget.dropLocation != null) {
      boundsPoints.add(LatLng(widget.dropLocation!.latitude, widget.dropLocation!.longitude));
    }
    if (widget.polylinePoints.isNotEmpty) {
      boundsPoints.addAll(widget.polylinePoints);
    }

    if (boundsPoints.isEmpty) return;

    double minLat = boundsPoints.first.latitude;
    double maxLat = boundsPoints.first.latitude;
    double minLng = boundsPoints.first.longitude;
    double maxLng = boundsPoints.first.longitude;

    for (var point in boundsPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Dynamic Zoom Bounds Safe Padding
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    if (latSpan < 0.005 && lngSpan < 0.005) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      minLat = centerLat - 0.0025;
      maxLat = centerLat + 0.0025;
      minLng = centerLng - 0.0025;
      maxLng = centerLng + 0.0025;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Debounce/delay the camera fit to ensure Google Map web container has finished its layout sizing.
    _cameraFitTimer?.cancel();
    _cameraFitTimer = Timer(const Duration(milliseconds: 250), () {
      if (_mapController != null && mounted) {
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final initialTarget = widget.pickupLocation != null
        ? LatLng(widget.pickupLocation!.latitude, widget.pickupLocation!.longitude)
        : const LatLng(11.0168, 76.9558);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 14,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
        _updateMapData(forceAnimate: true);
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
    );
  }
}
