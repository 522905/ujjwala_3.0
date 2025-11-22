# TUS to Multipart Upload Migration Guide

## Problem

The `tus_client` package version `^0.1.6` doesn't exist on pub.dev, causing dependency resolution failures.

## Solution

Replaced TUS client with **Dio-based multipart upload** - a more standard and widely compatible approach.

## What Changed

### 1. Dependencies (pubspec.yaml)

**Removed:**
```yaml
tus_client: ^0.1.6
```

**Added:**
```yaml
http_parser: ^4.0.2
```

### 2. Upload Service (lib/data/services/tus_upload_service.dart)

The service name remains the same (`TusUploadService`) but now uses Dio for multipart uploads instead of the TUS protocol.

**Key changes:**
- Uses `Dio` with `MultipartFile` for uploads
- Standard HTTP multipart/form-data instead of TUS PATCH protocol
- Same public API (no changes to calling code)
- Maintains retry logic and progress tracking

## API Compatibility

**Good news:** The public API remains unchanged! All existing calls to `TusUploadService` will work without modification.

```dart
// This code still works exactly the same
final uploadService = TusUploadService();
final url = await uploadService.uploadWithRetry(
  file: myFile,
  filename: 'document.pdf',
  onProgress: (progress) {
    print('Upload progress: ${progress * 100}%');
  },
);
```

## Backend Configuration Required

Your backend needs to accept standard multipart uploads instead of TUS protocol.

### Expected Endpoint

**URL:** `POST {ApiConfig.tusUploadUrl}/upload`

**Content-Type:** `multipart/form-data`

**Form fields:**
- `file`: Binary file data
- `filename`: Original filename
- `filetype`: MIME type (e.g., 'image/jpeg', 'application/pdf')

**Response format:**
```json
{
  "url": "https://your-cdn.com/files/abc123.pdf",
  // OR
  "file_url": "https://your-cdn.com/files/abc123.pdf",
  // OR
  "path": "/files/abc123.pdf"
}
```

The service will automatically detect which field contains the file URL.

### Example Backend Implementations

#### Node.js + Express + Multer

```javascript
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });

app.post('/upload', upload.single('file'), (req, res) => {
  const fileUrl = `${process.env.CDN_URL}/${req.file.filename}`;
  res.json({ url: fileUrl });
});
```

#### Python + Flask

```python
@app.route('/upload', methods=['POST'])
def upload_file():
    file = request.files['file']
    filename = request.form['filename']

    # Save file
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(file_path)

    # Return URL
    file_url = f"{CDN_URL}/{filename}"
    return jsonify({'url': file_url})
```

#### PHP

```php
if ($_FILES['file']) {
    $filename = $_POST['filename'];
    $target = "uploads/" . $filename;

    if (move_uploaded_file($_FILES['file']['tmp_name'], $target)) {
        $url = CDN_URL . "/" . $filename;
        echo json_encode(['url' => $url]);
    }
}
```

## Configuration

Update your backend URL in `lib/core/config/api_config.dart`:

```dart
// Development
static const String devApiBaseUrl = 'http://localhost:8000';
static const String devTusUploadUrl = 'http://localhost:8000'; // Changed

// Staging
static const String stagingApiBaseUrl = 'https://staging.api.arungas.com';
static const String stagingTusUploadUrl = 'https://staging.api.arungas.com'; // Changed

// Production
static const String productionApiBaseUrl = 'https://api.arungas.com';
static const String productionTusUploadUrl = 'https://api.arungas.com'; // Changed
```

The service will POST to `{tusUploadUrl}/upload`.

## Advanced Features

### Authentication

Add auth token to uploads:

```dart
final uploadService = TusUploadService();
uploadService.setAuthToken(myAuthToken);
```

### Custom Headers

```dart
uploadService.setHeaders({
  'X-Custom-Header': 'value',
});
```

### Multiple File Upload

```dart
final urls = await uploadService.uploadMultiple(
  files: [file1, file2, file3],
  filenames: ['doc1.pdf', 'doc2.jpg', 'doc3.png'],
  onProgress: (current, total, progress) {
    print('Uploading file $current of $total: ${progress * 100}%');
  },
);
```

## Migration from TUS Protocol (If Needed)

If you absolutely need TUS protocol support:

### Option 1: Manual TUS Implementation

Implement TUS PATCH protocol using Dio interceptors:

```dart
class TusInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.contains('/files/')) {
      options.method = 'PATCH';
      options.headers['Upload-Offset'] = '0';
      options.headers['Content-Type'] = 'application/offset+octet-stream';
      options.headers['Tus-Resumable'] = '1.0.0';
    }
    handler.next(options);
  }
}
```

### Option 2: Alternative Packages

Search for TUS packages on pub.dev:
- `tusker_client` (if available)
- `tus_client_dart` (if available)
- Or implement your own using Dio

### Option 3: Backend Change

Configure your backend to accept standard multipart uploads (recommended).

## Testing

After migration, test these scenarios:

### 1. Single File Upload
```dart
final file = File('path/to/document.pdf');
final url = await uploadService.uploadFile(
  file: file,
  filename: 'test.pdf',
);
print('Uploaded to: $url');
```

### 2. Upload with Retry
```dart
final url = await uploadService.uploadWithRetry(
  file: file,
  filename: 'test.pdf',
  maxRetries: 3,
);
```

### 3. Progress Tracking
```dart
await uploadService.uploadFile(
  file: file,
  filename: 'test.pdf',
  onProgress: (progress) {
    setState(() {
      uploadProgress = progress;
    });
  },
);
```

### 4. Error Handling
```dart
try {
  final url = await uploadService.uploadFile(
    file: file,
    filename: 'test.pdf',
  );
} catch (e) {
  print('Upload failed: $e');
}
```

## Benefits of Multipart Upload

1. **Wider Compatibility**: Works with any standard HTTP server
2. **Simpler Implementation**: No complex TUS protocol
3. **Fewer Dependencies**: One less package to maintain
4. **Better Control**: Direct access to Dio features
5. **Easier Debugging**: Standard HTTP requests

## Limitations vs TUS

1. **No Resume on Network Failure**: TUS allows resuming from exact byte offset
2. **Full Re-upload on Failure**: Retry sends entire file again
3. **No Chunked Upload**: Sends complete file in one request

For most use cases (files under 10MB), these limitations are acceptable given the retry logic.

## Rollback

If you need to rollback:

1. Find a working TUS client package
2. Add to pubspec.yaml
3. Revert `tus_upload_service.dart` from git:
   ```bash
   git checkout ec2051f -- lib/data/services/tus_upload_service.dart
   ```

## Support

For issues or questions:
- Check backend upload endpoint is working
- Verify response format matches expected structure
- Test with Postman/curl to isolate issues
- Check ApiConfig.tusUploadUrl configuration

## Summary

✅ **No code changes needed** in your UI or business logic
✅ **Same API interface** maintained
✅ **Simpler, more standard** approach
✅ **Better compatibility** with most backends
⚠️ **Backend must accept** multipart/form-data
⚠️ **No true resumable** uploads (but has retry)
