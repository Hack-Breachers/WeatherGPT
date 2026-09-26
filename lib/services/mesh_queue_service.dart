import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mesh_engine.dart';

class MeshQueueService {
  static const String _queueKey = 'weathergpt_mesh_pending_packets';

  Future<List<MeshPacket>> getPendingPackets() async {
    final prefs = await SharedPreferences.getInstance();

    final rawList = prefs.getStringList(_queueKey) ?? [];

    final packets = <MeshPacket>[];

    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          packets.add(MeshPacket.fromMap(decoded));
        }
      } catch (_) {
        // Ignore one corrupted packet and keep the remaining queue.
      }
    }

    return packets;
  }

  Future<void> savePacket(MeshPacket packet) async {
    final packets = await getPendingPackets();

    final alreadyExists = packets.any(
      (existing) => existing.packetId == packet.packetId,
    );

    if (alreadyExists) {
      return;
    }

    packets.add(packet);
    await _savePackets(packets);
  }

  Future<void> markDelivered(String packetId) async {
    await deletePacket(packetId);
  }

  Future<void> deletePacket(String packetId) async {
    final packets = await getPendingPackets();

    packets.removeWhere(
      (packet) => packet.packetId == packetId,
    );

    await _savePackets(packets);
  }

  Future<void> retryPacket(String packetId) async {
    final packets = await getPendingPackets();

    final packetIndex = packets.indexWhere(
      (packet) => packet.packetId == packetId,
    );

    if (packetIndex == -1) {
      return;
    }

    final packet = packets[packetIndex];

    packets[packetIndex] = MeshPacket(
      packetId: packet.packetId,
      packetType: packet.packetType,
      originId: packet.originId,
      ackFor: packet.ackFor,
      phone: packet.phone,
      latitude: packet.latitude,
      longitude: packet.longitude,
      category: packet.category,
      severity: packet.severity,
      hops: packet.hops,
      ttl: packet.ttl,
      timestamp: packet.timestamp,
    );

    await _savePackets(packets);
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  Future<void> _savePackets(List<MeshPacket> packets) async {
    final prefs = await SharedPreferences.getInstance();

    final rawList = packets
        .map((packet) => jsonEncode(packet.toMap()))
        .toList();

    await prefs.setStringList(_queueKey, rawList);
  }
}