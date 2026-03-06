import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../services/attendance_service.dart';
import '../services/token_storage_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _capturedImagePath;
  Position? _capturedLocation;
  String? _capturedAddress;
  Future<void>? _locationFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // Start fetching location immediately (parallel with camera init)
    _locationFuture = _fetchLocationAsync();
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
    if (_isSubmitting) return;
    try {
      // Permission already checked in attendance_screen - just take photo
      await _initializeControllerFuture;

      // Take the picture instantly
      final image = await _controller!.takePicture();

      // Show preview immediately
      if (mounted) {
        setState(() {
          _capturedImagePath = image.path;
        });
      }

      // If location not yet available, start fresh fetch
      if (_capturedLocation == null) {
        _locationFuture = _fetchLocationAsync();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (e.toString().toLowerCase().contains('already checked in')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Already checked in. Refreshing...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) Navigator.pop(context, 'refresh');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // Fetch location FAST in background
  Future<void> _fetchLocationAsync() async {
    try {
      // Try last known position first (INSTANT)
      Position? position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        _updateLocationState(position);
      }

      // Then get fresh position with timeout (don't block)
      try {
        final freshPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
        _updateLocationState(freshPosition);
      } catch (_) {
        // Timeout or error - use last known if we got it
        if (position == null) {
          print('No location available');
        }
      }
    } catch (e) {
      print('Location error: $e');
    }
  }

  void _updateLocationState(Position position) {
    final double distMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      26.816224,
      75.845444,
    );
    final String locationLabel = distMeters <= 100
        ? 'Main Building'
        : 'Outside Building';

    if (mounted) {
      setState(() {
        _capturedLocation = position;
        _capturedAddress = locationLabel;
      });
    }
  }

  Future<void> _confirmCheckIn() async {
    if (_capturedImagePath == null) return;

    try {
      setState(() => _isSubmitting = true);

      // Quick wait for location (max 2 sec), use fallback if not available
      if (_capturedLocation == null && _locationFuture != null) {
        await _locationFuture!.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }

      // Use office location as fallback if no GPS
      final double lat = _capturedLocation?.latitude ?? 26.816224;
      final double lng = _capturedLocation?.longitude ?? 75.845444;
      final String address = _capturedAddress ?? 'Main Building';

      // Get token
      final token = await TokenStorageService().getToken();
      if (token == null) throw Exception('No token found');

      // Call check-in API
      final response = await AttendanceService.checkIn(
        token: token,
        photoFile: File(_capturedImagePath!),
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, {
          'attendanceData': response.data,
          'checkInAddress': address,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);

        if (e.toString().toLowerCase().contains('already checked in')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Already checked in!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) Navigator.pop(context, 'refresh');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Check-in failed: ${e.toString().replaceAll('Exception:', '').trim()}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
          style: TextStyle(color: Colors.white70, fontSize: 14),
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
                    child: CircularProgressIndicator(color: Colors.white),
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
                  onPressed: _isSubmitting ? null : _takePicture,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFF8B94),
                    disabledBackgroundColor: const Color(
                      0xFFFF8B94,
                    ).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Capture',
                    style: const TextStyle(
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
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.pop(context, false),
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
            style: TextStyle(color: Colors.white70, fontSize: 14),
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
                        onPressed: _isSubmitting ? null : _retakePhoto,
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
              onPressed: _isSubmitting ? null : _confirmCheckIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFFF8B94),
                disabledBackgroundColor: const Color(
                  0xFFFF8B94,
                ).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.login, color: Colors.white, size: 22),
              label: Text(
                _isSubmitting ? 'Checking in...' : 'Confirm Check In',
                style: const TextStyle(
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
