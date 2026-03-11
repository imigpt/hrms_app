import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../services/face_verification_service.dart';
import '../services/profile_service.dart';
import '../services/token_storage_service.dart';
import '../models/profile_model.dart';

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

  // Profile (for face verification)
  Future<void>? _profileFuture;
  ProfileUser? _userProfile;

  // Face verification state
  bool _faceErrorNoFace = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // Start fetching location and profile in parallel with camera init
    _locationFuture = _fetchLocationAsync();
    _profileFuture = _fetchProfileAsync();
  }

  Future<void> _fetchProfileAsync() async {
    try {
      final token = await TokenStorageService().getToken();
      if (token == null) return;
      final profile = await ProfileService().fetchProfile(token);
      if (mounted) setState(() => _userProfile = profile);
    } catch (e) {
      debugPrint('Camera: profile fetch error — $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found on this device';
          _isLoading = false;
        });
        return;
      }

      // Prefer front camera for selfie
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) setState(() => _isLoading = false);
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
    FaceVerificationService.close();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isSubmitting) return;
    setState(() => _faceErrorNoFace = false);
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _capturedImagePath = image.path;
        });
      }
      if (_capturedLocation == null) _locationFuture = _fetchLocationAsync();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _fetchLocationAsync() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) _updateLocationState(position);
      try {
        final fresh = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
        _updateLocationState(fresh);
      } catch (_) {}
    } catch (e) {
      print('Location error: $e');
    }
  }

  void _updateLocationState(Position position) {
    final dist = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      26.816224,
      75.845444,
    );
    if (mounted) {
      setState(() {
        _capturedLocation = position;
        _capturedAddress = dist <= 100 ? 'Main Building' : 'Outside Building';
      });
    }
  }

  Future<void> _confirmCheckIn() async {
    if (_capturedImagePath == null) return;

    setState(() {
      _isSubmitting = true;
      _faceErrorNoFace = false;
    });

    try {
      // Wait briefly for location if not yet fetched
      if (_capturedLocation == null && _locationFuture != null) {
        await _locationFuture!.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }

      // Wait briefly for profile if not yet loaded
      if (_userProfile == null && _profileFuture != null) {
        await _profileFuture!.timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      }

      // ── On-device face verification ─────────────────────────────────────
      final profilePhotoUrl = _userProfile?.profilePhotoUrl ?? '';
      if (profilePhotoUrl.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _capturedImagePath = null;
        });
        _showFaceError(
          title: 'Profile Photo Missing',
          message:
              'You do not have a profile photo on file.\nPlease upload a profile photo from your profile settings before checking in.',
          icon: Icons.account_circle_outlined,
        );
        return;
      }

      final faceResult = await FaceVerificationService.verify(
        selfieFile: File(_capturedImagePath!),
        profilePhotoUrl: profilePhotoUrl,
      );

      if (!faceResult.verified) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _capturedImagePath = null;
          _capturedLocation = null;
        });
        switch (faceResult.reason) {
          case 'no_face_in_selfie':
            setState(() => _faceErrorNoFace = true);
            _showFaceError(
              title: 'No Face Detected',
              message:
                  'We could not detect a face in your photo.\nPlease ensure your face is clearly visible and well-lit.',
              icon: Icons.no_photography,
            );
          case 'no_face_in_profile':
            _showFaceError(
              title: 'Profile Photo Issue',
              message:
                  'No face detected in your profile photo.\nPlease update your profile photo with a clear frontal photo.',
              icon: Icons.account_circle_outlined,
            );
          case 'profile_download_failed':
            _showFaceError(
              title: 'Verification Unavailable',
              message:
                  'Could not load your profile photo for verification.\nPlease check your internet connection and try again.',
              icon: Icons.cloud_off_outlined,
            );
          default:
            _showFaceError(
              title: 'Face Not Matched',
              message:
                  'Your face could not be verified (match score: ${faceResult.similarityScore}%).\n'
                  'Ensure good lighting and face the camera directly, then try again.',
              icon: Icons.face_retouching_off,
            );
        }
        return;
      }
      // ── Face verified — return photo + location for BOD + check-in ──────
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, {
          'photoFile': File(_capturedImagePath!),
          'latitude': _capturedLocation?.latitude ?? 26.816224,
          'longitude': _capturedLocation?.longitude ?? 75.845444,
          'address': _capturedAddress ?? 'Main Building',
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showFaceError({
    required String title,
    required String message,
    required IconData icon,
    bool isWarning = false,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          icon,
          color: isWarning ? Colors.orangeAccent : Colors.redAccent,
          size: 48,
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!isWarning) {
                // For face errors, allow retake
                _retakePhoto();
              } else {
                // For leave errors, go back to attendance screen
                Navigator.pop(context);
              }
            },
            child: Text(
              isWarning ? 'Go Back' : 'Retake',
              style: TextStyle(
                color: isWarning ? Colors.orangeAccent : const Color(0xFFFF8B94),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
      _capturedLocation = null;
      _faceErrorNoFace = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
          ? _buildErrorView()
          : SafeArea(
              child: _capturedImagePath != null
                  ? _buildPhotoPreview()
                  : _buildCameraView(),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
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
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context, false),
              ),
              const Spacer(),
              const Text(
                'Face Check-In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // balance close button
            ],
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            _faceErrorNoFace
                ? 'No face detected — ensure your face is well-lit and centred'
                : 'Centre your face in the oval and tap Capture',
            style: TextStyle(
              color: _faceErrorNoFace ? Colors.orangeAccent : Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 12),

        // Camera preview with face oval guide
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera view
                  if (_controller != null)
                    CameraPreview(_controller!)
                  else
                    Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

                  // Face oval overlay
                  CustomPaint(
                    painter: _FaceOvalPainter(
                      borderColor: _faceErrorNoFace
                          ? Colors.orangeAccent
                          : const Color(0xFFFF8B94),
                    ),
                  ),

                  // Corner label
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Live selfie for face verification',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Cancel
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

              // Capture
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _takePicture,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFF8B94),
                    disabledBackgroundColor:
                        const Color(0xFFFF8B94).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
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
          // Top bar
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed:
                  _isSubmitting ? null : () => Navigator.pop(context, false),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Photo Captured!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Your selfie will be verified against your profile photo.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 24),

          // Photo card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Thumbnail + retake button
                Stack(
                  clipBehavior: Clip.none,
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
                      top: -10,
                      right: -10,
                      child: GestureDetector(
                        onTap: _isSubmitting ? null : _retakePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Face verification hint
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.face, color: Colors.white54, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Selfie ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Face recognition will run on the server',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submitting progress indicator
          if (_isSubmitting)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8B94),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Verifying your face…',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirmCheckIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFFF8B94),
                disabledBackgroundColor:
                    const Color(0xFFFF8B94).withValues(alpha: 0.5),
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
                  : const Icon(Icons.verified_user, color: Colors.white, size: 22),
              label: Text(
                _isSubmitting ? 'Verifying…' : 'Verify Face',
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

/// Draws a semi-transparent dark overlay with an oval cutout for face framing.
class _FaceOvalPainter extends CustomPainter {
  final Color borderColor;
  const _FaceOvalPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: size.width * 0.62,
      height: size.height * 0.58,
    );

    // Dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill,
    );

    // Oval border
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_FaceOvalPainter old) => old.borderColor != borderColor;
}
