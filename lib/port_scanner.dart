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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PortScanResult {
  final String host;
  final int port;
  final bool isOpen;
  final String? service;
  final int responseTimeMs;

  PortScanResult({
    required this.host,
    required this.port,
    required this.isOpen,
    this.service,
    required this.responseTimeMs,
  });
}

class ScanSession {
  final String id;
  final String target;
  final List<int> ports;
  final DateTime startTime;
  DateTime? endTime;
  final List<PortScanResult> results;
  bool isCompleted;

  ScanSession({
    required this.id,
    required this.target,
    required this.ports,
    required this.startTime,
    this.endTime,
    List<PortScanResult>? results,
    this.isCompleted = false,
  }) : results = results ?? [];
}

class PortScannerService extends ChangeNotifier {
  final List<ScanSession> _scanHistory = [];
  ScanSession? _currentScan;
  bool _isScanning = false;

  List<ScanSession> get scanHistory => _scanHistory;
  ScanSession? get currentScan => _currentScan;
  bool get isScanning => _isScanning;

  // Common service ports with descriptions
  static const Map<int, String> commonPorts = {
    21: 'FTP',
    22: 'SSH',
    23: 'Telnet',
    25: 'SMTP',
    53: 'DNS',
    80: 'HTTP',
    110: 'POP3',
    143: 'IMAP',
    443: 'HTTPS',
    993: 'IMAPS',
    995: 'POP3S',
    135: 'RPC',
    139: 'NetBIOS',
    445: 'SMB',
    3389: 'RDP',
    5900: 'VNC',
    8080: 'HTTP-Alt',
    3306: 'MySQL',
    5432: 'PostgreSQL',
    1433: 'MSSQL',
    6379: 'Redis',
    27017: 'MongoDB',
  };

  Future<void> scanPorts(String host, List<int> ports, {int timeoutMs = 3000}) async {
    if (_isScanning) return;

    _isScanning = true;
    _currentScan = ScanSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      target: host,
      ports: List.from(ports),
      startTime: DateTime.now(),
    );
    notifyListeners();

    try {
      final List<Future<PortScanResult>> futures = ports.map((port) async {
        final stopwatch = Stopwatch()..start();
        
        try {
          final socket = await Socket.connect(
            host, 
            port, 
            timeout: Duration(milliseconds: timeoutMs)
          );
          socket.destroy();
          stopwatch.stop();
          
          return PortScanResult(
            host: host,
            port: port,
            isOpen: true,
            service: commonPorts[port],
            responseTimeMs: stopwatch.elapsedMilliseconds,
          );
        } catch (e) {
          stopwatch.stop();
          return PortScanResult(
            host: host,
            port: port,
            isOpen: false,
            service: commonPorts[port],
            responseTimeMs: stopwatch.elapsedMilliseconds,
          );
        }
      }).toList();

      // Process results as they complete
      for (final future in futures) {
        final result = await future;
        _currentScan?.results.add(result);
        notifyListeners();
      }

      _currentScan?.endTime = DateTime.now();
      _currentScan?.isCompleted = true;
      
      if (_currentScan != null) {
        _scanHistory.insert(0, _currentScan!);
        if (_scanHistory.length > 10) {
          _scanHistory.removeLast();
        }
      }
    } catch (e) {
      debugPrint('Port scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _scanHistory.clear();
    notifyListeners();
  }

  List<int> getCommonPorts() => commonPorts.keys.toList()..sort();
  
  List<int> getWebPorts() => [80, 443, 8080, 8443, 3000, 8000, 9000];
  
  List<int> getDatabasePorts() => [3306, 5432, 1433, 6379, 27017];
  
  List<int> getRemoteAccessPorts() => [22, 23, 3389, 5900, 5901];
}

class PortScannerPage extends StatefulWidget {
  @override
  State<PortScannerPage> createState() => _PortScannerPageState();
}

class _PortScannerPageState extends State<PortScannerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _hostController = TextEditingController();
  final _portsController = TextEditingController();
  late PortScannerService _scannerService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerService = PortScannerService();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _scannerService,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.scanner, color: Colors.orange),
              SizedBox(width: 12),
              Text('Port Scanner'),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Scanner', icon: Icon(Icons.search)),
              Tab(text: 'History', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildScannerTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScanForm(),
          SizedBox(height: 24),
          _buildPresetButtons(),
          SizedBox(height: 24),
          Consumer<PortScannerService>(
            builder: (context, service, child) {
              if (service.currentScan != null) {
                return _buildCurrentScanResults(service.currentScan!);
              }
              return _buildScanTips();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Port Scan Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: 'Target Host/IP',
                prefixIcon: Icon(Icons.language),
                hintText: '192.168.1.1 or example.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _portsController,
              decoration: InputDecoration(
                labelText: 'Ports (comma-separated or ranges)',
                prefixIcon: Icon(Icons.settings_ethernet),
                hintText: '22,80,443 or 1-1000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            Consumer<PortScannerService>(
              builder: (context, service, child) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: service.isScanning ? null : _startScan,
                    icon: service.isScanning 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.play_arrow),
                    label: Text(service.isScanning ? 'Scanning...' : 'Start Scan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButtons() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Scan Presets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('Common Ports', _scannerService.getCommonPorts()),
                _buildPresetChip('Web Servers', _scannerService.getWebPorts()),
                _buildPresetChip('Databases', _scannerService.getDatabasePorts()),
                _buildPresetChip('Remote Access', _scannerService.getRemoteAccessPorts()),
                _buildPresetChip('Top 100', List.generate(100, (i) => i + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, List<int> ports) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _portsController.text = ports.join(',');
      },
      backgroundColor: Colors.orange.withOpacity(0.2),
      labelStyle: TextStyle(color: Colors.orange),
    );
  }

  Widget _buildCurrentScanResults(ScanSession scan) {
    final openPorts = scan.results.where((r) => r.isOpen).length;
    final totalPorts = scan.ports.length;
    final progress = scan.results.length / totalPorts;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scanner, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanning ${scan.target}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${scan.results.length}/$totalPorts ports checked • $openPorts open',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            SizedBox(height: 16),
            if (scan.results.where((r) => r.isOpen).isNotEmpty) ...[
              Text(
                'Open Ports Found:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 8),
              ...scan.results.where((r) => r.isOpen).map((result) => 
                _buildPortResultItem(result)
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortResultItem(PortScanResult result) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isOpen ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: result.isOpen ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Port ${result.port}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (result.service != null) ...[
            SizedBox(width: 8),
            Text('(${result.service})', style: TextStyle(color: Colors.grey)),
          ],
          Spacer(),
          Text(
            '${result.responseTimeMs}ms',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTips() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Scanning Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildTipItem('Use IP addresses for faster scanning'),
            _buildTipItem('Common ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)'),
            _buildTipItem('Port ranges: 1-1000 or specific ports: 22,80,443'),
            _buildTipItem('Scanning takes time - be patient with large ranges'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Colors.blue, fontSize: 16)),
          SizedBox(width: 8),
          Expanded(child: Text(tip, style: TextStyle(color: Colors.grey[300]))),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<PortScannerService>(
      builder: (context, service, child) {
        if (service.scanHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Scan History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Your completed scans will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: service.scanHistory.length,
          itemBuilder: (context, index) {
            final scan = service.scanHistory[index];
            return _buildHistoryItem(scan);
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(ScanSession scan) {
    final openPorts = scan.results.where((r) => r.isOpen).length;
    final duration = scan.endTime?.difference(scan.startTime);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: Icon(Icons.scanner, color: Colors.orange),
        ),
        title: Text(scan.target, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${scan.ports.length} ports • $openPorts open'),
            Text(
              '${_formatDateTime(scan.startTime)}${duration != null ? ' • ${duration.inSeconds}s' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () => _showScanDetails(scan),
      ),
    );
  }

  void _startScan() {
    final host = _hostController.text.trim();
    final portsText = _portsController.text.trim();

    if (host.isEmpty || portsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both host and ports'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ports = _parsePorts(portsText);
    if (ports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid port format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _scannerService.scanPorts(host, ports);
  }

 List<int> _parsePorts(String portsText) {
    final ports = <int>[];
    final parts = portsText.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final range = trimmed.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0].trim());
          final end = int.tryParse(range[1].trim());
          if (start != null && end != null && start <= end) {
            for (int i = start; i <= end; i++) {
              if (i > 0 && i <= 65535) ports.add(i);
            }
          }
        }
      } else {
        final port = int.tryParse(trimmed);
        if (port != null && port > 0 && port <= 65535) {
          ports.add(port);
        }
      }
    }

    return ports.toSet().toList()..sort();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showScanDetails(ScanSession scan) {
    showDialog(
      context: context,
      builder: (context) => ScanDetailsDialog(scan: scan),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostController.dispose();
    _portsController.dispose();
    super.dispose();
  }
}

class ScanDetailsDialog extends StatelessWidget {
  final ScanSession scan;

  const ScanDetailsDialog({Key? key, required this.scan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final openPorts = scan.results.where((r) => r.isOpen).toList();
    final closedPorts = scan.results.where((r) => !r.isOpen).toList();

    return AlertDialog(
      title: Text('Scan Results - ${scan.target}'),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                indicatorColor: Colors.cyan,
                labelColor: Colors.cyan,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Open (${openPorts.length})'),
                  Tab(text: 'Closed (${closedPorts.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPortsList(openPorts, true),
                    _buildPortsList(closedPorts, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildPortsList(List<PortScanResult> ports, bool isOpen) {
    if (ports.isEmpty) {
      return Center(
        child: Text(
          isOpen ? 'No open ports found' : 'No closed ports',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: ports.length,
      itemBuilder: (context, index) {
        final port = ports[index];
        return ListTile(
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? Colors.green : Colors.red,
            ),
          ),
          title: Text('Port ${port.port}'),
          subtitle: port.service != null ? Text(port.service!) : null,
          trailing: Text('${port.responseTimeMs}ms'),
        );
      },
    );
  }
}