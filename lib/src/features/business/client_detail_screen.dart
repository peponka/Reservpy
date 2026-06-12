import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

/// Detail screen showing a client's profile, stats, and reservation history
/// from the business owner's perspective.
///
/// Receives [clientId] and [businessId] to filter the relevant data.
class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String businessId;

  const ClientDetailScreen({
    super.key,
    required this.clientId,
    required this.businessId,
  });

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  final _notesController = TextEditingController();
  bool _notesSaved = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allReservations = ref.watch(businessReservationsProvider).valueOrNull ?? [];

    // ─── Filter reservations for this client at this business ────
    final clientReservations = allReservations
        .where(
          (r) => r.clientId == widget.clientId && r.businessId == widget.businessId,
        )
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    // ─── Extract client info from reservations ──────────────────
    final clientName = clientReservations.isNotEmpty
        ? clientReservations.first.clientName ?? 'Cliente'
        : 'Cliente';
    final initials = _extractInitials(clientName);

    // ─── Compute stats ──────────────────────────────────────────
    final completedAndConfirmed = clientReservations.where(
      (r) =>
          r.status == ReservationStatus.completed ||
          r.status == ReservationStatus.confirmed,
    );
    final totalVisits = completedAndConfirmed.length;

    final services = ref.watch(businessServicesProvider(widget.businessId)).valueOrNull ?? [];
    final totalSpent = _calculateTotalSpent(completedAndConfirmed, services);

    final lastVisitDate = clientReservations.isNotEmpty
        ? clientReservations.first.startTime
        : null;

    // ─── Member since (oldest reservation createdAt) ────────────
    final memberSince = clientReservations.isNotEmpty
        ? clientReservations
            .map((r) => r.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : null;

    // ─── Contact info REAL desde profiles (RLS expone solo lo necesario) ─
    // Si el cliente no tiene perfil cargado o la RLS no permite leerlo,
    // mostramos placeholders en lugar de inventar datos.
    final clientProfile =
        ref.watch(profileByIdProvider(widget.clientId)).value;
    final clientPhone =
        (clientProfile?.phone != null && clientProfile!.phone!.trim().isNotEmpty)
            ? clientProfile.phone!
            : 'Sin teléfono';
    final clientEmail =
        clientProfile?.email != null && clientProfile!.email.trim().isNotEmpty
            ? clientProfile.email
            : 'Sin email';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: _CircleBackButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSizes.s8),
                child: _CircleIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: () => _showOptionsSheet(context),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ClientHeroGradient(
                clientName: clientName,
                initials: initials,
                memberSince: memberSince,
                phone: clientPhone,
                email: clientEmail,
                onPhoneTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Llamando a $clientPhone...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onEmailTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Enviando email a $clientEmail...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Body Content ────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.s24),

                      // ─── KPI Stats Row ──────────────────────
                      _StatsRow(
                        totalVisits: totalVisits,
                        totalSpent: totalSpent,
                        lastVisitDate: lastVisitDate,
                      ),

                      const SizedBox(height: AppSizes.s24),

                      // ─── Reservation History ────────────────
                      SectionHeader(
                        title: 'Historial de turnos',
                        actionLabel: '${clientReservations.length} turnos',
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),

                      const SizedBox(height: AppSizes.s8),

                      if (clientReservations.isEmpty)
                        _EmptyHistoryPlaceholder()
                      else
                        ...List.generate(
                          clientReservations.length,
                          (index) => _ReservationHistoryCard(
                            reservation: clientReservations[index],
                            services: services,
                            delay: 450 + index * 80,
                          ),
                        ),

                      const SizedBox(height: AppSizes.s32),

                      // ─── Notes Section ──────────────────────
                      _NotesSection(
                        controller: _notesController,
                        saved: _notesSaved,
                        onSave: () {
                          setState(() => _notesSaved = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nota guardada correctamente'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _notesSaved = false);
                          });
                        },
                      )
                          .animate()
                          .fadeIn(delay: 650.ms, duration: 400.ms)
                          .slideY(
                              begin: 0.1,
                              end: 0,
                              delay: 650.ms,
                              duration: 400.ms),

                      const SizedBox(height: AppSizes.s32),

                      // ─── Quick Actions ──────────────────────
                      _QuickActions(
                        clientName: clientName,
                        onCreateReservation: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Crear turno para $clientName — próximamente',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onShare: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Compartir perfil de $clientName — próximamente',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      )
                          .animate()
                          .fadeIn(delay: 750.ms, duration: 400.ms)
                          .slideY(
                              begin: 0.1,
                              end: 0,
                              delay: 750.ms,
                              duration: 400.ms),

                      const SizedBox(height: AppSizes.s48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet with additional options.
  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.s16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _BottomSheetOption(
                  icon: Icons.calendar_today_rounded,
                  label: 'Crear turno para este cliente',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Crear turno — próximamente'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _BottomSheetOption(
                  icon: Icons.share_rounded,
                  label: 'Compartir perfil',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compartir — próximamente'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _BottomSheetOption(
                  icon: Icons.block_rounded,
                  label: 'Bloquear cliente',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bloquear cliente — próximamente'),
                        behavior: SnackBarBehavior.floating,
                      ),
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

  /// Extracts initials from a full name.
  String _extractInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  /// Sums the price of all completed/confirmed reservations.
  double _calculateTotalSpent(
    Iterable<Reservation> reservations,
    List<ServiceModel> services,
  ) {
    double total = 0;
    for (final r in reservations) {
      final svc = services.cast<ServiceModel?>().firstWhere(
            (s) => s?.id == r.serviceId,
            orElse: () => null,
          );
      if (svc != null && svc.price != null) {
        total += svc.price!;
      }
    }
    return total;
  }
}

// ═══════════════════════════════════════════════════════════════════
// ─── PRIVATE WIDGETS ───────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════

// ─── Hero Gradient with Avatar ─────────────────────────────────────
class _ClientHeroGradient extends StatelessWidget {
  final String clientName;
  final String initials;
  final DateTime? memberSince;
  final String phone;
  final String email;
  final VoidCallback onPhoneTap;
  final VoidCallback onEmailTap;

  const _ClientHeroGradient({
    required this.clientName,
    required this.initials,
    required this.memberSince,
    required this.phone,
    required this.email,
    required this.onPhoneTap,
    required this.onEmailTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat("MMMM yyyy", 'es');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.s40),

                // ─── Avatar ───────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    initials: initials,
                    size: 80,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                    ),

                const SizedBox(height: AppSizes.s12),

                // ─── Name ─────────────────────────────────
                Text(
                  clientName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s6),

                // ─── Member since ─────────────────────────
                if (memberSince != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s12,
                      vertical: AppSizes.s4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: AppSizes.s4),
                        Text(
                          'Cliente desde ${dateFormat.format(memberSince!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s12),

                // ─── Contact Row ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ContactChip(
                      icon: Icons.phone_rounded,
                      label: phone,
                      onTap: onPhoneTap,
                    ),
                    const SizedBox(width: AppSizes.s8),
                    _ContactChip(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      onTap: onEmailTap,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Contact Chip ──────────────────────────────────────────────────
class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        splashColor: Colors.white.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s12,
            vertical: AppSizes.s6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: AppSizes.s6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int totalVisits;
  final double totalSpent;
  final DateTime? lastVisitDate;

  const _StatsRow({
    required this.totalVisits,
    required this.totalSpent,
    required this.lastVisitDate,
  });

  String _formatPrice(double price) {
    if (price <= 0) return '0 Gs.';
    final formatted = NumberFormat('#,###', 'es').format(price.toInt());
    return '$formatted Gs.';
  }

  String _formatLastVisit(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            title: 'Visitas totales',
            value: totalVisits.toString(),
            icon: Icons.event_available_rounded,
            color: AppColors.statusConfirmed,
            delay: 150,
          ),
        ),
        const SizedBox(width: AppSizes.s8),
        Expanded(
          child: KpiCard(
            title: 'Total gastado',
            value: _formatPrice(totalSpent),
            icon: Icons.payments_rounded,
            color: AppColors.primary,
            delay: 250,
          ),
        ),
        const SizedBox(width: AppSizes.s8),
        Expanded(
          child: KpiCard(
            title: 'Última visita',
            value: _formatLastVisit(lastVisitDate),
            icon: Icons.schedule_rounded,
            color: AppColors.info,
            delay: 350,
          ),
        ),
      ],
    );
  }
}

// ─── Reservation History Card ──────────────────────────────────────
class _ReservationHistoryCard extends StatelessWidget {
  final Reservation reservation;
  final List<ServiceModel> services;
  final int delay;

  const _ReservationHistoryCard({
    required this.reservation,
    required this.services,
    this.delay = 0,
  });

  Color _statusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppColors.statusConfirmed;
      case ReservationStatus.pending:
        return AppColors.statusPending;
      case ReservationStatus.cancelled:
        return AppColors.statusCancelled;
      case ReservationStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  String _statusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.cancelled:
        return 'Cancelada';
      case ReservationStatus.completed:
        return 'Finalizada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(reservation.status);

    // Resolve service name & price
    final svc = services.cast<ServiceModel?>().firstWhere(
          (s) => s?.id == reservation.serviceId,
          orElse: () => null,
        );
    final serviceName = reservation.serviceName ?? svc?.name ?? 'Servicio';
    final priceStr = svc?.formattedPrice ?? '';

    final dateStr = DateFormat('EEE dd/MM/yyyy', 'es').format(reservation.startTime);
    final timeStr =
        '${DateFormat.Hm().format(reservation.startTime)} – ${DateFormat.Hm().format(reservation.endTime)}';

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Status indicator bar ────────────────────
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSizes.s12),

          // ─── Content ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name + status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s8),
                    StatusBadge(
                      label: _statusLabel(reservation.status),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s8),

                // Date & time row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSizes.s4),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSizes.s4),
                    Text(
                      timeStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

                // Price row
                if (priceStr.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s6),
                  Row(
                    children: [
                      Icon(
                        Icons.sell_outlined,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSizes.s4),
                      Text(
                        priceStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                // Cancellation reason
                if (reservation.status == ReservationStatus.cancelled &&
                    reservation.cancellationReason != null) ...[
                  const SizedBox(height: AppSizes.s6),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.s8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.error.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: AppSizes.s6),
                        Expanded(
                          child: Text(
                            reservation.cancellationReason!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        );
  }
}

// ─── Empty History Placeholder ─────────────────────────────────────
class _EmptyHistoryPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.history_rounded,
      title: 'Sin historial',
      subtitle: 'Este cliente aún no tiene turnos registrados en tu negocio.',
    );
  }
}

// ─── Notes Section ─────────────────────────────────────────────────
class _NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final bool saved;
  final VoidCallback onSave;

  const _NotesSection({
    required this.controller,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Section header ───────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.s8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                size: 20,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notas privadas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Solo vos podés ver estas notas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (saved)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s8,
                  vertical: AppSizes.s4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    SizedBox(width: AppSizes.s4),
                    Text(
                      'Guardado',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSizes.s12),

        // ─── Text field ───────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(AppSizes.s4),
          child: Column(
            children: [
              AppTextField(
                controller: controller,
                hint: 'Agregá notas sobre este cliente...',
                prefixIcon: Icons.edit_note_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: AppSizes.s8),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Guardar nota',
                  icon: Icons.save_rounded,
                  width: 160,
                  height: AppSizes.buttonSm,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Quick Actions ─────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final String clientName;
  final VoidCallback onCreateReservation;
  final VoidCallback onShare;

  const _QuickActions({
    required this.clientName,
    required this.onCreateReservation,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Acciones rápidas'),
        const SizedBox(height: AppSizes.s8),

        // ─── Create reservation button ────────────────
        AppCard(
          onTap: onCreateReservation,
          padding: const EdgeInsets.all(AppSizes.s16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear turno para este cliente',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Text(
                      'Agendá un nuevo turno para $clientName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),

        // ─── Share button ─────────────────────────────
        AppCard(
          onTap: onShare,
          padding: const EdgeInsets.all(AppSizes.s16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  size: 24,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartir perfil',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s2),
                    Text(
                      'Enviá el resumen de este cliente',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Sheet Option ───────────────────────────────────────────
class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(color: effectiveColor),
      ),
      onTap: onTap,
    );
  }
}

// ─── Circle Back Button ────────────────────────────────────────────
class _CircleBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CircleBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.s8),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

// ─── Circle Icon Button ────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
