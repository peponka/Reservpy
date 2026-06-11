import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _ClientSummary {
  final String clientId;
  final String clientName;
  final int visits;
  final DateTime lastVisit;
  final List<String> serviceNames;

  const _ClientSummary({
    required this.clientId,
    required this.clientName,
    required this.visits,
    required this.lastVisit,
    required this.serviceNames,
  });
}

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'Última reserva';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ClientSummary> _buildClients(List<Reservation> reservations) {
    final map = <String, List<Reservation>>{};
    for (final r in reservations) {
      if (r.clientId == null) continue;
      map.putIfAbsent(r.clientId!, () => []).add(r);
    }

    final clients = map.entries.map((e) {
      final res = e.value;
      res.sort((a, b) => b.startTime.compareTo(a.startTime));
      final services = res
          .map((r) => r.serviceName ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .take(3)
          .toList();
      return _ClientSummary(
        clientId: e.key,
        clientName: res.first.clientName ?? 'Cliente',
        visits: res.length,
        lastVisit: res.first.startTime,
        serviceNames: services,
      );
    }).toList();

    // Apply search filter
    final query = _searchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? clients
        : clients.where((c) => c.clientName.toLowerCase().contains(query)).toList();

    // Apply sort
    switch (_sortBy) {
      case 'Nombre (A-Z)':
        filtered.sort((a, b) => a.clientName.compareTo(b.clientName));
        break;
      case 'Más visitas':
        filtered.sort((a, b) => b.visits.compareTo(a.visits));
        break;
      default: // 'Última reserva'
        filtered.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reservationsAsync = ref.watch(businessReservationsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48,
              maxWidth: constraints.maxWidth - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────
                Text(
                  'Gestión de Clientes',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  'Historial y estadísticas de tus clientes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),

                // ── Search + Sort ──────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final searchBar = Expanded(
                      flex: isMobile ? 1 : 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: colorScheme.outline,
                            ),
                            filled: true,
                            fillColor: theme.cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    final sortDropdown = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16,
                        vertical: AppSizes.s4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (String? v) {
                            if (v != null) setState(() => _sortBy = v);
                          },
                          items: ['Última reserva', 'Nombre (A-Z)', 'Más visitas']
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('Ordenar: $v'),
                                  ))
                              .toList(),
                        ),
                      ),
                    );

                    return isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children: [searchBar]),
                              const SizedBox(height: AppSizes.s12),
                              sortDropdown,
                            ],
                          )
                        : Row(
                            children: [
                              searchBar,
                              const SizedBox(width: AppSizes.s16),
                              sortDropdown,
                            ],
                          );
                  },
                ),

                const SizedBox(height: AppSizes.s24),

                // ── Content ────────────────────────────────────
                reservationsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.s48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error al cargar clientes: $e'),
                  ),
                  data: (reservations) {
                    final clients = _buildClients(reservations);

                    if (clients.isEmpty) {
                      return _EmptyClients(
                        hasSearch: _searchQuery.isNotEmpty,
                        theme: theme,
                        colorScheme: colorScheme,
                      );
                    }

                    // KPI row
                    final uniqueCount = clients.length;
                    final totalVisits = clients.fold(0, (s, c) => s + c.visits);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KPI mini-cards
                        Row(
                          children: [
                            _KpiCard(
                              value: '$uniqueCount',
                              label: 'Clientes únicos',
                              icon: Icons.people_rounded,
                              color: colorScheme.primary,
                              theme: theme,
                            ),
                            const SizedBox(width: AppSizes.s12),
                            _KpiCard(
                              value: '$totalVisits',
                              label: 'Visitas totales',
                              icon: Icons.event_repeat_rounded,
                              color: AppColors.info,
                              theme: theme,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.s24),

                        // Client table/cards
                        _ClientTable(
                          clients: clients,
                          theme: theme,
                          colorScheme: colorScheme,
                          onClientTap: (c) {
                            final business = ref.read(currentBusinessProvider);
                            context.push(
                              '/business-client/${c.clientId}?businessId=${business?.id ?? ''}',
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyClients extends StatelessWidget {
  final bool hasSearch;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _EmptyClients({
    required this.hasSearch,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s40),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSizes.s24),
          Text(
            hasSearch ? 'Sin resultados' : 'Sin clientes aún',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.s8),
          Text(
            hasSearch
                ? 'No hay clientes que coincidan con la búsqueda.'
                : 'Cuando recibas reservas, tus clientes aparecerán aquí.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── KPI card ───────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Client table ───────────────────────────────────────────────────────────────
class _ClientTable extends StatelessWidget {
  final List<_ClientSummary> clients;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final void Function(_ClientSummary) onClientTap;

  const _ClientTable({
    required this.clients,
    required this.theme,
    required this.colorScheme,
    required this.onClientTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s20,
                    vertical: AppSizes.s16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'CLIENTE',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ÚLTIMA VISITA',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'SERVICIOS',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'VISITAS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              ...clients.map(
                (c) => Column(
                  children: [
                    _ClientRow(
                      client: c,
                      isMobile: isMobile,
                      theme: theme,
                      colorScheme: colorScheme,
                      onTap: () => onClientTap(c),
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final _ClientSummary client;
  final bool isMobile;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ClientRow({
    required this.client,
    required this.isMobile,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  String get _initials {
    final parts = client.clientName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return client.clientName.isNotEmpty ? client.clientName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(client.lastVisit);
    final avatar = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    if (isMobile) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s16),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.clientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Text(
                      'Última visita: $dateStr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    if (client.serviceNames.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.s4),
                      Text(
                        client.serviceNames.join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s12,
                  vertical: AppSizes.s4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${client.visits}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s20,
          vertical: AppSizes.s16,
        ),
        child: Row(
          children: [
            // Client column
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  avatar,
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Text(
                      client.clientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Last visit column
            Expanded(
              flex: 2,
              child: Text(
                dateStr,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            // Services column
            Expanded(
              flex: 2,
              child: Text(
                client.serviceNames.isNotEmpty
                    ? client.serviceNames.join(', ')
                    : '—',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Visits count
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s12,
                    vertical: AppSizes.s4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${client.visits}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
