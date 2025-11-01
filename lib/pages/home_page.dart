import 'package:flutter/material.dart';
import 'package:bt_classic/bt_classic.dart';
import 'package:permission_handler/permission_handler.dart';

import 'message_host.dart';
import 'message_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Discovery for Join flow
  final _client = BluetoothClientService();
  final List<BluetoothDevice> _found = [];
  bool _discovering = false;
  bool _permissionsOk = false;

  @override
  void initState() {
    super.initState();

    // Callbacks for discovery
    _client.onDeviceFound = (d) {
      if (!mounted) return;
      setState(() => _found.add(d));
    };
    _client.onDiscoveryFinished = () {
      if (!mounted) return;
      setState(() => _discovering = false);
    };

    // Pre-warm permissions so UI feels smooth
    Future.microtask(_ensurePerms);
  }

  Future<void> _ensurePerms() async {
    // Your existing style of perms + bt_classic helper
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    _permissionsOk = await _client.requestPermissions();
    if (!_permissionsOk && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required.')),
      );
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _found.clear();
      _discovering = true;
    });
    await _ensurePerms();
    if (!_permissionsOk) {
      if (mounted) setState(() => _discovering = false);
      return;
    }
    final started = await _client.startDiscovery();
    if (!started && mounted) {
      setState(() => _discovering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discovery failed to start')),
      );
    }
  }

  @override
  void dispose() {
    _client.stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // === Your original AppBar preserved ===
        appBar: AppBar(
          backgroundColor: Colors.red,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_outlined),
          ),
          title: const Text(
            "ShadowMesh",
            style: TextStyle(
              color: Color.fromRGBO(11, 11, 13, 1.0),
              fontFamily: "Orbitron",
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            // Scan shortcut
            IconButton(
              tooltip: 'Scan',
              icon: Icon(_discovering ? Icons.sync : Icons.search),
              onPressed: _discovering ? null : _startDiscovery,
            ),
          ],
        ),

        // === Your dark background preserved ===
        body: Container(
          color: const Color(0xFF0B0B0D),
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              // Keep your header (unchanged)
              const Center(
                child: Text(
                  "Paired Devices",
                  style: TextStyle(color: Colors.grey, fontSize: 20),
                ),
              ),
              const SizedBox(height: 6),
              // Extra hint (added, but doesn’t remove anything)
              const Text(
                'Tip: For phone-to-phone chat, tap Host on one phone, then Join (scan) here.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // NEW: Host / Join buttons (added)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F1F1F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cast_connected),
                      label: const Text('Host (start server)'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MessageHost()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Join (scan)'),
                      onPressed: _discovering ? null : () async {
                        await _startDiscovery(); // start immediately
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_discovering)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('Scanning for nearby hosts…',
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),

              // Show discovered devices to join
              Expanded(
                child: _discovering && _found.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _found.isEmpty
                        ? const Center(
                            child: Text(
                              'No devices found yet.\nTap the search icon or Join (scan).',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _found.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final d = _found[index];
                              final title = d.name.isNotEmpty ? d.name : 'Unknown Device';
                              final subtitle = d.address; // MAC/ID
                              return ListTile(
                                leading: const Icon(Icons.bluetooth_connected,
                                    color: Colors.white),
                                title: Text(title,
                                    style: const TextStyle(color: Colors.white)),
                                subtitle: Text(subtitle,
                                    style: const TextStyle(color: Colors.white70)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.message, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MessageClient(device: d),
                                      ),
                                    );
                                  },
                                  tooltip: 'Message',
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MessageClient(device: d),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
