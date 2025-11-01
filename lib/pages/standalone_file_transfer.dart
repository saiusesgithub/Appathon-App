import 'package:flutter/material.dart';
import 'package:bt_classic/bt_classic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/file_transfer_service.dart';
import '../models/file_transfer_item.dart';
import '../utils/file_utils.dart';
import '../utils/constants.dart';

// Standalone File Transfer Page
// This page allows users to connect and transfer files WITHOUT chat
// It's completely independent from the messaging system

class StandaloneFileTransferPage extends StatefulWidget {
  const StandaloneFileTransferPage({super.key});

  @override
  State<StandaloneFileTransferPage> createState() => _StandaloneFileTransferPageState();
}

class _StandaloneFileTransferPageState extends State<StandaloneFileTransferPage> {
  // Bluetooth services - we manage our own connection here
  final _client = BluetoothClientService();
  final _host = BluetoothHostService();
  
  // File transfer service
  final _fileService = FileTransferService();
  
  // Connection state
  bool _isHost = false;           // Am I hosting or joining?
  bool _isHosting = false;        // Is host server running?
  bool _isConnected = false;      // Are we connected to another device?
  bool _isSearching = false;      // Are we scanning for devices?
  String _connectedDevice = '';   // Name of connected device
  
  // Discovered devices (for joining)
  final List<BluetoothDevice> _foundDevices = [];
  
  // Track if picking file
  bool _isPickingFile = false;
  
  @override
  void initState() {
    super.initState();
    _setupBluetoothCallbacks();
    _setupFileTransferCallbacks();
    // Pre-warm permissions like HomePage does
    Future.microtask(_requestPermissions);
    print('📱 Standalone File Transfer Page initialized');
  }
  
  // Setup Bluetooth callbacks
  void _setupBluetoothCallbacks() {
    // Client callbacks (when joining)
    _client.onDeviceFound = (device) {
      if (!mounted) return;
      print('🔍 Device found: ${device.name.isNotEmpty ? device.name : "Unknown"} (${device.address})');
      // Add device without checking for duplicates - same as HomePage
      setState(() => _foundDevices.add(device));
    };
    
    _client.onDiscoveryFinished = () {
      if (!mounted) return;
      print('✅ Discovery finished. Found ${_foundDevices.length} devices');
      setState(() => _isSearching = false);
    };
    
    _client.onError = (error) {
      if (!mounted) return;
      print('❌ Client error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    };
    
    _client.onConnected = (addr) {
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _connectedDevice = addr;
      });
    };
    
    _client.onDisconnected = () {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _connectedDevice = '';
      });
    };
    
    _client.onMessageReceived = (msg) {
      if (!mounted) return;
      // Route to file service if it's a file transfer message
      if (msg.contains(FileTransferConstants.messageDelimiter)) {
        _fileService.handleIncomingMessage(msg);
      }
    };
    
    // Host callbacks (when hosting)
    _host.onClientConnected = (addr) {
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _connectedDevice = addr;
      });
    };
    
    _host.onClientDisconnected = () {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _connectedDevice = '';
      });
    };
    
    _host.onMessageReceived = (msg) {
      if (!mounted) return;
      // Route to file service if it's a file transfer message
      if (msg.contains(FileTransferConstants.messageDelimiter)) {
        _fileService.handleIncomingMessage(msg);
      }
    };
    
    _host.onError = (error) {
      if (!mounted) return;
      print('❌ Host error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    };
  }
  
  // Setup file transfer callbacks
  void _setupFileTransferCallbacks() {
    _fileService.onFileRequestReceived = (fileId, fileName, fileSize) {
      if (!mounted) return;
      setState(() {});
    };
    
    _fileService.onTransferProgress = (fileId, progress) {
      if (!mounted) return;
      setState(() {});
    };
    
    _fileService.onFileReceived = (completedFile) {
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ File received: ${completedFile.fileName}'),
          backgroundColor: Colors.green,
        ),
      );
    };
    
    _fileService.onTransferError = (fileId, error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    };
  }
  
  // Request Bluetooth permissions - matches HomePage approach
  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    final permissionsOk = await _client.requestPermissions();
    if (!permissionsOk && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required.')),
      );
    }
  }
  
  @override
  void dispose() {
    _client.stopDiscovery();
    _client.disconnect();
    _host.stopServer();
    _host.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        title: const Text(
          'File Transfer',
          style: TextStyle(
            color: Color(0xFF0B0B0D),
            fontFamily: "Orbitron",
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transfer History',
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF0B0B0D),
        child: Column(
          children: [
            // Connection status
            _buildConnectionStatus(),
            
            // If not connected, show connection options
            if (!_isConnected) _buildConnectionOptions(),
            
            // If connected, show file transfer interface
            if (_isConnected) ...[
              _buildSendFileSection(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Divider(color: Colors.grey),
              ),
              Expanded(child: _buildActiveTransfersList()),
            ],
          ],
        ),
      ),
    );
  }
  
  // ==========================================================================
  // UI BUILDING METHODS
  // ==========================================================================
  
  Widget _buildConnectionStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: _isConnected 
          ? Colors.green.withOpacity(0.2) 
          : Colors.orange.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.info,
            color: _isConnected ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isConnected 
                  ? 'Connected to $_connectedDevice' 
                  : 'Not connected - Choose Host or Join below',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Disconnect',
              onPressed: _disconnect,
            ),
        ],
      ),
    );
  }
  
  // Connection options (Host or Join)
  Widget _buildConnectionOptions() {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              const Icon(Icons.bluetooth, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Connect to Transfer Files',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose an option below to start',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              // Host button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isHosting ? null : _startHosting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isHosting ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(
                    _isHosting ? Icons.check_circle : Icons.wifi_tethering,
                    size: 32,
                  ),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHosting ? 'Hosting Active' : 'Host (Start Server)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isHosting 
                            ? 'Waiting for connections...'
                            : 'Let others connect to you',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Join button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSearching ? _stopScanning : _startScanning,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: _isSearching ? Colors.orange : Colors.red,
                      width: 2,
                    ),
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: _isSearching
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, size: 32),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSearching ? 'Stop Scanning' : 'Join (Scan for Devices)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isSearching ? 'Tap to stop' : 'Connect to a nearby host',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Scanning status message
              if (_isSearching) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Make sure the other device is hosting and discoverable',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Debug: Show permission check button
                TextButton.icon(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  label: const Text('Check Permissions', style: TextStyle(color: Colors.white70)),
                  onPressed: () async {
                    final btScan = await Permission.bluetoothScan.status;
                    final btConnect = await Permission.bluetoothConnect.status;
                    final location = await Permission.locationWhenInUse.status;
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Scan: $btScan, Connect: $btConnect, Location: $location'),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
              ],
              
              // Show found devices or scanning message
              if (_isSearching || _foundDevices.isNotEmpty) ...[
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Text(
                      'Found Devices:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '(${_foundDevices.length})',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Show devices if found
                if (_foundDevices.isNotEmpty) ...[
                  ...List.generate(_foundDevices.length, (index) {
                    final device = _foundDevices[index];
                    return Card(
                      color: const Color(0xFF1F1F1F),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.bluetooth, color: Colors.blue, size: 32),
                        title: Text(
                          device.name.isNotEmpty ? device.name : 'Unknown Device',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          device.address,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  }),
                ]
                // Show "searching" message if still scanning and no devices yet
                else if (_isSearching) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 15),
                        Text(
                          'Searching for nearby devices...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'This may take a few seconds',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // Send file section (when connected)
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
          Text(
            'Select any file up to ${FileUtils.formatFileSize(FileTransferConstants.maxFileSize)} to send',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPickingFile ? null : _pickAndSendFile,
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
  
  // Active transfers list
  Widget _buildActiveTransfersList() {
    final activeTransfers = _fileService.activeTransfers;
    
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
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: activeTransfers.length,
      itemBuilder: (context, index) {
        final transfer = activeTransfers[index];
        return _buildTransferCard(transfer);
      },
    );
  }
  
  // Individual transfer card
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
  
  // Start hosting (become server)
  Future<void> _startHosting() async {
    print('🎯 Starting host mode...');
    
    setState(() {
      _isHost = true;
      _isHosting = true;
    });
    
    // Ensure permissions are granted
    final permissionsOk = await _host.requestPermissions();
    if (!permissionsOk) {
      print('❌ Host permissions not granted');
      setState(() => _isHosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth permissions are required to host'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    print('✅ Making device discoverable...');
    await _host.makeDiscoverable();
    
    print('✅ Starting server...');
    final started = await _host.startServer();
    
    if (started) {
      print('✅ Host started successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🟢 Hosting started! Waiting for connections...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print('❌ Failed to start host');
      setState(() => _isHosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start hosting. Please check Bluetooth is enabled.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
  
  // Start scanning for devices - EXACT copy from HomePage
  Future<void> _startScanning() async {
    print('🔍 Starting scan...');
    setState(() {
      _foundDevices.clear();
      _isSearching = true;
    });
    
    // Request permissions first
    print('📋 Requesting permissions...');
    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();
    
    print('📋 Permission results: $results');

    final permissionsOk = await _client.requestPermissions();
    print('📋 BT Classic permissions: $permissionsOk');
    
    if (!permissionsOk) {
      if (mounted) {
        setState(() => _isSearching = false);
        
        // Check individual permission statuses for debugging
        final btScan = await Permission.bluetoothScan.status;
        final btConnect = await Permission.bluetoothConnect.status;
        final location = await Permission.locationWhenInUse.status;
        
        print('❌ Permission check - Scan: $btScan, Connect: $btConnect, Location: $location');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions denied. Tap to fix.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }
    
    print('✅ Permissions granted, starting discovery...');
    final started = await _client.startDiscovery();
    print('🔍 Discovery started: $started');
    
    if (!started && mounted) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discovery failed to start. Check Bluetooth is ON.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      // Set a timeout in case discovery doesn't auto-finish
      Future.delayed(const Duration(seconds: 12), () {
        if (mounted && _isSearching) {
          print('⏱️ Discovery timeout reached');
          setState(() => _isSearching = false);
          _client.stopDiscovery();
        }
      });
    }
  }
  
  // Stop scanning for devices
  void _stopScanning() {
    print('🛑 Stopping device scan...');
    _client.stopDiscovery();
    setState(() => _isSearching = false);
  }
  
  // Connect to a specific device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    print('🔗 Attempting to connect to ${device.name} (${device.address})...');
    
    // Show connecting message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to ${device.name.isNotEmpty ? device.name : device.address}...'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
    
    final success = await _client.connectToDevice(device.address);
    
    if (!success) {
      print('❌ Connection failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect. Make sure the device is hosting.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      print('✅ Connected successfully!');
    }
  }
  
  // Disconnect
  void _disconnect() {
    if (_isHost) {
      _host.disconnect();
      _host.stopServer();
    } else {
      _client.disconnect();
    }
    setState(() {
      _isConnected = false;
      _connectedDevice = '';
      _foundDevices.clear();
      _isHosting = false;
      _isSearching = false;
    });
  }
  
  // Pick and send file
  Future<void> _pickAndSendFile() async {
    try {
      setState(() => _isPickingFile = true);
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      
      setState(() => _isPickingFile = false);
      
      if (result == null) return;
      
      final filePath = result.files.single.path;
      if (filePath == null) {
        _showError('Could not access the selected file');
        return;
      }
      
      final file = File(filePath);
      
      if (!await file.exists()) {
        _showError('File does not exist');
        return;
      }
      
      final fileSize = await file.length();
      if (!FileUtils.isFileSizeValid(fileSize)) {
        _showError(
          'File too large!\nMax: ${FileUtils.formatFileSize(FileTransferConstants.maxFileSize)}'
        );
        return;
      }
      
      // Send via appropriate service
      final sendFunction = _isHost ? _host.sendMessage : _client.sendMessage;
      final success = await _fileService.sendFile(file, sendFunction);
      
      if (success) {
        setState(() {});
        _showSuccess('File sent successfully!');
      }
      
    } catch (e) {
      setState(() => _isPickingFile = false);
      _showError('Error: $e');
    }
  }
  
  // Show history dialog
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
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
