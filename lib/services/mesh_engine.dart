import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class MeshPacket {
  final String packetId;
  final String phone;
  final double latitude;
  final double longitude;
  final int hops;
  final int timestamp;

  MeshPacket({
    required this.packetId,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.hops = 0,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': packetId,
        'phone': phone,
        'lat': latitude,
        'lon': longitude,
        'hops': hops,
        'time': timestamp,
      };

  factory MeshPacket.fromJson(Map<String, dynamic> json) => MeshPacket(
        packetId: json['id'] as String,
        phone: json['phone'] as String,
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
        hops: json['hops'] as int,
        timestamp: json['time'] as int,
      );

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(jsonEncode(toMap())));

  factory MeshPacket.fromBytes(Uint8List bytes) =>
      MeshPacket.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
}

class MeshEngine {
  static final MeshEngine _instance = MeshEngine._internal();
  factory MeshEngine() => _instance;
  MeshEngine._internal();

  final Strategy _strategy = Strategy.P2P_CLUSTER;
  final String _serviceId = "com.weathergpt.sos.mesh";

  final Set<String> _seenPacketIds = {};
  final List<String> _connectedEndpoints = [];
  bool isBroadcasting = false;

  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((status) => status.isGranted || status.isLimited);
  }

  Future<void> startMesh({
    required String userName,
    Function(MeshPacket packet)? onPacketReceived,
  }) async {
    if (kIsWeb) {
      debugPrint("Mesh Engine: Running on Web preview (Hardware BLE radios disabled).");
      return;
    }

    final granted = await checkAndRequestPermissions();
    if (!granted) {
      debugPrint("Mesh Engine: Permissions not granted.");
      return;
    }

    isBroadcasting = true;

    try {
      await Nearby().startAdvertising(
        userName,
        _strategy,
        onConnectionInitiated: (id, info) => _onConnectionInit(id, info, onPacketReceived),
        onConnectionResult: (id, status) => _onConnectionResult(id, status),
        onDisconnected: (id) => _connectedEndpoints.remove(id),
        serviceId: _serviceId,
      );
    } catch (e) {
      debugPrint("Advertising error: $e");
    }

    try {
      await Nearby().startDiscovery(
        userName,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (endpointId, info) =>
                _onConnectionInit(endpointId, info, onPacketReceived),
            onConnectionResult: (endpointId, status) =>
                _onConnectionResult(endpointId, status),
            onDisconnected: (endpointId) => _connectedEndpoints.remove(endpointId),
          );
        },
        onEndpointLost: (id) => _connectedEndpoints.remove(id),
        serviceId: _serviceId,
      );
    } catch (e) {
      debugPrint("Discovery error: $e");
    }
  }

  void _onConnectionInit(
    String endpointId,
    ConnectionInfo info,
    Function(MeshPacket packet)? onPacketReceived,
  ) {
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          try {
            final packet = MeshPacket.fromBytes(payload.bytes!);
            if (_seenPacketIds.contains(packet.packetId)) return;
            _seenPacketIds.add(packet.packetId);

            if (onPacketReceived != null) onPacketReceived(packet);

            forwardPacket(
              MeshPacket(
                packetId: packet.packetId,
                phone: packet.phone,
                latitude: packet.latitude,
                longitude: packet.longitude,
                hops: packet.hops + 1,
                timestamp: packet.timestamp,
              ),
              excludeEndpoint: endpointId,
            );
          } catch (e) {
            debugPrint("Error parsing payload: $e");
          }
        }
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(endpointId);
    } else {
      _connectedEndpoints.remove(endpointId);
    }
  }

  Future<void> sendSosDistressBeacon({
    required String phone,
    required double lat,
    required double lon,
  }) async {
    final String id = "${DateTime.now().millisecondsSinceEpoch}_$phone";
    _seenPacketIds.add(id);

    final packet = MeshPacket(
      packetId: id,
      phone: phone,
      latitude: lat,
      longitude: lon,
      hops: 0,
    );

    await forwardPacket(packet);
  }

  Future<void> forwardPacket(MeshPacket packet, {String? excludeEndpoint}) async {
    if (kIsWeb) return;

    final bytes = packet.toBytes();
    for (String endpoint in _connectedEndpoints) {
      if (endpoint != excludeEndpoint) {
        await Nearby().sendBytesPayload(endpoint, bytes);
      }
    }
  }

  Future<void> stopMesh() async {
    if (kIsWeb) return;
    
    isBroadcasting = false;
    _connectedEndpoints.clear();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
  }
}