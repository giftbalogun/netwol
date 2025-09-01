import 'package:hive/hive.dart';

// part 'network_device.g.dart';

@HiveType(typeId: 0)
enum DeviceType {
  @HiveField(0)
  computer,
  @HiveField(1)
  router,
  @HiveField(2)
  printer,
  @HiveField(3)
  custom,
}

@HiveType(typeId: 1)
class NetworkDevice extends HiveObject {
  @HiveField(0)
  String id;

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
}
