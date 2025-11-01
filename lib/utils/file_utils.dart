import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// This file contains helper functions for file operations

class FileUtils {
  // Get the directory where we'll save received files
  // Returns a dedicated folder for ShadowMesh files
  static Future<Directory> getReceiveDirectory() async {
    // For Android, we get the app's document directory
    // For iOS, same - it's isolated and secure
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Create a subfolder called "ReceivedFiles"
    final shadowMeshDir = Directory('${appDocDir.path}/ReceivedFiles');
    
    // If folder doesn't exist, create it
    if (!await shadowMeshDir.exists()) {
      await shadowMeshDir.create(recursive: true);
    }
    
    return shadowMeshDir;
  }
  
  // Get an icon emoji based on file extension
  // Makes the UI more visual and user-friendly
  static String getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      // Images
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.heic':
        return '🖼️';
      
      // Videos
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
      case '.3gp':
        return '🎥';
      
      // Audio
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.m4a':
      case '.flac':
        return '🎵';
      
      // Documents
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.xls':
      case '.xlsx':
        return '📊';
      case '.ppt':
      case '.pptx':
        return '📽️';
      case '.txt':
        return '📃';
      
      // Archives
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return '📦';
      
      // APK
      case '.apk':
        return '📱';
      
      // Code files
      case '.dart':
      case '.java':
      case '.py':
      case '.js':
      case '.html':
      case '.css':
        return '💻';
      
      // Default for unknown types
      default:
        return '📎';
    }
  }
  
  // Format file size in a human-readable way
  // Examples: 1024 bytes -> "1.0 KB", 1048576 bytes -> "1.0 MB"
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  // Check if a file size is within our limit (5 MB)
  static bool isFileSizeValid(int bytes) {
    return bytes > 0 && bytes <= 5 * 1024 * 1024; // 5 MB
  }
  
  // Generate a unique ID for each transfer
  // Uses current timestamp in milliseconds as unique identifier
  static String generateTransferId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
