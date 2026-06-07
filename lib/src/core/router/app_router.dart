import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/role_selector_screen.dart';
import '../../features/business/create_business_screen.dart';
import '../../features/business/business_profile_screen.dart';
import '../../features/business/edit_business_screen.dart';
import '../../features/business/employees_screen.dart';
import '../../features/business/client_detail_screen.dart';
import '../../features/business/reminders_settings_screen.dart';
import '../../features/business/onboarding_screen.dart';
import '../../features/business/clients_screen.dart';
import '../../features/business/services_screen.dart';
import '../../features/business/availability_screen.dart';
import '../../features/dashboard/reports_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/auth/business_created_screen.dart';
import '../../features/landing/landing_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../features/reservations/select_service_screen.dart';
import '../../features/reservations/select_time_screen.dart';
import '../../features/reservations/confirm_reservation_screen.dart';
import '../../features/reservations/reservation_success_screen.dart';
import '../../features/reservations/business_detail_screen.dart';
import '../../features/shell/client_shell.dart';
import '../../features/shell/business_shell.dart';
import '../../features/subscription/upgrade_screen.dart';
import '../../features/subscription/bancard_payment_screen.dart';
import '../../shared/providers/providers.dart';
import '../../shared/models/models.dart';

/// A [Listenable] that notifies GoRouter when any of the watched streams emit a value.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(List<Stream<dynamic>> streams) {
    for (final stream in streams) {
      final sub = stream.asBroadcastStream().listen((_) => notifyListeners());
      _subscriptions.add(sub);
    }
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// GoRouter configuration with auth guards and role-based routing.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream([
    ref.watch(isLoggedInProvider.notifier).stream,
    ref.watch(currentUserProvider.notifier).stream,
  ]);

  ref.onDispose(() {
    refreshListenable.dispose();
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final user = ref.read(currentUserProvider);
      final activeRole = ref.read(activeRoleProvider);

      final isPublicPage = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/select-role';

      // Not logged in → allow public pages, redirect others to landing
      if (!isLoggedIn && !isPublicPage) return '/';

      // Logged in but on auth/landing page → redirect to home
      if (isLoggedIn && (state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password')) {
        // If multi-role and hasn't selected yet, go to selector
        if (user != null && user.isMultiRole && state.matchedLocation != '/select-role') {
          return '/select-role';
        }
        if (activeRole == UserRole.businessOwner || activeRole == UserRole.business) {
          return '/business';
        }
        return '/client';
      }

      // ── Role-based route guard ──
      // Business owners and employees CAN access /client
      // Only block pure clients from /business management dashboard
      if (isLoggedIn && user != null) {
        if (!user.canBeBusiness && state.matchedLocation == '/business') {
          return '/client';
        }
      }

      return null;
    },
    routes: [
      // ─── Entrada raíz ─────────────────────────────────
      //   Web   → landing comercial (hero, features, pricing, etc.)
      //   Mobile → pantalla de bienvenida simple
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPage(
          state,
          kIsWeb ? const LandingPage() : const WelcomeScreen(),
        ),
      ),

      // ─── Auth Routes ─────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildPage(
          state,
          const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _buildPage(
          state,
          const ForgotPasswordScreen(),
        ),
      ),

      // ─── Role Selector ─────────────────────────────────
      GoRoute(
        path: '/select-role',
        pageBuilder: (context, state) => _buildPage(
          state,
          const RoleSelectorScreen(),
        ),
      ),

      // ─── Negocio Creado (éxito tras registro) ─────────
      GoRoute(
        path: '/business-created',
        pageBuilder: (context, state) {
          final name = state.uri.queryParameters['name'] ?? '';
          return _buildPage(
            state,
            BusinessCreatedScreen(businessName: name),
          );
        },
      ),

      // ─── Business Onboarding ──────────────────────────
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPage(
          state,
          const OnboardingScreen(),
        ),
      ),

      // ─── Client Shell ────────────────────────────────
      GoRoute(
        path: '/client',
        pageBuilder: (context, state) => _buildPage(
          state,
          const ClientShell(),
        ),
      ),

      // ─── Business Shell ──────────────────────────────
      GoRoute(
        path: '/business',
        pageBuilder: (context, state) => _buildPage(
          state,
          const BusinessShell(),
        ),
      ),

      // ─── Create Business ─────────────────────────────
      GoRoute(
        path: '/create-business',
        pageBuilder: (context, state) => _buildPage(
          state,
          const CreateBusinessScreen(),
        ),
      ),

      // ─── Business Profile ────────────────────────────
      GoRoute(
        path: '/business/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPage(
            state,
            BusinessProfileScreen(businessId: id),
          );
        },
      ),

      // ─── Edit Business ────────────────────────────────
      GoRoute(
        path: '/business-edit',
        pageBuilder: (context, state) => _buildPage(
          state,
          const EditBusinessScreen(),
        ),
      ),

      // ─── Employees Management ─────────────────────────
      GoRoute(
        path: '/business-employees',
        pageBuilder: (context, state) => _buildPage(
          state,
          const EmployeesScreen(),
        ),
      ),

      // ─── Reports & Analytics ──────────────────────────
      GoRoute(
        path: '/business-reports',
        pageBuilder: (context, state) => _buildPage(
          state,
          const ReportsScreen(),
        ),
      ),

      // ─── Client Detail ────────────────────────────────
      GoRoute(
        path: '/business-client/:clientId',
        pageBuilder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final businessId = state.uri.queryParameters['businessId'] ?? '';
          return _buildPage(
            state,
            ClientDetailScreen(clientId: clientId, businessId: businessId),
          );
        },
      ),

      // ─── Reminders Settings ───────────────────────────
      GoRoute(
        path: '/business-reminders',
        pageBuilder: (context, state) => _buildPage(
          state,
          const RemindersSettingsScreen(),
        ),
      ),

      // ─── Business Clients ──────────────────────────────
      GoRoute(
        path: '/business-clients',
        pageBuilder: (context, state) => _buildPage(
          state,
          const ClientsScreen(),
        ),
      ),

      // ─── Business Services Manage ──────────────────────
      GoRoute(
        path: '/business-services-manage',
        pageBuilder: (context, state) => _buildPage(
          state,
          const ServicesScreen(),
        ),
      ),

      // ─── Business Availability ─────────────────────────
      GoRoute(
        path: '/business-availability',
        pageBuilder: (context, state) => _buildPage(
          state,
          const AvailabilityScreen(),
        ),
      ),

      // ─── Business Detail (client view) ──────────────
      GoRoute(
        path: '/business-detail/:businessId',
        pageBuilder: (context, state) {
          final businessId = state.pathParameters['businessId']!;
          return _buildPage(
            state,
            BusinessDetailScreen(businessId: businessId),
          );
        },
      ),

      // ─── Reservation Flow ────────────────────────────
      GoRoute(
        path: '/reserve/:businessId/service',
        pageBuilder: (context, state) {
          final businessId = state.pathParameters['businessId']!;
          return _buildPage(
            state,
            SelectServiceScreen(businessId: businessId),
          );
        },
      ),
      GoRoute(
        path: '/reserve/:businessId/time/:serviceId',
        pageBuilder: (context, state) {
          final businessId = state.pathParameters['businessId']!;
          final serviceId = state.pathParameters['serviceId']!;
          return _buildPage(
            state,
            SelectTimeScreen(businessId: businessId, serviceId: serviceId),
          );
        },
      ),
      GoRoute(
        path: '/reserve/:businessId/confirm/:serviceId/:timestamp',
        pageBuilder: (context, state) {
          final businessId = state.pathParameters['businessId']!;
          final serviceId = state.pathParameters['serviceId']!;
          final timestamp = state.pathParameters['timestamp']!;
          return _buildPage(
            state,
            ConfirmReservationScreen(
              businessId: businessId,
              serviceId: serviceId,
              selectedTime: DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)),
            ),
          );
        },
      ),
      GoRoute(
        path: '/reservation-success',
        pageBuilder: (context, state) {
          // Parse query parameters from confirm screen navigation
          final businessName = state.uri.queryParameters['businessName'] ?? 'Negocio';
          final serviceName = state.uri.queryParameters['serviceName'] ?? 'Servicio';
          final dateStr = state.uri.queryParameters['date'];
          final endDateStr = state.uri.queryParameters['endDate'];
          
          final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
          final endDate = endDateStr != null ? DateTime.parse(endDateStr) : date.add(const Duration(minutes: 30));
          
          return _buildPage(
            state,
            ReservationSuccessScreen(
              businessName: businessName,
              serviceName: serviceName,
              date: date,
              endDate: endDate,
            ),
          );
        },
      ),

      // ─── Subscription / Upgrade ───────────────────────────
      GoRoute(
        path: '/upgrade',
        pageBuilder: (context, state) => _buildPage(
          state,
          const UpgradeScreen(),
        ),
      ),
      GoRoute(
        path: '/upgrade/payment',
        pageBuilder: (context, state) => _buildPage(
          state,
          const BancardPaymentScreen(),
        ),
      ),
      GoRoute(
        path: '/upgrade/success',
        pageBuilder: (context, state) => _buildPage(
          state,
          const PaymentSuccessScreen(),
        ),
      ),
    ],
  );
});

/// Animated page transitions.
CustomTransitionPage _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
