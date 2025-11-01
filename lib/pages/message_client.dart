import 'package:flutter/material.dart';
import 'package:bt_classic/bt_classic.dart';
import 'file_transfer_page.dart';
import '../services/file_transfer_service.dart';
import '../utils/constants.dart';

class MessageClient extends StatefulWidget {
  final BluetoothDevice device;
  const MessageClient({super.key, required this.device});

  @override
  State<MessageClient> createState() => _MessageClientState();
}

class _MessageClientState extends State<MessageClient> {
  final _client = BluetoothClientService();
  final _controller = TextEditingController();
  final List<_Msg> _msgs = [];
  bool _connecting = true;
  bool _connected = false;
  
  // File transfer service instance
  final _fileService = FileTransferService();

  @override
  void initState() {
    super.initState();

    _client.onConnected = (addr) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connected = true;
      });
    };
    _client.onDisconnected = () {
      if (!mounted) return;
      setState(() => _connected = false);
    };
    _client.onMessageReceived = (msg) {
      if (!mounted) return;
      // Check if this is a file transfer message
      if (msg.contains(FileTransferConstants.messageDelimiter)) {
        // Route to file transfer service
        _fileService.handleIncomingMessage(msg);
      } else {
        // Regular chat message
        setState(() => _msgs.add(_Msg(text: msg, sentByMe: false)));
      }
    };
    _client.onError = (err) {
      if (!mounted) return;
      setState(() => _connecting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    };

    _connect();
  }

  Future<void> _connect() async {
    final ok = await _client.requestPermissions();
    if (!ok) {
      if (mounted) setState(() => _connecting = false);
      return;
    }
    final success = await _client.connectToDevice(widget.device.address);
    if (!success && mounted) {
      setState(() => _connecting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to connect')));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_connected) return;
    _controller.clear();
    final ok = await _client.sendMessage(text);
    if (ok && mounted)
      setState(() => _msgs.add(_Msg(text: text, sentByMe: true)));
  }

  @override
  void dispose() {
    _client.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.device.name.isNotEmpty
        ? widget.device.name
        : widget.device.address;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0B0B0D),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          // File Transfer button
          IconButton(
            tooltip: 'Send File',
            icon: const Icon(Icons.attach_file),
            onPressed: _connected
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileTransferPage(
                          sendMessage: _client.sendMessage,
                          isConnected: _connected,
                        ),
                      ),
                    );
                  }
                : null, // Disabled if not connected
          ),
          if (!_connected && !_connecting)
            IconButton(
              tooltip: 'Reconnect',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _connecting = true);
                _connect();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_connecting) const LinearProgressIndicator(minHeight: 2),
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
          if (_connected)
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
          if (!_connected && !_connecting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Disconnected', style: TextStyle(color: Colors.red)),
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
