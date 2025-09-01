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

import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Setup Guide'),
        backgroundColor: Color(0xFF1A1A1A),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(),
            SizedBox(height: 24),
            _buildGeneralRequirements(),
            SizedBox(height: 24),
            _buildLinuxSection(),
            SizedBox(height: 24),
            _buildTrueNASSection(),
            SizedBox(height: 24),
            _buildProxmoxSection(),
            SizedBox(height: 24),
            _buildTroubleshootingSection(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.cyan, size: 28),
                SizedBox(width: 12),
                Text(
                  'Wake-on-LAN Setup Guide',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Wake-on-LAN (WOL) allows you to remotely power on a system via a network packet called a "magic packet". This guide covers setup for Linux desktops, TrueNAS, and Proxmox systems.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setup Process Overview:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
                  ),
                  SizedBox(height: 8),
                  Text('1. Enable WOL in BIOS/UEFI'),
                  Text('2. Configure the operating system/network card'),
                  Text('3. Send magic packet using this app'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralRequirements() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'General Requirements (All)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildRequirementItem(
              '✅ Hardware Support',
              'Your motherboard and network interface card (NIC) must support WOL',
            ),
            SizedBox(height: 12),
            _buildRequirementItem(
              '✅ BIOS/UEFI Setting',
              'Enable "Wake on LAN", "Power on by PCI-E", or "Wake on PME" in BIOS/UEFI setup',
            ),
            SizedBox(height: 12),
            _buildRequirementItem(
              '✅ Ethernet Connection',
              'WOL does NOT work over Wi-Fi - must be connected via Ethernet cable',
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter BIOS by pressing Del, F2, or F12 during boot',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinuxSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.computer, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Linux Desktop',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '(Ubuntu, Fedora)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 1: Check WOL Support',
              'ethtool eth0',
              'Look for "Supports Wake-on: pumbg" and "Wake-on: g". If "Wake-on: d", WOL is disabled.',
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 2: Enable WOL',
              'sudo ethtool -s eth0 wol g',
              'Replace eth0 with your actual network interface name from "ip link".',
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 3: Make Persistent (systemd)',
              '''sudo nano /etc/systemd/system/wol@.service

[Unit]
Description=Enable Wake-on-LAN for %i
After=network.target

[Service]
ExecStart=/sbin/ethtool -s %i wol g

[Install]
WantedBy=multi-user.target

# Then enable:
sudo systemctl enable wol@eth0.service''',
              'This ensures WOL stays enabled after reboots.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrueNASSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.teal, size: 24),
                SizedBox(width: 12),
                Text(
                  'TrueNAS (CORE/SCALE)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.yellow, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TrueNAS does NOT enable WOL by default',
                      style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 1: Access Shell',
              'SSH into TrueNAS or use Shell from web GUI',
              'You need command line access to configure WOL.',
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 2: Find and Enable WOL',
              '''ip link  # Find your network interface
ethtool enp0s3  # Check WOL support
sudo ethtool -s enp0s3 wol g  # Enable WOL''',
              'Replace enp0s3 with your actual interface name.',
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 3: Make Persistent',
              '''In TrueNAS Web GUI:
• System → Advanced
• Init/Shutdown Scripts
• Add Post Init script:
  /usr/sbin/ethtool -s enp0s3 wol g
• Type: Command, When: Post Init''',
              'This runs the WOL command after each boot.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProxmoxSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns, color: Colors.purple, size: 24),
                SizedBox(width: 12),
                Text(
                  'Proxmox VE',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 1: Enable WOL on NIC',
              '''ip link  # Find network interface
ethtool eno1  # Check support
sudo ethtool -s eno1 wol g  # Enable WOL''',
              'Similar to Linux desktop setup.',
            ),
            SizedBox(height: 16),
            _buildStepSection(
              'Step 2: Make Persistent (Network Config)',
              '''sudo nano /etc/network/interfaces

# Add to your interface section:
iface eno1 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    up ethtool -s eno1 wol g

# Then restart networking:
sudo systemctl restart networking''',
              'The "up" command runs when interface comes online.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.troubleshoot, color: Colors.red, size: 24),
                SizedBox(width: 12),
                Text(
                  'Troubleshooting Tips',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildTroubleshootItem(
              'WOL Not Working?',
              '• Check BIOS settings are enabled\n• Verify Ethernet connection\n• Test with "ethtool" command\n• Check firewall settings',
            ),
            SizedBox(height: 12),
            _buildTroubleshootItem(
              'Magic Packet Not Received?',
              '• Ensure devices are on same network\n• Try different broadcast addresses\n• Check network switch settings\n• Verify MAC address is correct',
            ),
            SizedBox(height: 12),
            _buildTroubleshootItem(
              'Settings Don\'t Persist?',
              '• Use systemd service method\n• Check init scripts are enabled\n• Verify file permissions\n• Test after reboot',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: Colors.grey[300]),
        ),
      ],
    );
  }

  Widget _buildStepSection(String title, String command, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Text(
            command,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.green[300],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTroubleshootItem(String title, String tips) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[300]),
          ),
          SizedBox(height: 8),
          Text(
            tips,
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
        ],
      ),
    );
  }
}