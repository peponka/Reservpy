import 'dart:convert';

import 'package:reservpy/src/shared/models/models.dart';

String? extractBookingGroupIdFromNotes(String? notes) {
  if (notes == null || notes.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(notes);
    if (decoded is Map<String, dynamic>) {
      final groupId = decoded['booking_group_id'];
      if (groupId is String && groupId.trim().isNotEmpty) {
        return groupId.trim();
      }
    }
  } catch (_) {}
  return null;
}

List<Reservation> groupReservationsForDisplay(List<Reservation> reservations) {
  final grouped = <String, List<Reservation>>{};

  for (final reservation in reservations) {
    final groupId = extractBookingGroupIdFromNotes(reservation.notes);
    final key = groupId == null || groupId.isEmpty ? reservation.id : 'group:$groupId';
    grouped.putIfAbsent(key, () => []).add(reservation);
  }

  final result = <Reservation>[];
  for (final entry in grouped.entries) {
    final items = entry.value..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (items.length == 1) {
      result.add(items.first);
      continue;
    }

    final first = items.first;
    final last = items.last;
    final serviceNames = items
        .map((r) => r.serviceName)
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    result.add(Reservation(
      id: first.id,
      businessId: first.businessId,
      clientId: first.clientId,
      serviceId: first.serviceId,
      startTime: first.startTime,
      endTime: last.endTime,
      status: first.status,
      notes: first.notes,
      cancellationReason: first.cancellationReason,
      createdAt: first.createdAt,
      isManual: first.isManual,
      manualClientName: first.manualClientName,
      manualClientPhone: first.manualClientPhone,
      clientName: first.clientName,
      serviceName: serviceNames.isEmpty ? first.serviceName : serviceNames.join(' + '),
      businessName: first.businessName,
      employeeId: first.employeeId,
      employeeName: first.employeeName,
    ));
  }

  result.sort((a, b) => b.startTime.compareTo(a.startTime));
  return result;
}
