// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Minimum similarity score (0–100) required to pass verification.
/// Raise this value to be stricter; lower it to be more lenient.
const int _kThreshold = 75;

class FaceVerificationResult {
  final bool verified;

  /// 0–100 similarity score (higher = more similar faces).
  final int similarityScore;

  /// 'match' | 'mismatch' | 'no_face_in_selfie' |
  /// 'no_face_in_profile' | 'profile_download_failed'
  final String reason;

  const FaceVerificationResult({
    required this.verified,
    required this.similarityScore,
    required this.reason,
  });
}

/// On-device face verification using Google ML Kit face detection.
///
/// How it works:
///   1. Run face detection on the captured selfie.
///   2. Download the user's profile photo and run face detection on it.
///   3. Extract normalised facial landmark vectors from both faces.
///   4. Compute cosine similarity between the two vectors.
///   5. Return verified = true if similarity ≥ [_kThreshold].
///
/// Limitations: geometric landmark comparison gives a good signal for
/// obvious mismatches (different people, no face) but cannot match the
/// accuracy of deep neural-network face embeddings.  For the HRMS
/// employee-check-in use case this is an appropriate trade-off.
class FaceVerificationService {
  // Singleton detector — reused across calls to avoid repeated init cost.
  static FaceDetector? _detector;

  static FaceDetector _getDetector() {
    return _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: false,
        enableClassification: false,
        enableTracking: false,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  // ──────────────────────────── helpers ────────────────────────────────────

  /// Build a normalised landmark vector from the face bounding-box centre.
  /// Each landmark is normalised by half the bounding-box diagonal so the
  /// vector is scale- and position-invariant.
  static List<double> _landmarkVector(Face face) {
    final cx = face.boundingBox.left + face.boundingBox.width / 2.0;
    final cy = face.boundingBox.top + face.boundingBox.height / 2.0;
    final scale =
        max(face.boundingBox.width, face.boundingBox.height) / 2.0;

    const types = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
    ];

    final v = <double>[];
    for (final type in types) {
      final lm = face.landmarks[type];
      v.add(lm != null ? (lm.position.x - cx) / scale : 0.0);
      v.add(lm != null ? (lm.position.y - cy) / scale : 0.0);
    }
    return v;
  }

  static double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Return whichever detected face has the largest bounding-box area.
  static Face _largestFace(List<Face> faces) => faces.reduce(
        (a, b) =>
            (a.boundingBox.width * a.boundingBox.height) >=
                    (b.boundingBox.width * b.boundingBox.height)
                ? a
                : b,
      );

  // ──────────────────────────── public API ─────────────────────────────────

  /// Compare the face in [selfieFile] against the face in [profilePhotoUrl].
  ///
  /// Returns a [FaceVerificationResult] — the caller should check
  /// [verified] and use [reason] to show the right error message.
  static Future<FaceVerificationResult> verify({
    required File selfieFile,
    required String profilePhotoUrl,
  }) async {
    final detector = _getDetector();
    File? tempProfile;

    try {
      // ── 1. Detect face in selfie ──────────────────────────────────────────
      final selfieFaces =
          await detector.processImage(InputImage.fromFile(selfieFile));

      if (selfieFaces.isEmpty) {
        return const FaceVerificationResult(
          verified: false,
          similarityScore: 0,
          reason: 'no_face_in_selfie',
        );
      }

      // ── 2. Download profile photo → temp file ─────────────────────────────
      try {
        final response = await http
            .get(Uri.parse(profilePhotoUrl))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final dir = await getTemporaryDirectory();
        tempProfile = File('${dir.path}/profile_verify_temp.jpg');
        await tempProfile.writeAsBytes(response.bodyBytes);
      } catch (e) {
        print('Face verify: profile download failed — $e');
        return const FaceVerificationResult(
          verified: false,
          similarityScore: 0,
          reason: 'profile_download_failed',
        );
      }

      // ── 3. Detect face in profile photo ───────────────────────────────────
      final profileFaces =
          await detector.processImage(InputImage.fromFile(tempProfile));

      if (profileFaces.isEmpty) {
        return const FaceVerificationResult(
          verified: false,
          similarityScore: 0,
          reason: 'no_face_in_profile',
        );
      }

      // ── 4. Compare normalised landmark geometry ───────────────────────────
      final selfieVec = _landmarkVector(_largestFace(selfieFaces));
      final profileVec = _landmarkVector(_largestFace(profileFaces));
      final similarity = _cosineSimilarity(selfieVec, profileVec);
      final score = (similarity * 100).clamp(0, 100).round();
      final verified = score >= _kThreshold;

      print(
        'Face verify: score=$score% threshold=$_kThreshold verified=$verified',
      );

      return FaceVerificationResult(
        verified: verified,
        similarityScore: score,
        reason: verified ? 'match' : 'mismatch',
      );
    } finally {
      try {
        await tempProfile?.delete();
      } catch (_) {}
    }
  }

  /// Release native detector resources.
  /// Call this when the screen that owns verification is disposed.
  static void close() {
    _detector?.close();
    _detector = null;
  }
}
