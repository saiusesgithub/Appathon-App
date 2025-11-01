// This file defines the data structure for a file transfer
// It holds all information about a file being sent or received

enum TransferStatus {
  pending,      // Waiting to start
  transferring, // Currently sending/receiving
  completed,    // Successfully finished
  failed,       // Something went wrong
  cancelled,    // User cancelled the transfer
}

class FileTransferItem {
  final String id;           // Unique identifier for this transfer
  final String fileName;     // Name of the file (e.g., "photo.jpg")
  final int fileSize;        // Size in bytes
  final String? filePath;    // Where the file is stored on device (null if still transferring)
  final TransferStatus status; // Current state of transfer
  final double progress;     // 0.0 to 1.0 (0% to 100%)
  final DateTime timestamp;  // When transfer started
  final bool isSending;      // true = sending, false = receiving

  // Constructor - creates a new FileTransferItem
  FileTransferItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.filePath,
    required this.status,
    this.progress = 0.0,
    required this.timestamp,
    required this.isSending,
  });

  // Helper method to format file size nicely (e.g., "2.5 MB")
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Helper method to get progress as percentage (e.g., "45%")
  String get progressPercentage {
    return '${(progress * 100).toInt()}%';
  }

  // Create a copy of this item with some fields changed
  // This is useful for updating progress without recreating the whole object
  FileTransferItem copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    String? filePath,
    TransferStatus? status,
    double? progress,
    DateTime? timestamp,
    bool? isSending,
  }) {
    return FileTransferItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      timestamp: timestamp ?? this.timestamp,
      isSending: isSending ?? this.isSending,
    );
  }
}
