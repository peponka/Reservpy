import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/utils/date_utils.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/waitlist_repository.dart';

/// "Mi lista de espera" (12/9/2026) — anotaciones activas del cliente.
/// Las 'waiting' son pasivas; las 'notified' son accionables: hay un turno
/// concreto ofrecido y una ventana de tiempo para confirmarlo o rechazarlo.
class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  final _busyIds = <String>{};

  Future<void> _confirm(WaitlistEntry entry) async {
    setState(() => _busyIds.add(entry.id));
    try {
      await WaitlistRepository().confirm(entry);
      ref.invalidate(clientWaitlistProvider);
      ref.invalidate(clientReservationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Turno confirmado! Lo vas a ver en Mis Reservas.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo confirmar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  Future<void> _decline(WaitlistEntry entry) async {
    setState(() => _busyIds.add(entry.id));
    try {
      await WaitlistRepository().decline(entry.id);
      ref.invalidate(clientWaitlistProvider);
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  Future<void> _leave(WaitlistEntry entry) async {
    setState(() => _busyIds.add(entry.id));
    try {
      await WaitlistRepository().leave(entry.id);
      ref.invalidate(clientWaitlistProvider);
    } finally {
      if (mounted) setState(() => _busyIds.remove(entry.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(clientWaitlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi lista de espera'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(clientWaitlistProvider),
        child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (entries) {
            if (entries.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: AppSizes.s64),
                  EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No estás en ninguna lista de espera',
                    subtitle: 'Cuando un día esté completo podés anotarte para que te avisemos si se libera un turno.',
                  ),
                ],
              );
            }
            final notified = entries.where((e) => e.status == WaitlistStatus.notified).toList();
            final waiting = entries.where((e) => e.status == WaitlistStatus.waiting).toList();
            return ListView(
              padding: const EdgeInsets.all(AppSizes.s16),
              children: [
                if (notified.isNotEmpty) ...[
                  Text('Turno liberado — confirmá antes de que pase al siguiente',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSizes.s8),
                  ...notified.map((e) => _NotifiedCard(
                        entry: e,
                        busy: _busyIds.contains(e.id),
                        onConfirm: () => _confirm(e),
                        onDecline: () => _decline(e),
                      )),
                  const SizedBox(height: AppSizes.s20),
                ],
                if (waiting.isNotEmpty) ...[
                  Text('Esperando que se libere un turno',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSizes.s8),
                  ...waiting.map((e) => _WaitingCard(
                        entry: e,
                        busy: _busyIds.contains(e.id),
                        onLeave: () => _leave(e),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotifiedCard extends StatelessWidget {
  final WaitlistEntry entry;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const _NotifiedCard({required this.entry, required this.busy, required this.onConfirm, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = entry.notifiedStartTime;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.businessName ?? 'Negocio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (entry.serviceName != null) Text(entry.serviceName!, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSizes.s8),
            if (start != null)
              Text(
                '${AppDateUtils.formatDayMonth(start)} · ${AppDateUtils.formatTime(start)}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
              ),
            const SizedBox(height: AppSizes.s12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onDecline,
                    child: const Text('No puedo'),
                  ),
                ),
                const SizedBox(width: AppSizes.s8),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onConfirm,
                    child: busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Confirmar turno'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final WaitlistEntry entry;
  final bool busy;
  final VoidCallback onLeave;

  const _WaitingCard({required this.entry, required this.busy, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: ListTile(
        title: Text(entry.businessName ?? 'Negocio'),
        subtitle: Text(
          '${entry.serviceName != null ? '${entry.serviceName} · ' : ''}${AppDateUtils.formatDayMonth(entry.preferredDate)}',
        ),
        trailing: busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Salir de la lista',
                onPressed: onLeave,
              ),
      ),
    );
  }
}
