# Chat Media Handling System

## Overview

The Chat Media Handling System allows users to seamlessly download, cache, and open media files (images, videos, documents) received in chat messages. The system provides a smooth user experience with progress indicators, error handling, and offline access to cached files.

## Features

### 1. **Automatic Media Detection**
- Detects media type from file extension
- Supports: Images (JPG, PNG, GIF), Videos (MP4, MOV, AVI), Documents (PDF, DOC, DOCX, XLS, etc.)

### 2. **Smart Caching System**
- Organizes media by type in cache directory
- Checks for cached files before downloading
- Displays cached indicator (✓) for previously downloaded media
- Automatic cache organization by content type

### 3. **Download Management**
```
States:
┌─────────────┐
│ Not Cached  │ ──(tap)──> ┌──────────────┐
│ "Download"  │            │   Downloading│ ──(complete)──> ┌─────┐
└─────────────┘            │ Progress: %  │                 │Open │
                           └──────────────┘                 └─────┘
```

Features:
- Streaming download with real-time progress
- Download progress percentage display
- Automatic retry on failure
- Download indicator badges on uncached media

### 4. **File Opening**
- Opens files with device default applications
- Supports all major file types
- Graceful error handling for missing viewers

### 5. **Storage Permissions**
- Automatic permission requests for Android 12+
- Scoped storage compatibility
- Fallback to app cache if external storage unavailable

## Implementation Details

### ChatMediaService

**Location:** `lib/services/chat_media_service.dart`

**Key Methods:**

```dart
// Download media with progress callback
Future<String> downloadMedia(
  String url,
  String mediaType, {
  void Function(double)? onProgress,
})

// Open file with device default app
Future<void> openFile(String filePath)

// Check if file is cached
bool isCached(String url, String mediaType)

// Request storage permissions  
Future<bool> requestStoragePermission()

// Get human-readable file size
static String formatFileSize(int bytes)
```

### Media Bubble Widgets

#### _ImageBubble
- Shows thumbnail preview
- Download overlay when not cached
- Progress indicator during download
- Tap to download & open
- Error state with retry

#### _DocumentBubble
- File icon with name/mime type
- Download badge on uncached files
- Progress percentage during download
- Checkmark when cached
- Failure status with retry option

#### _VideoBubble
- Play icon indicator
- Download badge for uncached videos
- Progress percentage download display
- Cached status indicator
- Optimized for mobile video players

## User Flow

### Receiving Media

1. Message arrives with media attachment
2. Media bubble displays with cached status
3. If not cached:
   - Shows "Tap to download" indicator
   - Download icon badge appears
4. If cached:
   - Shows green checkmark (✓)
   - Ready to open immediately

### Opening Media

```
User taps media bubble
    ↓
Check if cached
    ├─ YES ──> Open file directly
    └─ NO  ──> Show download progress
               ↓
           Download from URL
               ↓
           Save to cache
               ↓
           Open with default app
```

### Error Handling

```
Download fails
    ↓
Show error message (red snackbar)
    ↓
Update UI to show retry option
    ↓
User can tap again to retry
```

## Cache Organization

```
App Cache Directory
├── /images
│   ├── image_1.jpg
│   ├── image_2.png
│   └── ...
├── /videos
│   ├── video_1.mp4
│   ├── video_2.mov
│   └── ...
└── /documents
    ├── document_1.pdf
    ├── document_2.docx
    └── ...
```

## Supported File Types

### Images
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)

### Videos
- MP4 (.mp4)
- MOV (.mov)
- AVI (.avi)

### Documents
- PDF (.pdf)
- Word (.doc, .docx)
- Excel (.xls, .xlsx)
- PowerPoint (.ppt, .pptx)
- Text (.txt)
- ZIP (.zip)

## Dependencies

```yaml
path_provider: ^2.1.1        # Access app cache/external storage
open_file: ^3.1.0            # Open files with default apps
permission_handler: ^11.0.0  # Request storage permissions (already included)
http: ^1.2.0                 # Download files (already included)
```

## Configuration

### Android Permissions

Required in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS Permissions

Required in `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Access photos to save downloaded media</string>
<key>NSDocumentsFolderAccessDescription</key>
<string>Access documents to save and open files</string>
```

## Usage Example

### Initialization (in main.dart or app init)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChatMediaService().init();
  runApp(const MyApp());
}
```

### In Chat Screen

```dart
// Media bubbles are already integrated
// Just ensure ChatMediaService is imported

import '../services/chat_media_service.dart';

// Bubbles handle download/open automatically
_ImageBubble(url: attachment.url)
_DocumentBubble(attachment: attachment, isMine: isMine)
_VideoBubble(url: attachment.url, isMine: isMine)
```

## UI States

### Image States
```
┌──────────────────────────────────────┐
│  Initial/Cached                      │
│  ┌──────────────────────────────────┐│
│  │ [Thumbnail Image]                ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Downloading                         │
│  ┌──────────────────────────────────┐│
│  │ [Thumbnail + Dark Overlay]       ││
│  │   📥 Progress: 45%               ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Not Cached                          │
│  ┌──────────────────────────────────┐│
│  │ [Thumbnail + Dark Overlay]       ││
│  │   ☁️ Tap to download             ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

### Document States
```
┌──────────────────────────────┐
│ 📄 document.pdf              │
│ application/pdf              │
│                 ↙ Download   │
└──────────────────────────────┘

┌──────────────────────────────┐
│ ⟳ document.pdf               │
│ application/pdf              │
│ 72%                         │
└──────────────────────────────┘

┌──────────────────────────────┐
│ 📄 document.pdf              │
│ application/pdf              │
│                      ✓ Cached│
└──────────────────────────────┘
```

## Performance Considerations

1. **Streaming Downloads**: Media streams directly to disk, not loaded into memory
2. **Progress Callback**: Updates UI at ~100ms intervals to avoid excessive rebuilds
3. **Caching**: Prevents re-downloading same media
4. **Async Operations**: All downloads/opens run on background threads
5. **Error Isolation**: Failed downloads don't crash the chat

## Troubleshooting

### "No app found to open this file type"
- User device doesn't have viewer for this file type
- Solution: Download and install appropriate app

### "Permission denied to open file"
- Storage permissions not granted
- Solution: Request permissions in app settings

### "Failed to download"
- Network connection issue
- URL moved/deleted
- Server error
- Solution: Check connection and retry

### Cache not clearing
- Use `ChatMediaService().clearCache()` to manually clear
- Cache persists between app sessions for offline access

## Future Enhancements

- [ ] Download retry with exponential backoff
- [ ] Pause/resume downloads
- [ ] Media preview gallery
- [ ] Automatic cache size limit management
- [ ] Download history/management UI
- [ ] Video thumbnail generation
- [ ] Document preview before opening
- [ ] Drag-to-share downloaded files
