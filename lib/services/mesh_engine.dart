import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'mesh_queue_service.dart';

class MeshPacket {
  final String packetId;
  final String packetType;
  final String originId;
  final String? ackFor;
  final String phone;
  final double latitude;
  final double longitude;
  final String category;
  final int severity;
  final String locationCode;
  final String message;
  final int hops;
  final int ttl;
  final int timestamp;

  MeshPacket({
  String? packetId,
  String? id,
  this.packetType = 'DATA',
  this.originId = '',
  this.ackFor,
  required this.phone,
  double? latitude,
  double? lat,
  double? longitude,
  double? lon,
  this.category = 'STRANDED',
  this.severity = 4,
  this.locationCode = '',
  this.message = '',
  this.hops = 0,
  this.ttl = 8,
  int? timestamp,
})  : packetId = packetId ?? id ?? '',
        latitude = latitude ?? lat ?? 0.0,
        longitude = longitude ?? lon ?? 0.0,
        timestamp =
            timestamp ?? DateTime.now().millisecondsSinceEpoch;

  String get id => packetId;
  double get lat => latitude;
  double get lon => longitude;

  Uint8List toBytes() {
    return Uint8List.fromList(
      utf8.encode(jsonEncode(toMap())),
    );
  }

  static MeshPacket fromBytes(List<int> bytes) {
    final map =
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    return MeshPacket.fromMap(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': packetId,
      'packetId': packetId,
      'packetType': packetType,
      'originId': originId,
      'ackFor': ackFor,
      'phone': phone,
      'lat': latitude,
      'latitude': latitude,
      'lon': longitude,
      'longitude': longitude,
      'category': category,
      'severity': severity,
      'locationCode': locationCode,
      'message': message,
      'hops': hops,
      'ttl': ttl,
      'timestamp': timestamp,
    };
  }

  factory MeshPacket.fromMap(Map<String, dynamic> map) {
    return MeshPacket(
      packetId:
          (map['packetId'] ?? map['id'])?.toString() ?? '',

      packetType:
        map['packetType']?.toString() ?? 'DATA',

      originId:
        map['originId']?.toString() ?? '',

      ackFor:
        map['ackFor']?.toString(),
      
      phone: map['phone']?.toString() ?? '',

      latitude:
          ((map['latitude'] ?? map['lat']) as num?)
                  ?.toDouble() ??
              0.0,

      longitude:
          ((map['longitude'] ?? map['lon']) as num?)
                  ?.toDouble() ??
              0.0,

      category:
          map['category']?.toString() ?? 'STRANDED',

      severity:
          (map['severity'] as num?)?.toInt() ?? 4,

      locationCode:
          map['locationCode']?.toString() ?? '',

      message:
          map['message']?.toString() ?? '',

      hops:
          (map['hops'] as num?)?.toInt() ?? 0,

      ttl:
        (map['ttl'] as num?)?.toInt() ?? 8,

      timestamp:
          (map['timestamp'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
    );
  }
}

typedef SosPacket = MeshPacket;

class MeshEngine {
  static final MeshEngine _instance =
      MeshEngine._internal();

  factory MeshEngine() => _instance;

  MeshEngine._internal();

  static const String _serviceId =
      "com.weathergpt.mesh";

  // IMPORTANT:
  // Cluster is better for a multi-device disaster mesh.
  final Strategy _strategy =
      Strategy.P2P_CLUSTER;

  static final StreamController<MeshPacket>
      packetStreamController =
      StreamController<MeshPacket>.broadcast();

  static Stream<MeshPacket> get onPacketStream =>
      packetStreamController.stream;

  final Set<String> _connectedEndpoints = {};
  final Set<String> _pendingEndpoints = {};
  final Set<String> _seenPacketIds = {};
  final List<MeshPacket> _outboxQueue = [];
  final MeshQueueService _queueService = MeshQueueService();

  Function(MeshPacket)? _onPacketReceived;

  bool _isMeshRunning = false;
  bool _isStarting = false;

  String _currentUserName = "";

  late final String _nodeId =
      (1000 + math.Random().nextInt(9000)).toString();

  bool get isRunning => _isMeshRunning;

  bool get isBroadcasting => _isMeshRunning;

  int get activePeerCount =>
      _connectedEndpoints.length;

  // ============================================================
  // PERMISSIONS
  // ============================================================

  Future<bool> checkAndRequestPermissions() async {
    final permissions = [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ];

    final statuses =
        await permissions.request();

    for (final entry in statuses.entries) {
      debugPrint(
        "MESH PERMISSION: ${entry.key} = ${entry.value}",
      );
    }

    final granted = statuses.values.every(
      (status) =>
          status.isGranted ||
          status.isLimited,
    );

    debugPrint(
      "MESH PERMISSIONS RESULT: $granted",
    );

    return granted;
  }

  // ============================================================
  // START MESH
  // ============================================================

  Future<void> startMesh({
    required String userName,
    Function(MeshPacket)? onPacketReceived,
  }) async {
    // If already running, just update callback.
    if (_isMeshRunning) {
      debugPrint(
        "MESH: Already running. Updating packet callback.",
      );

      if (onPacketReceived != null) {
        _onPacketReceived =
            onPacketReceived;
      }

      return;
    }

    // Prevent simultaneous startup.
    if (_isStarting) {
      debugPrint(
        "MESH: Startup already in progress.",
      );
      return;
    }

    _isStarting = true;

    try {
      final hasPermissions =
          await checkAndRequestPermissions();

      if (!hasPermissions) {
        debugPrint(
          "MESH ERROR: Required permissions denied.",
        );
        return;
      }

      // Clean old Nearby state.
      try {
        await Nearby().stopAllEndpoints();
      } catch (_) {}

      try {
        await Nearby().stopDiscovery();
      } catch (_) {}

      try {
        await Nearby().stopAdvertising();
      } catch (_) {}

      _currentUserName =
          "${userName}_#$_nodeId";

      _onPacketReceived =
          onPacketReceived;

      _connectedEndpoints.clear();
      _pendingEndpoints.clear();

      final pendingPackets =
        await _queueService.getPendingPackets();
          _outboxQueue.clear();
          _outboxQueue.addAll(
            pendingPackets,
          );
          debugPrint(
            "MESH: Restored ${pendingPackets.length} pending packet(s) from persistent queue.",
          );

      _isMeshRunning = true;

      debugPrint(
        "========================================",
      );

      debugPrint(
        "MESH STARTING",
      );

      debugPrint(
        "MESH NODE: $_currentUserName",
      );

      debugPrint(
        "MESH SERVICE: $_serviceId",
      );

      debugPrint(
        "MESH STRATEGY: P2P_CLUSTER",
      );

      debugPrint(
        "========================================",
      );

      await _startAdvertising();

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      await _startDiscovery();

      debugPrint(
        "MESH: Mesh startup complete.",
      );
    } catch (e, stack) {
      debugPrint(
        "MESH START ERROR: $e",
      );

      debugPrint(
        "$stack",
      );

      _isMeshRunning = false;
    } finally {
      _isStarting = false;
    }
  }

  // ============================================================
  // ADVERTISING
  // ============================================================

  Future<void> _startAdvertising() async {
    try {
      debugPrint(
        "MESH: Starting advertising...",
      );

      await Nearby().startAdvertising(
        _currentUserName,
        _strategy,

        onConnectionInitiated:
            _handleConnectionInitiation,

        onConnectionResult:
            (endpointId, status) {
          _handleConnectionResult(
            endpointId,
            status,
          );
        },

        onDisconnected:
            (endpointId) {
          _handleDisconnection(
            endpointId,
          );
        },

        serviceId: _serviceId,
      );

      debugPrint(
        "MESH: Advertising ACTIVE.",
      );
    } catch (e) {
      debugPrint(
        "MESH ADVERTISE ERROR: $e",
      );
    }
  }

  // ============================================================
  // DISCOVERY
  // ============================================================

  Future<void> _startDiscovery() async {
    try {
      debugPrint(
        "MESH: Starting discovery...",
      );

      await Nearby().startDiscovery(
        _currentUserName,
        _strategy,

        onEndpointFound:
            (id, name, serviceId) async {
          debugPrint(
            "MESH DISCOVERY: Found endpoint",
          );

          debugPrint(
            "  ID: $id",
          );

          debugPrint(
            "  NAME: $name",
          );

          debugPrint(
            "  SERVICE: $serviceId",
          );

          // Ignore wrong service.
          if (serviceId != _serviceId) {
            debugPrint(
              "MESH: Ignoring endpoint with wrong service ID.",
            );
            return;
          }

          // Ignore ourselves.
          if (name == _currentUserName ||
              name.contains(_nodeId)) {
            debugPrint(
              "MESH: Ignoring self endpoint.",
            );
            return;
          }

          // Already connected.
          if (_connectedEndpoints
              .contains(id)) {
            debugPrint(
              "MESH: Endpoint already connected.",
            );
            return;
          }

          // Connection already being attempted.
          if (_pendingEndpoints
              .contains(id)) {
            debugPrint(
              "MESH: Connection already pending.",
            );
            return;
          }

          _pendingEndpoints.add(id);

          debugPrint(
            "MESH: REQUESTING CONNECTION -> $name ($id)",
          );

          try {
            await Nearby().requestConnection(
              _currentUserName,
              id,

              onConnectionInitiated:
                  _handleConnectionInitiation,

              onConnectionResult:
                  (endpointId, status) {
                _handleConnectionResult(
                  endpointId,
                  status,
                );
              },

              onDisconnected:
                  (endpointId) {
                _handleDisconnection(
                  endpointId,
                );
              },
            );

            debugPrint(
              "MESH: Connection request sent -> $id",
            );
          } catch (e) {
            _pendingEndpoints.remove(id);

            debugPrint(
              "MESH REQUEST ERROR [$id]: $e",
            );
          }
        },

        onEndpointLost: (id) {
          if (id != null) {
            debugPrint(
              "MESH: Endpoint lost -> $id",
            );

            _pendingEndpoints.remove(id);
          }
        },

        serviceId: _serviceId,
      );

      debugPrint(
        "MESH: Discovery ACTIVE.",
      );
    } catch (e) {
      debugPrint(
        "MESH DISCOVERY ERROR: $e",
      );
    }
  }

  // ============================================================
  // CONNECTION INITIATED
  // ============================================================

  Future<void> _handleConnectionInitiation(
    String endpointId,
    ConnectionInfo info,
  ) async {
    debugPrint(
      "========================================",
    );

    debugPrint(
      "MESH: CONNECTION INITIATED",
    );

    debugPrint(
      "MESH: Endpoint ID: $endpointId",
    );

    debugPrint(
      "MESH: Endpoint Name: ${info.endpointName}",
    );

    debugPrint(
      "========================================",
    );

    // Never connect to ourselves.
    if (info.endpointName ==
            _currentUserName ||
        info.endpointName.contains(
          _nodeId,
        )) {
      debugPrint(
        "MESH: Rejecting self connection.",
      );

      try {
        await Nearby()
            .rejectConnection(
          endpointId,
        );
      } catch (_) {}

      return;
    }

    try {
      debugPrint(
        "MESH: ACCEPTING connection from ${info.endpointName}",
      );

      await Nearby().acceptConnection(
        endpointId,

        onPayLoadRecieved:
            (endId, payload) {
          _handleIncomingPayload(
            endId,
            payload,
          );
        },

        onPayloadTransferUpdate:
            (endId, update) {
          debugPrint(
            "MESH PAYLOAD UPDATE: $endId -> $update",
          );
        },
      );

      debugPrint(
        "MESH: Connection ACCEPTED -> $endpointId",
      );
    } catch (e) {
      debugPrint(
        "MESH ACCEPT ERROR [$endpointId]: $e",
      );
    }
  }

  // ============================================================
  // CONNECTION RESULT
  // ============================================================

  void _handleConnectionResult(
    String endpointId,
    Status status,
  ) {
    debugPrint(
      "========================================",
    );

    debugPrint(
      "MESH: CONNECTION RESULT",
    );

    debugPrint(
      "MESH: Endpoint: $endpointId",
    );

    debugPrint(
      "MESH: Status: $status",
    );

    debugPrint(
      "========================================",
    );

    _pendingEndpoints.remove(
      endpointId,
    );

    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(
        endpointId,
      );

      debugPrint(
        "MESH: PEER CONNECTED!",
      );

      debugPrint(
        "MESH: Active peers = ${_connectedEndpoints.length}",
      );

      // Deliver queued packets.
      _flushOutboxToPeer(
        endpointId,
      );
    } else {
      _connectedEndpoints.remove(
        endpointId,
      );

      debugPrint(
        "MESH: Connection FAILED.",
      );

      debugPrint(
        "MESH: Status = $status",
      );
    }
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  void _handleDisconnection(
    String endpointId,
  ) {
    _connectedEndpoints.remove(
      endpointId,
    );

    _pendingEndpoints.remove(
      endpointId,
    );

    debugPrint(
      "MESH: PEER DISCONNECTED -> $endpointId",
    );

    debugPrint(
      "MESH: Remaining peers = ${_connectedEndpoints.length}",
    );
  }

  // ============================================================
  // INCOMING PAYLOAD
  // ============================================================

  Future<void> _handleIncomingPayload(
    String fromEndpointId,
    Payload payload,
  ) async{
    debugPrint(
      "MESH: PAYLOAD RECEIVED from $fromEndpointId",
    );

    debugPrint(
      "MESH: Payload type = ${payload.type}",
    );

    if (payload.type !=
            PayloadType.BYTES ||
        payload.bytes == null) {
      debugPrint(
        "MESH: Ignoring non-byte payload.",
      );
      return;
    }

    try {
      final jsonString =
          utf8.decode(
        payload.bytes!,
      );

      debugPrint(
        "MESH: Raw payload = $jsonString",
      );

      final data =
          jsonDecode(jsonString)
              as Map<String, dynamic>;

      final packet =
          MeshPacket.fromMap(data);

      // ACK packets confirm successful delivery.
if (packet.packetType == 'ACK') {
  final ackedPacketId = packet.ackFor;

  if (ackedPacketId != null &&
      ackedPacketId.isNotEmpty) {
    debugPrint(
      "MESH: ACK RECEIVED for packet $ackedPacketId",
    );

    await _queueService.markDelivered(
      ackedPacketId,
    );

    _outboxQueue.removeWhere(
      (queuedPacket) =>
          queuedPacket.packetId == ackedPacketId,
    );
  }

  return;
}

      debugPrint(
        "========================================",
      );

      debugPrint(
        "🚨 MESH PACKET RECEIVED",
      );

      debugPrint(
        "ID: ${packet.id}",
      );

      debugPrint(
        "PHONE: ${packet.phone}",
      );

      debugPrint(
        "LOCATION: ${packet.lat}, ${packet.lon}",
      );

      debugPrint(
        "HOPS: ${packet.hops}",
      );

      debugPrint(
        "========================================",
      );

      // Duplicate protection.
      if (_seenPacketIds.contains(packet.id)) {
        debugPrint(
          "MESH: Duplicate packet received -> ${packet.id}",
        );
        await _sendAck(
          packet,
          fromEndpointId,
        );

        return;
      }

      _seenPacketIds.add(
        packet.id,
      );

      // Notify UI.
      packetStreamController.add(
        packet,
      );

      _onPacketReceived?.call(
        packet,
      );

      // Relay.
      if (packet.ttl > 0) {
        awaitRelay(
          packet,
          fromEndpointId,
        );
      }
    } catch (e) {
      debugPrint(
        "MESH PAYLOAD ERROR: $e",
      );
    }
  }

  Future<void> _sendAck(
  MeshPacket packet,
  String endpointId,
) async {
  final ackPacket = MeshPacket(
    packetId:
        'ACK-${packet.packetId}-$_nodeId',
    packetType: 'ACK',
    originId: _nodeId,
    ackFor: packet.packetId,
    phone: packet.phone,
    latitude: packet.latitude,
    longitude: packet.longitude,
    category: packet.category,
    severity: packet.severity,
    hops: 0,
    ttl: 8,
    timestamp:
        DateTime.now().millisecondsSinceEpoch,
  );

  try {
    await Nearby().sendBytesPayload(
      endpointId,
      ackPacket.toBytes(),
    );

    debugPrint(
      "MESH: ACK SENT for ${packet.packetId} -> $endpointId",
    );
  } catch (e) {
    debugPrint(
      "MESH: ACK SEND FAILED for ${packet.packetId}: $e",
    );
  }
}

  // ============================================================
  // RELAY
  // ============================================================

  Future<void> awaitRelay(
    MeshPacket packet,
    String fromEndpointId,
  ) async {
    final relayedPacket =
    MeshPacket(
      packetId: packet.packetId,
      packetType: packet.packetType,
      originId: packet.originId,
      ackFor: packet.ackFor,
      phone: packet.phone,
      latitude: packet.latitude,
      longitude: packet.longitude,
      category: packet.category,
      severity: packet.severity,
      locationCode: packet.locationCode,
      message: packet.message,
      hops: packet.hops + 1,
      ttl: packet.ttl - 1,
      timestamp: packet.timestamp,
    );

    debugPrint(
      "MESH: RELAYING packet ${packet.id}",
    );

    debugPrint(
      "MESH: New hop = ${relayedPacket.hops}",
    );

    await _broadcastPacket(
      relayedPacket,
      excludeEndpoint:
          fromEndpointId,
    );
  }

  // ============================================================
  // SEND SOS
  // ============================================================

  Future<void> sendSosDistressBeacon({
    required String phone,
    double? lat,
    double? latitude,
    double? lon,
    double? longitude,
    String category = "STRANDED",
    int severity = 4,
    String locationCode = '',
    String message = '',
    String? packetId,
  }) async {
    final actualLat =
        latitude ?? lat ?? 0.0;

    final actualLon =
        longitude ?? lon ?? 0.0;

    final packet =
      MeshPacket(
        packetId:
          packetId ?? "${DateTime.now().millisecondsSinceEpoch}_$phone",
        packetType: 'DATA',
        originId: _nodeId,
        phone: phone,
        latitude: actualLat,
        longitude: actualLon,
        category: category,
        severity: severity,
        locationCode: locationCode,
        message: message,
        hops: 0,
        timestamp:
          DateTime.now()
              .millisecondsSinceEpoch,
      );

      await _queueService.savePacket(packet);

    debugPrint(
      "========================================",
    );

    debugPrint(
      "MESH: CREATING SOS PACKET",
    );

    debugPrint(
      "ID: ${packet.id}",
    );

    debugPrint(
      "PHONE: ${packet.phone}",
    );

    debugPrint(
      "LOCATION: ${packet.lat}, ${packet.lon}",
    );

    debugPrint(
      "CONNECTED PEERS: ${_connectedEndpoints.length}",
    );

    debugPrint(
      "========================================",
    );

    _seenPacketIds.add(
      packet.id,
    );

    // Queue it first.
    _outboxQueue.add(
      packet,
    );

    if (_connectedEndpoints.isEmpty) {
      debugPrint(
        "MESH: NO PEERS CONNECTED.",
      );

      debugPrint(
        "MESH: Packet stored in outbox.",
      );

      debugPrint(
        "MESH: Waiting for peer connection...",
      );

      return;
    }

    await _broadcastPacket(
      packet,
    );
  }

  // ============================================================
  // FLUSH QUEUED PACKETS
  // ============================================================

  Future<void> _flushOutboxToPeer(
    String endpointId,
  ) async {
    if (_outboxQueue.isEmpty) {
      debugPrint(
        "MESH: No queued packets.",
      );
      return;
    }

    debugPrint(
      "MESH: FLUSHING ${_outboxQueue.length} queued packet(s)",
    );

    final packets =
        List<MeshPacket>.from(
      _outboxQueue,
    );

    for (final packet in packets) {
      try {
        debugPrint(
          "MESH: Sending queued packet ${packet.id} -> $endpointId",
        );

        await Nearby().sendBytesPayload(
          endpointId,
          packet.toBytes(),
        );

        debugPrint(
          "MESH: QUEUED PACKET SENT SUCCESSFULLY -> $endpointId",
        );

      } catch (e) {
        debugPrint(
          "MESH OUTBOX SEND ERROR [$endpointId]: $e",
        );
      }
    }
  }

  // ============================================================
  // BROADCAST
  // ============================================================

  Future<void> _broadcastPacket(
    MeshPacket packet, {
    String? excludeEndpoint,
  }) async {
    if (_connectedEndpoints.isEmpty) {
      debugPrint(
        "MESH: Broadcast skipped - no connected peers.",
      );
      return;
    }

    final bytes =
        packet.toBytes();

    debugPrint(
      "MESH: BROADCASTING packet ${packet.id}",
    );

    debugPrint(
      "MESH: Peers = ${_connectedEndpoints.length}",
    );

    for (final endpointId
        in List<String>.from(
      _connectedEndpoints,
    )) {
      if (endpointId ==
          excludeEndpoint) {
        continue;
      }

      try {
        debugPrint(
          "MESH: Sending ${bytes.length} bytes -> $endpointId",
        );

        await Nearby()
            .sendBytesPayload(
          endpointId,
          bytes,
        );

        debugPrint(
          "MESH: PAYLOAD SENT SUCCESSFULLY -> $endpointId",
        );
      } catch (e) {
        debugPrint(
          "MESH SEND ERROR [$endpointId]: $e",
        );
      }
    }
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stopMesh() async {
    debugPrint(
      "MESH: STOP REQUESTED",
    );

    _isMeshRunning = false;

    _connectedEndpoints.clear();
    _pendingEndpoints.clear();

    // Do NOT clear outbox here if you want
    // packets to survive temporary disconnects.
    // _outboxQueue.clear();

    try {
      await Nearby()
          .stopAdvertising();
    } catch (_) {}

    try {
      await Nearby()
          .stopDiscovery();
    } catch (_) {}

    try {
      await Nearby()
          .stopAllEndpoints();
    } catch (_) {}

    debugPrint(
      "MESH: Radios halted.",
    );
  }
}