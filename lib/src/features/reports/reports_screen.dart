import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reservationsAsync = ref.watch(businessReservationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Reportes',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            'Generá reportes mensuales de tu negocio',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.s24),

          // Month selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar mes',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      }),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy', 'es').format(_selectedMonth),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s24),

          // Stats preview
          reservationsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (allReservations) {
              final monthReservations = allReservations.where((r) {
                return r.startTime.year == _selectedMonth.year &&
                    r.startTime.month == _selectedMonth.month;
              }).toList();

              final confirmed = monthReservations
                  .where((r) => r.status == ReservationStatus.confirmed)
                  .length;
              final completed = monthReservations
                  .where((r) => r.status == ReservationStatus.completed)
                  .length;
              final cancelled = monthReservations
                  .where((r) => r.status == ReservationStatus.cancelled)
                  .length;
              final pending = monthReservations
                  .where((r) => r.status == ReservationStatus.pending)
                  .length;

              // Service breakdown
              final serviceCount = <String, int>{};
              for (final r in monthReservations
                  .where((r) => r.status != ReservationStatus.cancelled)) {
                final name = r.serviceName ?? 'Sin servicio';
                serviceCount[name] = (serviceCount[name] ?? 0) + 1;
              }
              final sortedServices = serviceCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                children: [
                  // Summary cards
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                    children: [
                      _StatCard(
                        label: 'Total',
                        value: '${monthReservations.length}',
                        icon: Icons.calendar_month_rounded,
                        color: AppColors.primary,
                      ),
                      _StatCard(
                        label: 'Confirmadas',
                        value: '${confirmed + completed}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      _StatCard(
                        label: 'Pendientes',
                        value: '$pending',
                        icon: Icons.schedule_rounded,
                        color: Colors.amber.shade700,
                      ),
                      _StatCard(
                        label: 'Canceladas',
                        value: '$cancelled',
                        icon: Icons.cancel_rounded,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s24),

                  // Service breakdown
                  if (sortedServices.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Servicios mas solicitados',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...sortedServices.take(5).map((entry) {
                            final maxCount = sortedServices.first.value;
                            final pct = maxCount > 0 ? entry.value / maxCount : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key,
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      Text('${entry.value} turnos',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      valueColor: const AlwaysStoppedAnimation(
                                          AppColors.primary),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSizes.s24),

                  // Generate PDF button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating
                          ? null
                          : () => _generatePdf(
                                monthReservations,
                                sortedServices,
                              ),
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: Text(
                        _isGenerating ? 'Generando...' : 'Generar PDF',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(
    List<Reservation> reservations,
    List<MapEntry<String, int>> serviceBreakdown,
  ) async {
    setState(() => _isGenerating = true);

    try {
      final business = ref.read(currentBusinessProvider).value;
      final monthName = DateFormat('MMMM yyyy', 'es').format(_selectedMonth);
      final bName = business?.name ?? 'Mi Negocio';

      final pdf = pw.Document();

      final confirmed = reservations
          .where((r) =>
              r.status == ReservationStatus.confirmed ||
              r.status == ReservationStatus.completed)
          .length;
      final cancelled = reservations
          .where((r) => r.status == ReservationStatus.cancelled)
          .length;
      final pending = reservations
          .where((r) => r.status == ReservationStatus.pending)
          .length;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Title
            pw.Center(
              child: pw.Text(
                'Reporte Mensual',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                '$bName - $monthName',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),

            // Summary
            pw.Text('Resumen',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStatBox('Total', '${reservations.length}'),
                _pdfStatBox('Confirmadas', '$confirmed'),
                _pdfStatBox('Pendientes', '$pending'),
                _pdfStatBox('Canceladas', '$cancelled'),
              ],
            ),
            pw.SizedBox(height: 24),

            // Services
            if (serviceBreakdown.isNotEmpty) ...[
              pw.Text('Servicios',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                cellPadding: const pw.EdgeInsets.all(8),
                data: [
                  ['Servicio', 'Cantidad'],
                  ...serviceBreakdown.map((e) => [e.key, '${e.value}']),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            // Reservations list
            pw.Text('Detalle de Reservas',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(6),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(1.5),
              },
              data: [
                ['Fecha', 'Hora', 'Cliente', 'Estado'],
                ...reservations.map((r) => [
                      DateFormat('dd/MM/yy').format(r.startTime),
                      '${DateFormat('HH:mm').format(r.startTime)} - ${DateFormat('HH:mm').format(r.endTime)}',
                      r.clientName ?? 'N/A',
                      _statusLabel(r.status),
                    ]),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'Reporte_${bName}_$monthName.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) setState(() => _isGenerating = false);
  }

  String _statusLabel(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.completed:
        return 'Completada';
      case ReservationStatus.cancelled:
        return 'Cancelada';
    }
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
