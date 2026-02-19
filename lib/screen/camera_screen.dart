import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/attendance_service.dart';
import '../services/token_storage_service.dart';
import '../widgets/location_permission_dialog.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isLoading = true;
  String? _error;
  String? _capturedImagePath;
  Position? _capturedLocation;
  String? _capturedAddress;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found on this device';
          _isLoading = false;
        });
        return;
      }

      // Get the front camera for selfie, or first available camera
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Create and initialize the camera controller
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services to mark attendance'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check current location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current location permission: $permission');
      
      // ALWAYS show our custom dialog first (except if already granted)
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Show custom dialog to explain why we need location
        if (mounted) {
          final shouldRequest = await LocationPermissionDialog.show(
            context, 
            isPermanentlyDenied: permission == LocationPermission.deniedForever
          );
          print('Dialog result: $shouldRequest');
          
          if (shouldRequest == null) {
            print('User cancelled');
            return;
          }
          
          if (permission == LocationPermission.deniedForever) {
            // User needs to go to settings
            return;
          }
          
          if (shouldRequest == true) {
            // User clicked "Enable", now request permission from system
            permission = await Geolocator.requestPermission();
            print('Permission after request: $permission');
            
            if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
              print('Permission denied by user');
              return;
            }
          } else {
            return;
          }
        }
      }

      // Ensure the camera is initialized
      await _initializeControllerFuture;

      // Take the picture first
      final image = await _controller!.takePicture();
      print('Photo captured: ${image.path}');

      // Get current location after photo is taken
      print('Getting current location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Location captured: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates using reverse geocoding
      String address = 'Address not found';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          
          // Build address string from placemark
          List<String> addressParts = [];
          if (placemark.name != null && placemark.name!.isNotEmpty) {
            addressParts.add(placemark.name!);
          }
          if (placemark.street != null && placemark.street!.isNotEmpty && 
              placemark.street != placemark.name) {
            addressParts.add(placemark.street!);
          }
          if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
            addressParts.add(placemark.subLocality!);
          }
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            addressParts.add(placemark.locality!);
          }
          if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
            addressParts.add(placemark.administrativeArea!);
          }
          
          address = addressParts.take(3).join(', '); // Take first 3 parts to keep it concise
          if (address.isEmpty) {
            address = '${placemark.locality ?? 'Unknown'}, ${placemark.administrativeArea ?? 'Unknown'}';
          }
        }
        print('Address resolved: $address');
      } catch (e) {
        print('Error getting address: $e');
        // Keep default "Address not found" if reverse geocoding fails
      }

      if (mounted) {
        setState(() {
          _capturedImagePath = image.path;
          _capturedLocation = position;
          _capturedAddress = address;
        });
      }
    } catch (e) {
      print('Error in _takePicture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmCheckIn() async {
    if (_capturedImagePath == null || _capturedLocation == null || _capturedAddress == null) {
      print('ERROR: Check-in failed - missing photo, location, or address');
      print('Photo path: $_capturedImagePath');
      print('Location: $_capturedLocation');
      print('Address: $_capturedAddress');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing photo or location data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      print('=== Starting Check-In ===');
      print('Photo path: $_capturedImagePath');
      print('Location: Lat=${_capturedLocation!.latitude}, Long=${_capturedLocation!.longitude}');
      
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      // Get token from storage
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      print('Token retrieved: ${token.substring(0, 20)}...');

      // Call the check-in API with location data
      print('Calling check-in API with location...');
      final response = await AttendanceService.checkIn(
        token: token,
        photoFile: File(_capturedImagePath!),
        latitude: _capturedLocation!.latitude,
        longitude: _capturedLocation!.longitude,
      );
      
      print('Check-in API response received');
      print('Response message: ${response.message}');

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Wait a moment for the snackbar
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Return attendance data with address to caller
        if (mounted) {
          // Include the human-readable address with the response data
          final dataWithAddress = {
            'attendanceData': response.data,
            'checkInAddress': _capturedAddress,
          };
          Navigator.pop(context, dataWithAddress);
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if open
        try {
          Navigator.pop(context);
        } catch (_) {}
        
        String errorMessage = e.toString();
        
        // Check if user is already checked in
        if (errorMessage.toLowerCase().contains('already checked in')) {
          // Show a message and go back - user is already checked in on backend
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already checked in. Refreshing...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Wait a moment for the snackbar
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Return "refresh" signal to dashboard
          if (mounted) {
            Navigator.pop(context, 'refresh');
          }
        } else {
          // Show regular error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Check-in failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
      _capturedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: _capturedImagePath != null
                      ? _buildPhotoPreview()
                      : _buildCameraView(),
                ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        // Close button in top right
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),

        const SizedBox(height: 20),

        // Title
        const Text(
          'Capture Check-in Photo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        // Instructions
        const Text(
          'Position yourself in the frame and click capture',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 30),

        // Camera Preview in rounded container
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[900],
            ),
            clipBehavior: Clip.hardEdge,
            child: _controller != null
                ? CameraPreview(_controller!)
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 30),

        // Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Capture Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePicture,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFF8B94),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: const Text(
                    'Capture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          const Text(
            'Photo Captured!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Click "Confirm Check In" to proceed',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 30),

          // Photo Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Photo thumbnail with delete button
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_capturedImagePath!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        onPressed: _retakePhoto,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Photo ready text
                const Text(
                  'Photo ready',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Confirm Check In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmCheckIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFFF8B94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.login,
                color: Colors.white,
                size: 22,
              ),
              label: const Text(
                'Confirm Check In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
