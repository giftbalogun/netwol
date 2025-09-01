// ignore_for_file: use_build_context_synchronously

/*
 * ------------------------------------------------------------
 * Project: NETWOL
 * Author: Gift Balogun
 * Company: Royal Bcode Ventures
 * Created: 2025-07-28
 * Contact: giftbalogun@royalbv.name.ng
 * ------------------------------------------------------------
 * © 2025 Gift Balogun. All rights reserved.
 */

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'port_scanner.dart';
import 'package:netwol/help.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  Hive.registerAdapter(DeviceTypeAdapter());
  Hive.registerAdapter(NetworkDeviceAdapter());

  await Hive.openBox<NetworkDevice>('devices');
  
  runApp(NetwolApp());
}

class NetwolApp extends StatelessWidget {
  const NetwolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DeviceManager()..init(),
      child: MaterialApp(
        title: 'Netwol - Your Network Control',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Color(0xFF0A0A0A),
          cardTheme: CardTheme(
            color: Color(0xFF1A1A1A),
            elevation: 8,
            shadowColor: Colors.cyan.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: MainNavigation(),
      ),
    );
  }
}

@HiveType(typeId: 1)
enum DeviceType {
  @HiveField(0)
  computer,
  
  @HiveField(1)
  server,
  
  @HiveField(2)
  router,
  
  @HiveField(3)
  printer,
  
  @HiveField(4)
  nas,
  
  @HiveField(5)
  other
}

@HiveType(typeId: 0)
class NetworkDevice extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String ipAddress;
  
  @HiveField(3)
  String macAddress;
  
  @HiveField(4)
  String? sshUsername;
  
  @HiveField(5)
  bool isOnline;
  
  @HiveField(6)
  DateTime lastChecked;
  
  @HiveField(7)
  int? sshPort;
  
  @HiveField(8)
  DeviceType type;

  NetworkDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.macAddress,
    this.sshUsername,
    this.isOnline = false,
    required this.lastChecked,
    this.sshPort = 22,
    this.type = DeviceType.computer,
  });

  // Keep JSON methods for backward compatibility if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'sshUsername': sshUsername,
      'isOnline': isOnline,
      'lastChecked': lastChecked.toIso8601String(),
      'sshPort': sshPort,
      'type': type.name,
    };
  }

  factory NetworkDevice.fromJson(Map<String, dynamic> json) {
    return NetworkDevice(
      id: json['id'],
      name: json['name'],
      ipAddress: json['ipAddress'],
      macAddress: json['macAddress'],
      sshUsername: json['sshUsername'],
      isOnline: json['isOnline'] ?? false,
      lastChecked: DateTime.parse(json['lastChecked']),
      sshPort: json['sshPort'] ?? 22,
      type: DeviceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeviceType.computer,
      ),
    );
  }
}

// Hive Type Adapters
class DeviceTypeAdapter extends TypeAdapter<DeviceType> {
  @override
  final int typeId = 1;

  @override
  DeviceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DeviceType.computer;
      case 1:
        return DeviceType.server;
      case 2:
        return DeviceType.router;
      case 3:
        return DeviceType.printer;
      case 4:
        return DeviceType.nas;
      case 5:
        return DeviceType.other;
      default:
        return DeviceType.computer;
    }
  }

  @override
  void write(BinaryWriter writer, DeviceType obj) {
    switch (obj) {
      case DeviceType.computer:
        writer.writeByte(0);
        break;
      case DeviceType.server:
        writer.writeByte(1);
        break;
      case DeviceType.router:
        writer.writeByte(2);
        break;
      case DeviceType.printer:
        writer.writeByte(3);
        break;
      case DeviceType.nas:
        writer.writeByte(4);
        break;
      case DeviceType.other:
        writer.writeByte(5);
        break;
    }
  }
}

class NetworkDeviceAdapter extends TypeAdapter<NetworkDevice> {
  @override
  final int typeId = 0;

  @override
  NetworkDevice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NetworkDevice(
      id: fields[0] as String,
      name: fields[1] as String,
      ipAddress: fields[2] as String,
      macAddress: fields[3] as String,
      sshUsername: fields[4] as String?,
      isOnline: fields[5] as bool? ?? false,
      lastChecked: fields[6] as DateTime,
      sshPort: fields[7] as int?,
      type: fields[8] as DeviceType? ?? DeviceType.computer,
    );
  }

  @override
  void write(BinaryWriter writer, NetworkDevice obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ipAddress)
      ..writeByte(3)
      ..write(obj.macAddress)
      ..writeByte(4)
      ..write(obj.sshUsername)
      ..writeByte(5)
      ..write(obj.isOnline)
      ..writeByte(6)
      ..write(obj.lastChecked)
      ..writeByte(7)
      ..write(obj.sshPort)
      ..writeByte(8)
      ..write(obj.type);
  }

  @override
  Type get isAdapterOf => NetworkDevice;
}

class DeviceManager extends ChangeNotifier {
  List<NetworkDevice> _devices = [];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Timer? _statusTimer;
  bool _isChecking = false;
  bool _initialized = false;
  late Box<NetworkDevice> _deviceBox;

  List<NetworkDevice> get devices => _devices;
  bool get isChecking => _isChecking;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _deviceBox = Hive.box<NetworkDevice>('devices');
    await _loadDevices();
    _startStatusMonitoring();
  }

  void _startStatusMonitoring() {
    _statusTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!_isChecking && _devices.isNotEmpty) {
        checkAllDevicesStatus();
      }
    });
  }

  Future<void> _loadDevices() async {
    try {
      _devices = _deviceBox.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading devices from Hive: $e');
    }
  }

  Future<void> _saveDevice(NetworkDevice device) async {
    try {
      await _deviceBox.put(device.id, device);
    } catch (e) {
      debugPrint('Error saving device to Hive: $e');
      rethrow;
    }
  }

  Future<void> addDevice(NetworkDevice device) async {
    _devices.add(device);
    await _saveDevice(device);
    notifyListeners();
  }

  Future<void> updateDevice(NetworkDevice device) async {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index] = device;
      await _saveDevice(device);
      notifyListeners();
    }
  }

  Future<void> removeDevice(String id) async {
    try {
      _devices.removeWhere((d) => d.id == id);
      await _deviceBox.delete(id);
      await _secureStorage.delete(key: 'ssh_password_$id');
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing device from Hive: $e');
      rethrow;
    }
  }

  Future<void> saveSSHPassword(String deviceId, String password) async {
    await _secureStorage.write(key: 'ssh_password_$deviceId', value: password);
  }

  Future<String?> getSSHPassword(String deviceId) async {
    return await _secureStorage.read(key: 'ssh_password_$deviceId');
  }

  Future<void> checkAllDevicesStatus() async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    final futures = _devices.map((device) async {
      try {
        final isOnline = await NetworkUtils.checkDeviceOnline(device.ipAddress);
        device.isOnline = isOnline;
        device.lastChecked = DateTime.now();
        // Save updated device status to Hive
        await _saveDevice(device);
      } catch (e) {
        device.isOnline = false;
        device.lastChecked = DateTime.now();
        await _saveDevice(device);
      }
    });

    await Future.wait(futures);
    _isChecking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}

class NetworkUtils {
  static Future<bool> sendWakeOnLAN(
    String macAddress, {
    String? targetIP,
  }) async {
    try {
      // Clean and validate MAC address
      String cleanMac =
          macAddress.replaceAll(RegExp(r'[:\-\s]'), '').toUpperCase();
      if (cleanMac.length != 12 ||
          !RegExp(r'^[0-9A-F]{12}$').hasMatch(cleanMac)) {
        throw Exception('Invalid MAC address format');
      }

      // Create magic packet
      final packet = Uint8List(102);

      // First 6 bytes: 0xFF
      for (int i = 0; i < 6; i++) {
        packet[i] = 0xFF;
      }

      // Next 96 bytes: MAC address repeated 16 times
      final macBytes = <int>[];
      for (int i = 0; i < 12; i += 2) {
        macBytes.add(int.parse(cleanMac.substring(i, i + 2), radix: 16));
      }

      for (int rep = 0; rep < 16; rep++) {
        for (int i = 0; i < 6; i++) {
          packet[6 + rep * 6 + i] = macBytes[i];
        }
      }

      // Send packets to multiple addresses and ports
      final addresses = <String>[
        '255.255.255.255', // Global broadcast
      ];

      // Add subnet broadcast if target IP provided
      if (targetIP != null) {
        final parts = targetIP.split('.');
        if (parts.length == 4) {
          addresses.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
        }
      }

      bool success = false;
      for (final address in addresses) {
        for (final port in [7, 9]) {
          try {
            final socket = await RawDatagramSocket.bind(
              InternetAddress.anyIPv4,
              0,
            );
            socket.broadcastEnabled = true;
            final bytesSent = socket.send(
              packet,
              InternetAddress(address),
              port,
            );
            socket.close();
            if (bytesSent > 0) success = true;
            debugPrint('WOL packet sent to $address:$port ($bytesSent bytes)');
          } catch (e) {
            debugPrint('Failed to send WOL to $address:$port: $e');
          }
        }
      }

      return success;
    } catch (e) {
      debugPrint('WOL Error: $e');
      return false;
    }
  }

  static Future<bool> checkDeviceOnline(
    String ipAddress, {
    int timeoutSeconds = 3,
  }) async {
    try {
      // Try multiple methods to detect if device is online

      // Method 1: Try common ports
      final commonPorts = [22, 80, 135, 443, 3389, 5900];
      for (final port in commonPorts) {
        try {
          final socket = await Socket.connect(
            ipAddress,
            port,
            timeout: Duration(seconds: 1),
          );
          socket.destroy();
          return true;
        } catch (e) {
          // Port not open, try next
        }
      }

      // Method 2: ICMP Ping using system ping command
      return await _pingDevice(ipAddress, timeoutSeconds);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _pingDevice(String ipAddress, int timeoutSeconds) async {
    try {
      final Process process;
      if (Platform.isWindows) {
        process = await Process.start('ping', [
          '-n',
          '1',
          '-w',
          '${timeoutSeconds * 1000}',
          ipAddress,
        ]);
      } else {
        process = await Process.start('ping', [
          '-c',
          '1',
          '-W',
          '$timeoutSeconds',
          ipAddress,
        ]);
      }

      final exitCode = await process.exitCode.timeout(
        Duration(seconds: timeoutSeconds + 1),
      );
      return exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shutdownDevice(
    String ipAddress,
    String username,
    String password, {
    int port = 22,
  }) async {
    try {
      if (Platform.isWindows) {
        // Windows shutdown via network
        final result = await Process.run('shutdown', [
          '/s',
          '/m',
          '\\\\$ipAddress',
          '/t',
          '5',
          '/f',
        ]).timeout(const Duration(seconds: 10));
        return result.exitCode == 0;
      } else {
        // SSH shutdown for Unix systems
        final result = await Process.run('ssh', [
          '-o',
          'ConnectTimeout=5',
          '-o',
          'StrictHostKeyChecking=no',
          '-p',
          '$port',
          '$username@$ipAddress',
          'sudo shutdown -h +1',
        ]).timeout(const Duration(seconds: 10));
        return result.exitCode == 0;
      }
    } catch (e) {
      debugPrint('Shutdown error: $e');
      return false;
    }
  }
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.network_wifi, color: Colors.cyan),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Netwol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text('Your Network Control', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<DeviceManager>(
            builder: (context, manager, child) {
              return IconButton(
                icon: manager.isChecking 
                  ? SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan)
                    )
                  : Icon(Icons.refresh),
                onPressed: manager.isChecking ? null : () => manager.checkAllDevicesStatus(),
                tooltip: 'Refresh all devices',
              );
            },
          ),
        ],
      ),
      body: Consumer<DeviceManager>(
        builder: (context, manager, child) {
          if (manager.devices.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildDeviceList(context, manager);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeviceDialog(context),
        icon: Icon(Icons.add),
        label: Text('Add Device'),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.devices, size: 64, color: Colors.cyan),
          ),
          SizedBox(height: 24),
          Text(
            'No Devices Added',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first network device to get started',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showAddDeviceDialog(context),
            icon: Icon(Icons.add),
            label: Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, DeviceManager manager) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: manager.devices.length,
      itemBuilder: (context, index) {
        return DeviceCard(device: manager.devices[index]);
      },
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DeviceDialog(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    DevicesPage(),
    PortScannerPage(),
    HelpPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Color(0xFF1A1A1A),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.devices),
            selectedIcon: Icon(Icons.devices, color: Colors.cyan),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.scanner),
            selectedIcon: Icon(Icons.scanner, color: Colors.cyan),
            label: 'Port Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help, color: Colors.cyan),
            label: 'Help',
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final NetworkDevice device;

  const DeviceCard({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 16),
            _buildDeviceInfo(),
            SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getDeviceTypeColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getDeviceTypeIcon(),
            color: _getDeviceTypeColor(),
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: device.isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    device.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: device.isOnline ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '• ${_formatLastChecked()}',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(context);
            } else if (value == 'delete') {
              _confirmDelete(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.language, 'IP Address', device.ipAddress),
          SizedBox(height: 8),
          _buildInfoRow(Icons.network_wifi, 'MAC Address', device.macAddress),
          if (device.sshUsername != null) ...[
            SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'SSH User', device.sshUsername!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: Colors.grey, fontSize: 12)),
        SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(fontFamily: 'monospace'))),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _wakeDevice(context),
            icon: Icon(Icons.power_settings_new),
            label: Text('Wake'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed:
                device.isOnline && device.sshUsername != null
                    ? () => _shutdownDevice(context)
                    : null,
            icon: Icon(Icons.power_off),
            label: Text('Shutdown'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _getDeviceTypeColor() {
    switch (device.type) {
      case DeviceType.computer:
        return Colors.blue;
      case DeviceType.server:
        return Colors.orange;
      case DeviceType.router:
        return Colors.purple;
      case DeviceType.printer:
        return Colors.green;
      case DeviceType.nas:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getDeviceTypeIcon() {
    switch (device.type) {
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.router:
        return Icons.router;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.nas:
        return Icons.storage;
      default:
        return Icons.device_unknown;
    }
  }

  String _formatLastChecked() {
    final now = DateTime.now();
    final diff = now.difference(device.lastChecked);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _wakeDevice(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final success = await NetworkUtils.sendWakeOnLAN(
        device.macAddress,
        targetIP: device.ipAddress,
      );

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Wake-on-LAN packet sent to ${device.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Check status after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          final manager = Provider.of<DeviceManager>(context, listen: false);
          manager.checkAllDevicesStatus();
        });
      } else {
        throw Exception('Failed to send magic packet');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to wake ${device.name}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

Future<void> _shutdownDevice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Shutdown'),
            content: Text('Are you sure you want to shutdown ${device.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Shutdown'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    final manager = Provider.of<DeviceManager>(context, listen: false);

    try {
      final password = await manager.getSSHPassword(device.id);
      if (password == null) {
        throw Exception('No SSH password stored');
      }

      final success = await NetworkUtils.shutdownDevice(
        device.ipAddress,
        device.sshUsername!,
        password,
        port: device.sshPort ?? 22,
      );

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Shutdown command sent to ${device.name}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Check status after 10 seconds
        Future.delayed(Duration(seconds: 10), () {
          manager.checkAllDevicesStatus();
        });
      } else {
        throw Exception('Shutdown command failed');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to shutdown ${device.name}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DeviceDialog(device: device),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Device'),
            content: Text('Are you sure you want to delete ${device.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final manager = Provider.of<DeviceManager>(context, listen: false);
      await manager.removeDevice(device.id);
    }
  }
}

class DeviceDialog extends StatefulWidget {
  final NetworkDevice? device;

  const DeviceDialog({Key? key, this.device}) : super(key: key);

  @override
  State<DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ipController;
  late final TextEditingController _macController;
  late final TextEditingController _sshUserController;
  late final TextEditingController _sshPasswordController;
  late final TextEditingController _sshPortController;
  late DeviceType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device?.name ?? '');
    _ipController = TextEditingController(text: widget.device?.ipAddress ?? '');
    _macController = TextEditingController(
      text: widget.device?.macAddress ?? '',
    );
    _sshUserController = TextEditingController(
      text: widget.device?.sshUsername ?? '',
    );
    _sshPasswordController = TextEditingController();
    _sshPortController = TextEditingController(
      text: (widget.device?.sshPort ?? 22).toString(),
    );
    _selectedType = widget.device?.type ?? DeviceType.computer;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.device == null ? 'Add Device' : 'Edit Device'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DeviceType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Device Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items:
                    DeviceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Device Name',
                  prefixIcon: Icon(Icons.device_hub),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a device name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'IP Address',
                  prefixIcon: Icon(Icons.language),
                  hintText: '192.168.1.100',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an IP address';
                  }
                  final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                  if (!ipRegex.hasMatch(value.trim())) {
                    return 'Invalid IP address format';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _macController,
                decoration: InputDecoration(
                  labelText: 'MAC Address',
                  prefixIcon: Icon(Icons.network_wifi),
                  hintText: 'AA:BB:CC:DD:EE:FF',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a MAC address';
                  }
                  final macRegex = RegExp(
                    r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
                  );
                  if (!macRegex.hasMatch(value.trim())) {
                    return 'Invalid MAC address format';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SSH Configuration (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Required for remote shutdown functionality',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sshUserController,
                decoration: InputDecoration(
                  labelText: 'SSH Username',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'admin, root, etc.',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sshPasswordController,
                decoration: InputDecoration(
                  labelText: 'SSH Password',
                  prefixIcon: Icon(Icons.lock),
                  hintText:
                      widget.device != null
                          ? 'Leave empty to keep current'
                          : 'Enter password',
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sshPortController,
                decoration: InputDecoration(
                  labelText: 'SSH Port',
                  prefixIcon: Icon(Icons.settings_ethernet),
                  hintText: '22',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final port = int.tryParse(value);
                    if (port == null || port < 1 || port > 65535) {
                      return 'Invalid port number';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveDevice,
          child: Text(widget.device == null ? 'Add Device' : 'Save Changes'),
        ),
      ],
    );
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;

    final manager = Provider.of<DeviceManager>(context, listen: false);

    try {
      final device = NetworkDevice(
        id:
            widget.device?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        ipAddress: _ipController.text.trim(),
        macAddress: _macController.text.trim().toUpperCase(),
        sshUsername:
            _sshUserController.text.trim().isEmpty
                ? null
                : _sshUserController.text.trim(),
        sshPort: int.tryParse(_sshPortController.text.trim()) ?? 22,
        type: _selectedType,
        lastChecked: DateTime.now(),
      );

      // Save SSH password if provided
      if (_sshPasswordController.text.isNotEmpty) {
        await manager.saveSSHPassword(device.id, _sshPasswordController.text);
      }

      if (widget.device == null) {
        await manager.addDevice(device);
      } else {
        await manager.updateDevice(device);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.device == null
                ? 'Device added successfully'
                : 'Device updated successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving device: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _macController.dispose();
    _sshUserController.dispose();
    _sshPasswordController.dispose();
    _sshPortController.dispose();
    super.dispose();
  }
}