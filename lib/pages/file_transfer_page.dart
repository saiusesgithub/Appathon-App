import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/file_transfer_service.dart';
import '../models/file_transfer_item.dart';
import '../utils/file_utils.dart';
import '../utils/constants.dart';

// This is the main File Transfer Page
// Users come here to send and receive files

class FileTransferPage extends StatefulWidget {
  // We need to pass in the Bluetooth send function so we can actually send data
  final Future<bool> Function(String) sendMessage;
  final bool isConnected;
  
  const FileTransferPage({
    super.key,
    required this.sendMessage,
    required this.isConnected,
  });

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  // Create instance of our file transfer service
  final FileTransferService _fileService = FileTransferService();
  
  // Track if we're currently picking a file
  bool _isPickingFile = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set up callbacks so service can notify us when things happen
    _setupCallbacks();
  }
  
  // Configure all the callback functions
  void _setupCallbacks() {
    // When file request is received
    _fileService.onFileRequestReceived = (fileId, fileName, fileSize) {
      if (!mounted) return;
      setState(() {}); // Refresh UI to show new incoming file
      print('📩 File request received: $fileName');
    };
    
    // When transfer progress updates
    _fileService.onTransferProgress = (fileId, progress) {
      if (!mounted) return;
      setState(() {}); // Refresh UI to update progress bar
    };
    
    // When file is successfully received
    _fileService.onFileReceived = (completedFile) {
      if (!mounted) return;
      setState(() {}); // Refresh UI
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ File received: ${completedFile.fileName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    };
    
    // When transfer fails
    _fileService.onTransferError = (fileId, error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Transfer failed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar at the top
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'File Transfer',
          style: TextStyle(
            color: Color(0xFF0B0B0D),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          // History button (shows completed transfers)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transfer History',
            onPressed: _showHistory,
          ),
        ],
      ),
      
      // Main content
      body: Container(
        color: const Color(0xFF0B0B0D), // Dark background like other pages
        child: Column(
          children: [
            // Connection status indicator
            _buildConnectionStatus(),
            
            // Send file section
            _buildSendFileSection(),
            
            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Divider(color: Colors.grey),
            ),
            
            // Active transfers section
            Expanded(
              child: _buildActiveTransfersList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // ==========================================================================
  // UI BUILDING METHODS
  // ==========================================================================
  
  // Shows connection status at the top
  Widget _buildConnectionStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: widget.isConnected 
          ? Colors.green.withOpacity(0.2) 
          : Colors.red.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isConnected ? Icons.check_circle : Icons.error,
            color: widget.isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isConnected 
                ? 'Connected - Ready to transfer files' 
                : 'Not connected - Connect first to transfer files',
            style: TextStyle(
              color: widget.isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Section where user can pick and send a file
  Widget _buildSendFileSection() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Icon and title
          const Row(
            children: [
              Icon(Icons.upload_file, color: Colors.red, size: 32),
              SizedBox(width: 10),
              Text(
                'Send a File',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Information text
          Text(
            'Select any file up to ${FileUtils.formatFileSize(FileTransferConstants.maxFileSize)} to send',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 15),
          
          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isConnected && !_isPickingFile
                  ? _pickAndSendFile
                  : null, // Disabled if not connected or already picking
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isPickingFile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.attach_file),
              label: Text(
                _isPickingFile ? 'Opening file picker...' : 'Choose File',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // List of currently active transfers (sending or receiving)
  Widget _buildActiveTransfersList() {
    final activeTransfers = _fileService.activeTransfers;
    
    // If no active transfers, show a message
    if (activeTransfers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'No active transfers',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              'Send a file to get started',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    // Show list of active transfers
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: activeTransfers.length,
      itemBuilder: (context, index) {
        final transfer = activeTransfers[index];
        return _buildTransferCard(transfer);
      },
    );
  }
  
  // Individual transfer card showing progress
  Widget _buildTransferCard(FileTransferItem transfer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: transfer.isSending 
              ? Colors.blue.withOpacity(0.3) 
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File icon and name
          Row(
            children: [
              Text(
                FileUtils.getFileIcon(transfer.fileName),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transfer.formattedSize,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Direction indicator (sending or receiving)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: transfer.isSending 
                      ? Colors.blue.withOpacity(0.2) 
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      transfer.isSending ? Icons.upload : Icons.download,
                      size: 16,
                      color: transfer.isSending ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      transfer.isSending ? 'Sending' : 'Receiving',
                      style: TextStyle(
                        color: transfer.isSending ? Colors.blue : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transfer.status == TransferStatus.completed
                        ? 'Completed'
                        : 'Transferring...',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    transfer.progressPercentage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: transfer.progress,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  transfer.isSending ? Colors.blue : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // ACTION METHODS
  // ==========================================================================
  
  // Open file picker and send selected file
  Future<void> _pickAndSendFile() async {
    try {
      setState(() => _isPickingFile = true);
      
      // Step 1: Open file picker (native system file browser)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow any file type
      );
      
      setState(() => _isPickingFile = false);
      
      // Step 2: Check if user cancelled
      if (result == null) {
        print('📂 File picker cancelled');
        return;
      }
      
      // Step 3: Get the selected file
      final filePath = result.files.single.path;
      if (filePath == null) {
        _showError('Could not access the selected file');
        return;
      }
      
      final file = File(filePath);
      
      // Step 4: Check if file exists
      if (!await file.exists()) {
        _showError('File does not exist');
        return;
      }
      
      // Step 5: Check file size
      final fileSize = await file.length();
      if (!FileUtils.isFileSizeValid(fileSize)) {
        _showError(
          'File too large!\nMaximum size: ${FileUtils.formatFileSize(FileTransferConstants.maxFileSize)}\n'
          'Selected file: ${FileUtils.formatFileSize(fileSize)}'
        );
        return;
      }
      
      print('✅ File selected: ${result.files.single.name} (${FileUtils.formatFileSize(fileSize)})');
      
      // Step 6: Show confirmation dialog
      final confirmed = await _showSendConfirmation(result.files.single.name, fileSize);
      if (!confirmed) {
        print('📤 User cancelled send');
        return;
      }
      
      // Step 7: Send the file!
      print('📤 Starting file transfer...');
      final success = await _fileService.sendFile(file, widget.sendMessage);
      
      if (success) {
        setState(() {}); // Refresh UI
        _showSuccess('File sent successfully!');
      } else {
        _showError('Failed to send file');
      }
      
    } catch (e) {
      setState(() => _isPickingFile = false);
      print('❌ Error picking file: $e');
      _showError('Error: $e');
    }
  }
  
  // Show confirmation dialog before sending
  Future<bool> _showSendConfirmation(String fileName, int fileSize) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'Send File?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: $fileName',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              'Size: ${FileUtils.formatFileSize(fileSize)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            const Text(
              'This will be sent to the connected device.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // Show transfer history
  void _showHistory() {
    final completed = _fileService.completedTransfers;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'Transfer History',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: completed.isEmpty
              ? const Text(
                  'No completed transfers yet',
                  style: TextStyle(color: Colors.grey),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: completed.length,
                  itemBuilder: (context, index) {
                    final transfer = completed[index];
                    return ListTile(
                      leading: Text(
                        FileUtils.getFileIcon(transfer.fileName),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        transfer.fileName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${transfer.isSending ? "Sent" : "Received"} • ${transfer.formattedSize}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Icon(
                        transfer.status == TransferStatus.completed
                            ? Icons.check_circle
                            : Icons.error,
                        color: transfer.status == TransferStatus.completed
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
