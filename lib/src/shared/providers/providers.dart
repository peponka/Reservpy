import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';
import '../mock_data.dart';
import 'package:reservpy/src/data/repositories/category_repository.dart';
import 'package:reservpy/src/data/repositories/business_repository.dart';
import 'package:reservpy/src/data/repositories/service_repository.dart';
import 'package:reservpy/src/data/repositories/reports_repository.dart';
import 'package:reservpy/src/data/repositories/employee_repository.dart';
import 'package:reservpy/src/data/repositories/reservation_repository.dart';
import 'package:reservpy/src/data/repositories/blocked_slot_repository.dart';
import 'package:reservpy/src/data/repositories/notification_repository.dart';
import 'package:reservpy/src/data/repositories/review_repository.dart';
import 'package:reservpy/src/data/repositories/business_photo_repository.dart';
import 'package:reservpy/src/data/repositories/favorite_repository.dart';
import 'package:reservpy/src/data/repositories/promotion_repository.dart';
import 'package:reservpy/src/shared/models/employee.dart';

// ─── Theme ───────────────────────────────────────────────
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// ─── Auth ────────────────────────────────────────────────
final isLoggedInProvider = StateProvider<bool>((ref) => false);
final currentUserProvider = StateProvider<AppUser?>((ref) => null);
/// The currently active role for navigation/display purposes.
/// This is the role the user chose at login (or last switched to).
final activeRoleProvider = StateProvider<UserRole>((ref) => UserRole.client);

/// Legacy alias — all existing code uses selectedRoleProvider.
/// Points to the same provider as activeRoleProvider.
final selectedRoleProvider = activeRoleProvider;

/// All roles for the current user (fetched from user_roles table).
final userRolesProvider = FutureProvider<List<UserRole>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return user.roles;
});

// ─── Business ────────────────────────────────────────────
final businessesProvider = FutureProvider<List<Business>>((ref) async {
  return BusinessRepository().getAllBusinesses();
});

/// Fetches business for the current user by owner_id (includes inactive)
final ownerBusinessProvider = FutureProvider<Business?>((ref) async {
  // Use Supabase auth directly — must match auth.uid() for RLS
  final authUser = SupabaseConfig.client.auth.currentUser;
  if (authUser == null) return null;
  final businesses = await BusinessRepository().getByOwner(authUser.id);
  return businesses.isNotEmpty ? businesses.first : null;
});

final currentBusinessProvider = Provider<Business?>((ref) {
  // First try from the owner-specific provider (includes inactive businesses)
  final ownerBiz = ref.watch(ownerBusinessProvider).value;
  if (ownerBiz != null) return ownerBiz;
  // Fallback: search in all businesses list
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final allBiz = ref.watch(businessesProvider).value ?? [];
  try {
    return allBiz.firstWhere((b) => b.ownerId == user.id);
  } catch (_) {
    return null;
  }
});

final selectedBusinessProvider = StateProvider<Business?>((ref) => null);

final businessServicesProvider = FutureProvider.family<List<ServiceModel>, String>((ref, businessId) async {
  return ServiceRepository().getByBusiness(businessId);
});

// ─── Categories ──────────────────────────────────────────
final categoriesProvider = FutureProvider<List<BusinessCategory>>((ref) async {
  try {
    return await CategoryRepository().getAll();
  } catch (_) {
    return mockCategories;
  }
});

// ─── Reservations ────────────────────────────────────────

/// Reservations for the current business (async from Supabase).
final businessReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return ReservationRepository().getByBusiness(business.id);
});

/// Reservations for the current client user (async from Supabase).
final clientReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ReservationRepository().getByClient(user.id);
});

// ─── Dashboard ───────────────────────────────────────────
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final reservations = ref.watch(businessReservationsProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final todayReservations =
      reservations.where((r) => r.startTime.isAfter(today) && r.startTime.isBefore(tomorrow));
  final active = todayReservations.where((r) => r.status != ReservationStatus.cancelled);
  final cancelled = todayReservations.where((r) => r.status == ReservationStatus.cancelled);
  final uniqueClients = reservations
      .where((r) => r.status != ReservationStatus.cancelled)
      .map((r) => r.clientId)
      .toSet();

  // Calculate occupancy based on slots
  final business = ref.watch(currentBusinessProvider);
  double occupancy = 0;
  if (business != null) {
    final totalSlots =
        ((business.closingTime.hour * 60 + business.closingTime.minute) -
                (business.openingTime.hour * 60 + business.openingTime.minute)) /
            business.slotDurationMinutes;
    if (totalSlots > 0) {
      occupancy = (active.length / totalSlots * 100).clamp(0, 100);
    }
  }

  return DashboardStats(
    reservationsToday: active.length,
    uniqueClients: uniqueClients.length,
    cancellationsToday: cancelled.length,
    occupancyPercent: occupancy,
  );
});

// ─── Blocked Slots ───────────────────────────────────────
final blockedSlotsProvider = FutureProvider<List<BlockedSlot>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return BlockedSlotRepository().getByBusiness(business.id);
});

/// Blocked slots for a SPECIFIC business (used in client booking flow).
final blockedSlotsForBusinessProvider = FutureProvider.family<List<BlockedSlot>, String>((ref, businessId) async {
  return BlockedSlotRepository().getByBusiness(businessId);
});

// ─── Search ──────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredBusinessesProvider = Provider<List<Business>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final businessesAsync = ref.watch(businessesProvider);
  final businesses = businessesAsync.value ?? [];

  return businesses.where((b) {
    final matchesQuery =
        query.isEmpty || b.name.toLowerCase().contains(query) || (b.address ?? '').toLowerCase().contains(query);
    final matchesCategory = categoryId == null || b.categoryId == categoryId;
    return matchesQuery && matchesCategory && b.isActive;
  }).toList();
});

/// Count of active businesses per category ID.
final businessCountByCategoryProvider = Provider<Map<String, int>>((ref) {
  final businesses = ref.watch(businessesProvider).value ?? [];
  final counts = <String, int>{};
  for (final b in businesses.where((b) => b.isActive)) {
    counts[b.categoryId] = (counts[b.categoryId] ?? 0) + 1;
  }
  return counts;
});

// ─── Navigation state ────────────────────────────────────
final clientNavIndexProvider = StateProvider<int>((ref) => 0);
final businessNavIndexProvider = StateProvider<int>((ref) => 0);

// ─── Services ────────────────────────────────────────────

/// All services for the current business (async from Supabase).
final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return ServiceRepository().getByBusiness(business.id);
});

// ─── Employees ───────────────────────────────────────────

/// All employees for the current business (async from Supabase).
final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return EmployeeRepository().getByBusiness(business.id);
});

// ─── Day-based Filtering ──────────────────────────────────────


/// Currently selected day for calendar/day views.
final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Reservations for the selected day, sorted by start time.
final reservationsForDayProvider = Provider<List<Reservation>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final all = ref.watch(businessReservationsProvider).value ?? [];
  return all.where((r) =>
    r.startTime.year == day.year &&
    r.startTime.month == day.month &&
    r.startTime.day == day.day
  ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
});

// ─── Status Filtering ─────────────────────────────────────────

/// Optional status filter for reservation lists.
final selectedStatusFilterProvider = StateProvider<ReservationStatus?>((ref) => null);

/// Business reservations filtered by status.
final filteredReservationsProvider = Provider<List<Reservation>>((ref) {
  final status = ref.watch(selectedStatusFilterProvider);
  final all = ref.watch(businessReservationsProvider).value ?? [];
  if (status == null) return all;
  return all.where((r) => r.status == status).toList();
});

// ─── Enhanced Dashboard Stats ─────────────────────────────────

/// Computed stats from real reservation data.
final enhancedDashboardStatsProvider = Provider<EnhancedDashboardStats>((ref) {
  final reservations = ref.watch(businessReservationsProvider).value ?? [];
  final services = ref.watch(servicesProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);

  final todayReservations = reservations.where((r) =>
    r.startTime.year == today.year &&
    r.startTime.month == today.month &&
    r.startTime.day == today.day
  ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

  final weekReservations = reservations.where((r) =>
    r.startTime.isAfter(weekStart) && r.startTime.isBefore(weekEnd)
  ).toList();

  final monthReservations = reservations.where((r) =>
    r.startTime.isAfter(monthStart) && r.startTime.isBefore(monthEnd.add(const Duration(days: 1)))
  ).toList();

  // Estimated revenue from completed/confirmed reservations
  double revenue = 0;
  for (final r in reservations.where((r) =>
      r.status == ReservationStatus.completed ||
      r.status == ReservationStatus.confirmed)) {
    final service = services.cast<ServiceModel?>().firstWhere(
      (s) => s?.id == r.serviceId,
      orElse: () => null,
    );
    if (service != null) revenue += service.price ?? 0;
  }

  // Upcoming (future, not cancelled)
  final upcoming = reservations.where((r) =>
    r.startTime.isAfter(now) &&
    r.status != ReservationStatus.cancelled
  ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

  // Status counts
  final pending = reservations.where((r) => r.status == ReservationStatus.pending).length;
  final confirmed = reservations.where((r) => r.status == ReservationStatus.confirmed).length;
  final cancelled = reservations.where((r) => r.status == ReservationStatus.cancelled).length;
  final completed = reservations.where((r) => r.status == ReservationStatus.completed).length;

  // Occupancy: (booked slots today) / (total available slots today)
  final business = ref.watch(currentBusinessProvider);
  double occupancy = 0;
  if (business != null && business.slotDurationMinutes > 0) {
    final totalMinutes = (business.closingTime.hour * 60 + business.closingTime.minute) -
        (business.openingTime.hour * 60 + business.openingTime.minute);
    final totalSlots = totalMinutes ~/ business.slotDurationMinutes;
    if (totalSlots > 0) {
      occupancy = (todayReservations.length / totalSlots * 100).clamp(0, 100);
    }
  }

  // Weekly breakdown: reservations per day (Mon-Sun) for the current week
  final weeklyBreakdown = List.generate(7, (i) {
    final dayStart = weekStart.add(Duration(days: i));
    final dayEnd = dayStart.add(const Duration(days: 1));
    return reservations.where((r) =>
      r.startTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
      r.startTime.isBefore(dayEnd) &&
      r.status != ReservationStatus.cancelled
    ).length;
  });

  // Top services by reservation count
  final serviceCountMap = <String, int>{};
  for (final r in reservations.where((r) => r.status != ReservationStatus.cancelled)) {
    final name = r.serviceName ?? 'Sin servicio';
    serviceCountMap[name] = (serviceCountMap[name] ?? 0) + 1;
  }
  final topServices = serviceCountMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return EnhancedDashboardStats(
    reservationsToday: todayReservations.length,
    reservationsThisWeek: weekReservations.length,
    reservationsThisMonth: monthReservations.length,
    estimatedRevenue: revenue,
    occupancyPercent: occupancy,
    pendingCount: pending,
    confirmedCount: confirmed,
    cancelledCount: cancelled,
    completedCount: completed,
    upcomingReservations: upcoming.take(5).toList(),
    todayReservations: todayReservations,
    weeklyBreakdown: weeklyBreakdown,
    topServices: topServices,
  );
});

// ─── Reports ─────────────────────────────────────────────

/// Reports data fetched from Supabase.
/// Family parameter is periodDays (7, 30, 90).
final reportsDataProvider =
    FutureProvider.family<ReportsData, int>((ref, periodDays) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) {
    return const ReportsData(reservations: [], services: []);
  }
  final now = DateTime.now();
  final from = now.subtract(Duration(days: periodDays));
  return ReportsRepository().getReportsData(
    businessId: business.id,
    from: from,
    to: now,
  );
});

// ─── Notifications ─────────────────────────────────────

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null) return [];
  return NotificationRepository().fetchForUser(userId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

// ─── Reviews ─────────────────────────────────────────────

final businessReviewsProvider = FutureProvider.family<List<Review>, String>((ref, businessId) async {
  return ReviewRepository().fetchForBusiness(businessId);
});

final businessAverageRatingProvider = Provider.family<double, String>((ref, businessId) {
  final reviews = ref.watch(businessReviewsProvider(businessId)).value ?? [];
  if (reviews.isEmpty) return 0.0;
  final sum = reviews.fold<int>(0, (s, r) => s + r.rating);
  return sum / reviews.length;
});

// ─── Business Photos ──────────────────────────────────────

final businessPhotosProvider = FutureProvider.family<List<BusinessPhoto>, String>((ref, businessId) async {
  return BusinessPhotoRepository().fetchPhotos(businessId);
});

// ─── Favorites ─────────────────────────────────────────────

final clientFavoritesProvider = FutureProvider<List<String>>((ref) async {
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null) return [];
  return FavoriteRepository().fetchFavoriteIds(userId);
});

// ─── Promotions ────────────────────────────────────────────

final businessPromotionsProvider = FutureProvider.family<List<Promotion>, String>((ref, businessId) async {
  return PromotionRepository().fetchForBusiness(businessId);
});

final activePromotionsProvider = FutureProvider.family<List<Promotion>, String>((ref, businessId) async {
  return PromotionRepository().fetchActiveForBusiness(businessId);
});
