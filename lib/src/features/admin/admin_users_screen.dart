import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/data/repositories/admin_repository.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _adminUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  return AdminRepository().getAllUsers();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_adminUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Row(
              children: [
                Text('Usuarios',
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => ref.invalidate(_adminUsersProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primary,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Search ────────────────────────────────────
            TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                hintStyle: GoogleFonts.inter(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── List ──────────────────────────────────────
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (users) {
                  final filtered = users.where((u) {
                    if (_search.isEmpty) return true;
                    return u.fullName.toLowerCase().contains(_search) ||
                        u.email.toLowerCase().contains(_search);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${filtered.length} usuarios',
                        style: GoogleFonts.inter(fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: theme.dividerColor.withValues(alpha: 0.2),
                              ),
                              itemBuilder: (_, i) => _UserTile(user: filtered[i]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(user.initials,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Sin nombre' : user.fullName,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.inter(fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (user.phone != null)
            Text(
              user.phone!,
              style: GoogleFonts.inter(fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          const SizedBox(width: 12),
          Text(
            DateFormat('dd/MM/yy').format(user.createdAt),
            style: GoogleFonts.inter(fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
