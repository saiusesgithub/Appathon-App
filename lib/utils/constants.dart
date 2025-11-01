// This file stores all constant values used in file transfer
// Having them in one place makes it easy to change settings

class FileTransferConstants {
  // Maximum file size allowed: 5 MB (5 * 1024 * 1024 bytes)
  static const int maxFileSize = 5 * 1024 * 1024;
  
  // Size of each chunk when splitting file: 32 KB
  // Smaller chunks = more reliable but slower
  // Larger chunks = faster but may overwhelm Bluetooth
  static const int chunkSize = 32 * 1024;
  
  // Delay between sending chunks (in milliseconds)
  // This prevents overwhelming the Bluetooth buffer
  static const int chunkDelayMs = 50;
  
  // How long to wait before timing out (5 minutes)
  static const Duration transferTimeout = Duration(minutes: 5);
  
  // Message delimiter - separates message type from data
  // Example: "FILE_META|||{json data here}"
  static const String messageDelimiter = '|||';
  
  // Message types - these are like "commands" in our protocol
  static const String msgTypeFileRequest = 'FILE_REQUEST';   // "I want to send a file"
  static const String msgTypeFileAccept = 'FILE_ACCEPT';     // "OK, send it"
  static const String msgTypeFileReject = 'FILE_REJECT';     // "No thanks"
  static const String msgTypeFileMetadata = 'FILE_META';     // File information
  static const String msgTypeFileChunk = 'FILE_CHUNK';       // Piece of file data
  static const String msgTypeFileComplete = 'FILE_COMPLETE'; // "Transfer done"
  static const String msgTypeFileCancelled = 'FILE_CANCEL';  // "I'm cancelling"
  static const String msgTypeTextMessage = 'TEXT_MSG';       // Regular chat message
}
