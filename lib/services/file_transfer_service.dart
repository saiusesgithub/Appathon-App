import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../models/file_transfer_item.dart';
import '../utils/constants.dart';
import '../utils/file_utils.dart';

// This is the main service that handles all file transfer operations
// Think of it as the "manager" for sending and receiving files

class FileTransferService {
  // Storage for active transfers (files currently being sent/received)
  // Key = transfer ID, Value = FileTransferItem
  final Map<String, FileTransferItem> _activeTransfers = {};
  
  // Storage for completed transfers (history)
  final List<FileTransferItem> _completedTransfers = [];
  
  // Temporary storage for file chunks being received
  // Key = transfer ID, Value = List of byte chunks
  final Map<String, List<Uint8List>> _receivedChunks = {};
  
  // Metadata for files being received (name, size, total chunks, etc.)
  final Map<String, Map<String, dynamic>> _receivingFileMetadata = {};
  
  // ==========================================================================
  // CALLBACKS - These notify the UI when something happens
  // ==========================================================================
  
  // Called when a new file request arrives (someone wants to send us a file)
  Function(String fileId, String fileName, int fileSize)? onFileRequestReceived;
  
  // Called when transfer progress updates (e.g., 25% -> 26%)
  Function(String fileId, double progress)? onTransferProgress;
  
  // Called when a file is successfully received
  Function(FileTransferItem completedFile)? onFileReceived;
  
  // Called when transfer fails
  Function(String fileId, String error)? onTransferError;
  
  // Called when transfer is cancelled
  Function(String fileId)? onTransferCancelled;
  
  // ==========================================================================
  // GETTERS - Access to transfer lists
  // ==========================================================================
  
  // Get list of all active transfers
  List<FileTransferItem> get activeTransfers => _activeTransfers.values.toList();
  
  // Get list of completed transfers
  List<FileTransferItem> get completedTransfers => _completedTransfers;
  
  // Get a specific transfer by ID
  FileTransferItem? getTransfer(String id) => _activeTransfers[id];
  
  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================
  
  FileTransferService() {
    print('📁 FileTransferService initialized');
  }
  
  // ==========================================================================
  // HELPER METHOD - Build protocol messages
  // ==========================================================================
  
  // Creates a message in our protocol format: "MESSAGE_TYPE|||data"
  // Example: "FILE_META|||{fileName: "photo.jpg", fileSize: 1024}"
  String _buildMessage(String messageType, Map<String, dynamic> data) {
    final jsonData = jsonEncode(data);
    return '$messageType${FileTransferConstants.messageDelimiter}$jsonData';
  }
  
  // Parse an incoming message into type and data
  // Example: "FILE_META|||{...}" -> type: "FILE_META", data: {...}
  Map<String, dynamic>? _parseMessage(String message) {
    try {
      final parts = message.split(FileTransferConstants.messageDelimiter);
      if (parts.length != 2) return null;
      
      return {
        'type': parts[0],
        'data': jsonDecode(parts[1]),
      };
    } catch (e) {
      print('❌ Error parsing message: $e');
      return null;
    }
  }
  
  // ==========================================================================
  // SENDING FILES - Methods for sending files to another device
  // ==========================================================================
  
  // Main method to send a file
  // Parameters:
  //   - file: The file to send
  //   - sendFunction: A function that actually sends data via Bluetooth
  //                   (we pass this in because different pages use different BT services)
  Future<bool> sendFile(
    File file,
    Future<bool> Function(String) sendFunction,
  ) async {
    try {
      print('📤 Starting to send file: ${path.basename(file.path)}');
      
      // Step 1: Get file information
      final fileName = path.basename(file.path);
      final fileSize = await file.length();
      
      // Step 2: Validate file size
      if (!FileUtils.isFileSizeValid(fileSize)) {
        final error = 'File too large. Maximum size is ${FileUtils.formatFileSize(FileTransferConstants.maxFileSize)}';
        print('❌ $error');
        onTransferError?.call('', error);
        return false;
      }
      
      // Step 3: Generate unique ID for this transfer
      final transferId = FileUtils.generateTransferId();
      
      // Step 4: Read the entire file into memory (safe because we limit to 5MB)
      final fileBytes = await file.readAsBytes();
      
      // Step 5: Calculate how many chunks we'll need
      final totalChunks = (fileBytes.length / FileTransferConstants.chunkSize).ceil();
      
      print('📊 File info: $fileName, ${FileUtils.formatFileSize(fileSize)}, $totalChunks chunks');
      
      // Step 6: Create a transfer item to track progress
      final transferItem = FileTransferItem(
        id: transferId,
        fileName: fileName,
        fileSize: fileSize,
        filePath: file.path,
        status: TransferStatus.transferring,
        progress: 0.0,
        timestamp: DateTime.now(),
        isSending: true,
      );
      
      // Add to active transfers
      _activeTransfers[transferId] = transferItem;
      
      // Step 7: Send file metadata first (tells receiver what to expect)
      final metadataMessage = _buildMessage(
        FileTransferConstants.msgTypeFileMetadata,
        {
          'transferId': transferId,
          'fileName': fileName,
          'fileSize': fileSize,
          'totalChunks': totalChunks,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      final metaSent = await sendFunction(metadataMessage);
      if (!metaSent) {
        print('❌ Failed to send metadata');
        _updateTransferStatus(transferId, TransferStatus.failed);
        return false;
      }
      
      print('✅ Metadata sent');
      
      // Step 8: Send file in chunks
      for (int i = 0; i < fileBytes.length; i += FileTransferConstants.chunkSize) {
        // Calculate end position for this chunk
        final end = (i + FileTransferConstants.chunkSize < fileBytes.length)
            ? i + FileTransferConstants.chunkSize
            : fileBytes.length;
        
        // Extract this chunk of bytes
        final chunk = fileBytes.sublist(i, end);
        
        // Encode chunk to Base64 (converts binary to text so we can send via Bluetooth)
        final encodedChunk = base64Encode(chunk);
        
        // Calculate chunk number (0-indexed)
        final chunkNumber = i ~/ FileTransferConstants.chunkSize;
        
        // Create chunk message
        final chunkMessage = _buildMessage(
          FileTransferConstants.msgTypeFileChunk,
          {
            'transferId': transferId,
            'chunkNumber': chunkNumber,
            'totalChunks': totalChunks,
            'data': encodedChunk,
          },
        );
        
        // Send this chunk
        final chunkSent = await sendFunction(chunkMessage);
        if (!chunkSent) {
          print('❌ Failed to send chunk $chunkNumber');
          _updateTransferStatus(transferId, TransferStatus.failed);
          return false;
        }
        
        // Update progress
        final progress = (chunkNumber + 1) / totalChunks;
        _updateTransferProgress(transferId, progress);
        
        // Small delay to prevent overwhelming Bluetooth buffer
        await Future.delayed(Duration(milliseconds: FileTransferConstants.chunkDelayMs));
        
        print('📦 Sent chunk ${chunkNumber + 1}/$totalChunks (${(progress * 100).toInt()}%)');
      }
      
      // Step 9: Send completion message
      final completeMessage = _buildMessage(
        FileTransferConstants.msgTypeFileComplete,
        {
          'transferId': transferId,
          'fileName': fileName,
        },
      );
      
      await sendFunction(completeMessage);
      
      // Step 10: Mark as completed
      _updateTransferStatus(transferId, TransferStatus.completed);
      _moveToCompleted(transferId);
      
      print('✅ File sent successfully!');
      return true;
      
    } catch (e) {
      print('❌ Error sending file: $e');
      onTransferError?.call('', e.toString());
      return false;
    }
  }
  
  // ==========================================================================
  // HELPER METHODS - Update transfer state
  // ==========================================================================
  
  // Update the status of a transfer (e.g., from transferring to completed)
  void _updateTransferStatus(String transferId, TransferStatus status) {
    final transfer = _activeTransfers[transferId];
    if (transfer != null) {
      _activeTransfers[transferId] = transfer.copyWith(status: status);
    }
  }
  
  // Update the progress of a transfer
  void _updateTransferProgress(String transferId, double progress) {
    final transfer = _activeTransfers[transferId];
    if (transfer != null) {
      _activeTransfers[transferId] = transfer.copyWith(progress: progress);
      onTransferProgress?.call(transferId, progress);
    }
  }
  
  // Move a transfer from active to completed list
  void _moveToCompleted(String transferId) {
    final transfer = _activeTransfers.remove(transferId);
    if (transfer != null) {
      _completedTransfers.insert(0, transfer); // Add to start of list
    }
  }
  
  // ==========================================================================
  // RECEIVING FILES - Methods for receiving files from another device
  // ==========================================================================
  
  // Main method to handle incoming messages
  // This is called whenever a Bluetooth message arrives
  // It figures out what type of message it is and handles it accordingly
  Future<void> handleIncomingMessage(String message) async {
    try {
      // Step 1: Parse the message
      final parsed = _parseMessage(message);
      if (parsed == null) {
        // Not a file transfer message, ignore it
        return;
      }
      
      final messageType = parsed['type'] as String;
      final data = parsed['data'] as Map<String, dynamic>;
      
      print('📨 Received message type: $messageType');
      
      // Step 2: Route to appropriate handler based on message type
      switch (messageType) {
        case FileTransferConstants.msgTypeFileMetadata:
          await _handleFileMetadata(data);
          break;
        
        case FileTransferConstants.msgTypeFileChunk:
          await _handleFileChunk(data);
          break;
        
        case FileTransferConstants.msgTypeFileComplete:
          await _handleFileComplete(data);
          break;
        
        case FileTransferConstants.msgTypeFileCancelled:
          _handleFileCancelled(data);
          break;
        
        default:
          print('⚠️ Unknown message type: $messageType');
      }
      
    } catch (e) {
      print('❌ Error handling incoming message: $e');
    }
  }
  
  // Handle metadata (file information) message
  // This is the first message received when someone sends a file
  Future<void> _handleFileMetadata(Map<String, dynamic> data) async {
    try {
      final transferId = data['transferId'] as String;
      final fileName = data['fileName'] as String;
      final fileSize = data['fileSize'] as int;
      final totalChunks = data['totalChunks'] as int;
      
      print('📋 Receiving file: $fileName (${FileUtils.formatFileSize(fileSize)}, $totalChunks chunks)');
      
      // Store metadata for this transfer
      _receivingFileMetadata[transferId] = data;
      
      // Initialize chunk storage
      _receivedChunks[transferId] = [];
      
      // Create transfer item
      final transferItem = FileTransferItem(
        id: transferId,
        fileName: fileName,
        fileSize: fileSize,
        status: TransferStatus.transferring,
        progress: 0.0,
        timestamp: DateTime.now(),
        isSending: false,
      );
      
      _activeTransfers[transferId] = transferItem;
      
      // Notify UI that file transfer started
      onFileRequestReceived?.call(transferId, fileName, fileSize);
      
    } catch (e) {
      print('❌ Error handling file metadata: $e');
    }
  }
  
  // Handle a file chunk (piece of the file)
  Future<void> _handleFileChunk(Map<String, dynamic> data) async {
    try {
      final transferId = data['transferId'] as String;
      final chunkNumber = data['chunkNumber'] as int;
      final totalChunks = data['totalChunks'] as int;
      final encodedData = data['data'] as String;
      
      // Decode from Base64 back to bytes
      final chunkBytes = base64Decode(encodedData);
      
      // Store this chunk
      if (!_receivedChunks.containsKey(transferId)) {
        _receivedChunks[transferId] = [];
      }
      _receivedChunks[transferId]!.add(chunkBytes);
      
      // Update progress
      final progress = (chunkNumber + 1) / totalChunks;
      _updateTransferProgress(transferId, progress);
      
      print('📦 Received chunk ${chunkNumber + 1}/$totalChunks (${(progress * 100).toInt()}%)');
      
    } catch (e) {
      print('❌ Error handling file chunk: $e');
      onTransferError?.call(data['transferId'] as String? ?? '', e.toString());
    }
  }
  
  // Handle file complete message (all chunks received)
  Future<void> _handleFileComplete(Map<String, dynamic> data) async {
    try {
      final transferId = data['transferId'] as String;
      final fileName = data['fileName'] as String;
      
      print('✅ File transfer complete, assembling file...');
      
      // Get all chunks for this transfer
      final chunks = _receivedChunks[transferId];
      if (chunks == null || chunks.isEmpty) {
        print('❌ No chunks found for transfer $transferId');
        return;
      }
      
      // Step 1: Combine all chunks into one byte array
      final totalBytes = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final fileBytes = Uint8List(totalBytes);
      
      int offset = 0;
      for (final chunk in chunks) {
        fileBytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      
      print('📊 Assembled ${chunks.length} chunks into ${FileUtils.formatFileSize(fileBytes.length)} file');
      
      // Step 2: Save file to device
      final receiveDir = await FileUtils.getReceiveDirectory();
      final filePath = '${receiveDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      print('💾 File saved to: $filePath');
      
      // Step 3: Update transfer status
      final transfer = _activeTransfers[transferId];
      if (transfer != null) {
        final completedTransfer = transfer.copyWith(
          status: TransferStatus.completed,
          progress: 1.0,
          filePath: filePath,
        );
        
        _activeTransfers[transferId] = completedTransfer;
        _moveToCompleted(transferId);
        
        // Notify UI
        onFileReceived?.call(completedTransfer);
      }
      
      // Step 4: Clean up temporary data
      _receivedChunks.remove(transferId);
      _receivingFileMetadata.remove(transferId);
      
      print('🎉 File received successfully: $fileName');
      
    } catch (e) {
      print('❌ Error completing file transfer: $e');
      onTransferError?.call(data['transferId'] as String? ?? '', e.toString());
    }
  }
  
  // Handle file cancelled message
  void _handleFileCancelled(Map<String, dynamic> data) {
    final transferId = data['transferId'] as String;
    print('🚫 Transfer cancelled: $transferId');
    
    _updateTransferStatus(transferId, TransferStatus.cancelled);
    _moveToCompleted(transferId);
    
    // Clean up
    _receivedChunks.remove(transferId);
    _receivingFileMetadata.remove(transferId);
    
    onTransferCancelled?.call(transferId);
  }
  
  // ==========================================================================
  // PUBLIC METHODS - Cancel and cleanup
  // ==========================================================================
  
  // Cancel an active transfer
  Future<void> cancelTransfer(String transferId) async {
    print('🚫 Cancelling transfer: $transferId');
    
    _updateTransferStatus(transferId, TransferStatus.cancelled);
    _moveToCompleted(transferId);
    
    // Clean up
    _receivedChunks.remove(transferId);
    _receivingFileMetadata.remove(transferId);
  }
  
  // Clear completed transfers history
  void clearHistory() {
    _completedTransfers.clear();
    print('🗑️ Transfer history cleared');
  }
}
