import 'package:flutter/material.dart';
import 'package:bt_classic/bt_classic.dart';
import 'file_transfer_page.dart';
import '../services/file_transfer_service.dart';
import '../services/chat_storage_service.dart';
import '../utils/constants.dart';

class MessageHost extends StatefulWidget {
  const MessageHost({super.key});
  @override
  State<MessageHost> createState() => _MessageHostState();
}

class _MessageHostState extends State<MessageHost> {
  final _host = BluetoothHostService();
  final _controller = TextEditingController();
  final List<_Msg> _msgs = [];
  bool _serverRunning = false;
  bool _clientConnected = false;
  String _clientAddr = '';
  
  // File transfer service instance
  final _fileService = FileTransferService();

  @override
  void initState() {
    super.initState();
    _host.onClientConnected = (addr) {
      setState(() {
        _clientConnected = true;
        _clientAddr = addr;
      });
    };
    _host.onClientDisconnected = () {
      setState(() {
        _clientConnected = false;
        _clientAddr = '';
      });
    };
    _host.onMessageReceived = (msg) {
      // Check if this is a file transfer message
      if (msg.contains(FileTransferConstants.messageDelimiter)) {
        // Route to file transfer service
        _fileService.handleIncomingMessage(msg);
      } else {
        // Regular chat message
        setState(() => _msgs.add(_Msg(text: msg, sentByMe: false)));
      }
    };
    _host.onError = (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    };
    _setup();
    _loadSavedChat();
  }

  // Load saved chat messages if they exist
  Future<void> _loadSavedChat() async {
    final savedMessages = await ChatStorageService.loadHostChat();
    if (savedMessages.isNotEmpty && mounted) {
      setState(() {
        _msgs.clear();
        for (var msgData in savedMessages) {
          _msgs.add(_Msg(
            text: msgData['text'] as String,
            sentByMe: msgData['sentByMe'] as bool,
          ));
        }
      });
    }
  }

  // Save current chat messages
  Future<void> _saveChat() async {
    final messagesToSave = _msgs.map((msg) => {
      'text': msg.text,
      'sentByMe': msg.sentByMe,
    }).toList();
    
    await ChatStorageService.saveHostChat(messagesToSave);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💾 Chat saved successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Clear current chat and saved messages
  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will clear the current chat and delete any saved messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _msgs.clear());
      await ChatStorageService.clearHostChat();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Chat cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _setup() async {
    final ok = await _host.requestPermissions();
    if (!ok) return;
    // Optional: make discoverable so Join can see you easily
    await _host.makeDiscoverable();
    final started = await _host.startServer();
    if (mounted) setState(() => _serverRunning = started);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    if (!_clientConnected) return;
    final ok = await _host.sendMessage(text);
    if (ok && mounted)
      setState(() => _msgs.add(_Msg(text: text, sentByMe: true)));
  }

  @override
  void dispose() {
    _host.stopServer();
    _host.disconnect();
    _controller.dispose();
    // Note: We don't clear saved chats on dispose
    // They only get cleared when explicitly saved by user or on app restart
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _serverRunning
        ? (_clientConnected ? 'Client: $_clientAddr' : 'Waiting for client…')
        : 'Starting server…';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Host (Server)',
          style: TextStyle(
            color: Color(0xFF0B0B0D),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          // Clear Chat button
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: _msgs.isNotEmpty ? _clearChat : null,
          ),
          // Save Chat button
          IconButton(
            tooltip: 'Save Chat',
            icon: const Icon(Icons.save),
            onPressed: _msgs.isNotEmpty ? _saveChat : null,
          ),
          // File Transfer button
          IconButton(
            tooltip: 'Send File',
            icon: const Icon(Icons.attach_file),
            onPressed: _clientConnected
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileTransferPage(
                          sendMessage: _host.sendMessage,
                          isConnected: _clientConnected,
                        ),
                      ),
                    );
                  }
                : null, // Disabled if no client connected
          ),
          IconButton(
            tooltip: 'Discoverable',
            icon: const Icon(Icons.visibility),
            onPressed: () => _host.makeDiscoverable(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF141416),
            padding: const EdgeInsets.all(12),
            child: Text(status, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[_msgs.length - 1 - i];
                return Align(
                  alignment: m.sentByMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m.sentByMe ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          if (_clientConnected)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool sentByMe;
  _Msg({required this.text, required this.sentByMe});
}
