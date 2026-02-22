import 'dart:async';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'token_storage_service.dart';

/// Handles authenticated media download, caching, gallery saving, and opening.
class ChatMediaService {
  static final ChatMediaService _instance = ChatMediaService._internal();
  late Directory _cacheDir;
  final Map<String, double> _downloadProgress = {};
  final _storage = TokenStorageService();

  factory ChatMediaService() => _instance;
  ChatMediaService._internal();

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _cacheDir = await getApplicationCacheDirectory();
  }

  // ── Auth header ───────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    // Always fetch fresh token from SharedPreferences before each request
    final token = await _storage.getToken();
    print("TOKEN => $token");
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  /// Authenticated GET request using the stored Bearer token.
  /// Automatically attaches the latest token from SharedPreferences.
  /// If the server returns 401 (token expired), call [_storage.updateToken]
  /// with the refreshed token and retry.
  ///
  /// Example:
  ///   final response = await authenticatedGet('https://example.com/api/file');
  ///   if (response.statusCode == 401) {
  ///     await _storage.updateToken(newToken); // store refreshed token
  ///     final retry = await authenticatedGet('https://example.com/api/file');
  ///   }
  Future<http.Response> authenticatedGet(String fileUrl) async {
    final token = await _storage.getToken();
    final response = await http
        .get(Uri.parse(fileUrl), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 120));
    return response;
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses scoped storage
      final photos = await Permission.photos.request();
      if (photos.isGranted) return true;
      // Fallback for Android < 13
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  File _getCacheFile(String url, String mediaType) {
    final uri = Uri.parse(url);
    final rawName = uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => 'media_${DateTime.now().millisecondsSinceEpoch}',
    );
    final typeDir = Directory('${_cacheDir.path}/$mediaType');
    if (!typeDir.existsSync()) typeDir.createSync(recursive: true);
    return File('${typeDir.path}/$rawName');
  }

  bool isCached(String url, String mediaType) =>
      _getCacheFile(url, mediaType).existsSync();

  String? getCachedPath(String url, String mediaType) {
    final file = _getCacheFile(url, mediaType);
    return file.existsSync() ? file.path : null;
  }

  // ── URL Validation ───────────────────────────────────────────────────────

  /// Validate that the URL is a proper HTTP(S) URL
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  /// Check if URL is a public CDN URL (no auth needed)
  bool _isCdnUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('cloudinary.com') ||
        lower.contains('res.cloudinary.com') ||
        lower.contains('.cloudinary.') ||
        lower.contains('cdn.') ||
        lower.contains('assets.') ||
        lower.contains('imgur.com') ||
        lower.contains('googleapis.com/') ||
        lower.contains('firebasestorage.googleapis.com');
  }

  bool _requiresAuth(String url) {
    final lower = url.toLowerCase();

    // Cloudinary or CDN → NO AUTH
    if (lower.contains('cloudinary.com') ||
        lower.contains('res.cloudinary.com')) {
      return false;
    }

    // Backend URLs → AUTH
    if (lower.contains('hrms-backend') ||
        lower.contains('onrender.com') ||
        lower.contains('localhost') ||
        lower.contains('/api/')) {
      return true;
    }

    return false;
  }

  // ── Download ──────────────────────────────────────────────────────────────

  /// Downloads [url] with optional JWT auth to the local cache.
  /// For images & videos, also saves to device gallery.
  Future<String> downloadMedia(
    String url,
    String mediaType, {
    void Function(double progress)? onProgress,
  }) async {
    if (!_isValidUrl(url)) {
      print('❌ Invalid media URL: "$url"');
      throw Exception('Invalid media URL');
    }

    final file = _getCacheFile(url, mediaType);

    if (file.existsSync()) {
      print('📦 Already cached: ${file.path}');
      return file.path;
    }

    try {
      print('⬇️ Downloading: $url');
      print('   Media Type: $mediaType');

      final isCdn = _isCdnUrl(url);
      final needsAuth = _requiresAuth(url); // ✅ FIXED

      print('   CDN URL: $isCdn | Needs Auth: $needsAuth');

      http.StreamedResponse response;

      /// ── FIRST ATTEMPT ──
      response = await _sendDownloadRequest(url, withAuth: needsAuth);

      print('   📊 Response Code: ${response.statusCode}');

      /// ── RETRY RULES ──

      /// Case 1 → Sent auth but failed
      if (response.statusCode == 401 && needsAuth) {
        print('   🔄 401 with auth → retry WITHOUT auth');
        await response.stream.drain();

        response = await _sendDownloadRequest(url, withAuth: false);

        print('   📊 Retry Response Code: ${response.statusCode}');
      }

      /// Case 2 → Sent without auth but failed
      if (response.statusCode == 401 && !needsAuth) {
        print('   🔄 401 without auth → retry WITH auth');
        await response.stream.drain();

        response = await _sendDownloadRequest(url, withAuth: true);

        print('   📊 Retry Response Code: ${response.statusCode}');
      }

      /// ── FINAL STATUS ──
      if (response.statusCode != 200) {
        final statusMsg = switch (response.statusCode) {
          401 => 'Unauthorized – please log in again',
          403 => 'Access denied',
          404 => 'File not found',
          >= 500 => 'Server error (${response.statusCode})',
          _ => 'Download failed (${response.statusCode})',
        };

        print('   ❌ $statusMsg');
        await response.stream.drain();
        throw Exception(statusMsg);
      }

      print('   ✅ Download successful');

      /// ── SAVE FILE ──
      final contentLength = response.contentLength ?? 0;
      var downloaded = 0;
      final chunks = <List<int>>[];
      final completer = Completer<void>();

      response.stream.listen(
        (chunk) {
          chunks.add(chunk);
          downloaded += chunk.length;

          if (contentLength > 0) {
            onProgress?.call(downloaded / contentLength);
          }
        },
        onDone: completer.complete,
        onError: completer.completeError,
        cancelOnError: true,
      );

      await completer.future;

      final bytes = chunks.expand((c) => c).toList();

      if (bytes.isEmpty) {
        throw Exception('Downloaded file empty');
      }

      await file.writeAsBytes(bytes);

      print('   💾 Cached: ${file.path}');
      print('   📏 Size: ${formatFileSize(bytes.length)}');

      /// Save gallery if needed
      if (mediaType == 'images' || mediaType == 'videos') {
        await _saveToGallery(file, mediaType);
      }

      return file.path;
    } catch (e) {
      print('   ❌ Download error: $e');

      if (file.existsSync()) {
        file.deleteSync();
      }

      rethrow;
    }
  }

  /// Internal: fire a single GET request and return the streamed response.
  Future<http.StreamedResponse> _sendDownloadRequest(
    String url, {
    required bool withAuth,
  }) async {
    print("🌍 Request URL => $url");

    final headers = <String, String>{};

    if (withAuth) {
      final authHeaders = await _authHeaders();
      headers.addAll(authHeaders);
      print('   🔐 Auth header attached');
    } else {
      print('   🌐 No auth (public URL)');
    }

    final client = http.Client();

    final request = http.Request('GET', Uri.parse(url))
      ..headers.addAll(headers)
      ..followRedirects = true
      ..maxRedirects = 5;

    return await client.send(request).timeout(const Duration(seconds: 120));
  }

  // ── Gallery save ──────────────────────────────────────────────────────────

  Future<void> _saveToGallery(File file, String mediaType) async {
    try {
      print('   🖼️ Saving to gallery...');

      final hasAccess = await Gal.hasAccess(toAlbum: false);
      print('   📋 Has gallery access: $hasAccess');

      if (!hasAccess) {
        print('   🔐 Requesting gallery access...');
        await Gal.requestAccess(toAlbum: false);
      }

      if (mediaType == 'images') {
        print('   📷 Saving image to gallery...');
        await Gal.putImage(file.path, album: 'HRMS');
        print('   ✅ Image saved to gallery');
      } else if (mediaType == 'videos') {
        print('   🎬 Saving video to gallery...');
        await Gal.putVideo(file.path, album: 'HRMS');
        print('   ✅ Video saved to gallery');
      }
    } catch (e) {
      // Non-fatal: we still have the cached copy
      print('   ⚠️ Gallery save skipped: $e');
    }
  }

  // ── Open ──────────────────────────────────────────────────────────────────

  Future<void> openFile(String filePath) async {
    print('📂 Opening file: $filePath');
    final file = File(filePath);

    if (!file.existsSync()) {
      print('   ❌ File not found: $filePath');
      throw Exception('File not found: $filePath');
    }

    print('   ✅ File exists');
    print('   📏 File size: ${formatFileSize(file.lengthSync())}');

    final fileName = file.path.split('/').last;
    final mimeType = getMimeType(fileName);
    final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
    print('   📋 File name: $fileName');
    print('   🏷️ MIME type: $mimeType');

    try {
      print('   🚀 Launching app to open file...');
      final result = await OpenFile.open(filePath, type: mimeType);
      print('   📊 Result type: ${result.type}');
      print('   📝 Result message: ${result.message}');

      if (result.type.index != 0) {
        // Type 0 = success, anything else = error
        final errorMsg = result.message.isNotEmpty
            ? result.message
            : 'No app found to open $ext files';
        print('   ❌ Failed to open: $errorMsg');
        throw Exception(errorMsg);
      }

      print('   ✅ File opened successfully');
    } catch (e) {
      print('   ❌ Open error: $e');
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double? getProgress(String url) => _downloadProgress[url];

  String getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.lastWhere(
        (s) => s.isNotEmpty,
        orElse: () => 'file',
      );
    } catch (_) {
      return 'file';
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String getMimeType(String fileName) {
    if (fileName.isEmpty) return 'application/octet-stream';

    // Extract extension (handle URLs with query params)
    final parts = fileName.split('?').first; // Remove query params
    final ext = parts.contains('.') ? parts.split('.').last.toLowerCase() : '';

    print('   🔍 File extension detected: .$ext');

    const mimes = {
      // Images
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'ico': 'image/x-icon',
      // Documents
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'rtf': 'application/rtf',
      'odt': 'application/vnd.oasis.opendocument.text',
      'ods': 'application/vnd.oasis.opendocument.spreadsheet',
      'odp': 'application/vnd.oasis.opendocument.presentation',
      'csv': 'text/csv',
      // Video
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'mkv': 'video/x-matroska',
      'flv': 'video/x-flv',
      'wmv': 'video/x-ms-wmv',
      '3gp': 'video/3gpp',
      'webm': 'video/webm',
      // Audio
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'aac': 'audio/aac',
      'm4a': 'audio/mp4',
      'ogg': 'audio/ogg',
      'flac': 'audio/flac',
      'wma': 'audio/x-ms-wma',
      // Archive
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',
    };

    final mimeType = mimes[ext] ?? 'application/octet-stream';
    return mimeType;
  }

  Future<void> clearCache() async {
    if (_cacheDir.existsSync()) {
      try {
        _cacheDir.deleteSync(recursive: true);
      } catch (e) {
        print('⚠️ Cache clear error: $e');
      }
    }
  }

  /// Get total cache size
  Future<int> getCacheSize() async {
    if (!_cacheDir.existsSync()) return 0;
    int size = 0;
    for (final file in _cacheDir.listSync(recursive: true)) {
      if (file is File) size += file.lengthSync();
    }
    return size;
  }
}
