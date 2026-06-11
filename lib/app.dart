import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/constants/app_theme.dart';
import 'src/core/router/app_router.dart';
import 'src/shared/models/models.dart';
import 'src/shared/providers/providers.dart';
import 'src/data/repositories/profile_repository.dart';
import 'src/data/repositories/user_role_repository.dart';

/// Root application widget.
class ReservPyApp extends ConsumerStatefulWidget {
  const ReservPyApp({super.key});

  @override
  ConsumerState<ReservPyApp> createState() => _ReservPyAppState();
}

class _ReservPyAppState extends ConsumerState<ReservPyApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes (handles OAuth redirect return)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;

        if ((event == AuthChangeEvent.signedIn ||
                event == AuthChangeEvent.tokenRefreshed) &&
            session != null) {
          await _restoreSession(session);
        }
      },
    );

    // Also check for an existing session on cold start
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    // Detect an OAuth callback: Google redirected back with ?code=xxx in the URL
    final hasOAuthCode = kIsWeb &&
        (Uri.base.queryParameters['code']?.isNotEmpty ?? false);

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Supabase.initialize() may have already exchanged the code for us
      await _restoreSession(session);
      if (hasOAuthCode) _redirectAfterOAuth();
      return;
    }

    // Web PKCE: exchange the code explicitly if initialize() didn't
    if (hasOAuthCode) {
      final code = Uri.base.queryParameters['code']!;
      bool sessionRestored = false;
      try {
        final response = await Supabase.instance.client.auth
            .exchangeCodeForSession(code);
        if (response.session != null) {
          await _restoreSession(response.session!);
          sessionRestored = true;
        }
      } catch (_) {
        // Exchange may have raced with initialize() — check again
        await Future.delayed(const Duration(milliseconds: 300));
        final retrySession = Supabase.instance.client.auth.currentSession;
        if (retrySession != null) {
          if (!ref.read(isLoggedInProvider)) {
            await _restoreSession(retrySession);
          }
          sessionRestored = true;
        }
      }
      if (sessionRestored) _redirectAfterOAuth();
    }
  }

  /// After a Google OAuth login, take the user to their dashboard
  /// instead of leaving them on the landing page.
  void _redirectAfterOAuth() {
    if (!mounted || !ref.read(isLoggedInProvider)) return;
    final router = ref.read(routerProvider);
    final user = ref.read(currentUserProvider);
    final activeRole = ref.read(activeRoleProvider);

    if (user != null && user.isMultiRole) {
      router.go('/select-role');
    } else if (activeRole == UserRole.businessOwner ||
        activeRole == UserRole.business) {
      router.go('/business');
    } else {
      router.go('/client');
    }
  }

  Future<void> _restoreSession(Session session) async {
    // Avoid re-processing if already logged in
    if (ref.read(isLoggedInProvider)) return;

    final userId = session.user.id;
    final profileRepo = ProfileRepository();
    final roleRepo = UserRoleRepository();
    final profile = await profileRepo.getProfile(userId);

    // Fetch roles from user_roles table
    var roles = await roleRepo.getRoles(userId);
    // TODO: remove debug log after diagnosing missing client card
    // ignore: avoid_print
    print('RestoreSession: fetched roles=$roles profile=${profile?.email}');

    if (profile != null) {
      // If no roles found in user_roles, fallback to profile.role
      if (roles.isEmpty) {
        final normalizedRole = (profile.role == UserRole.business)
            ? UserRole.businessOwner
            : profile.role;
        roles = [normalizedRole];
        // Sync to user_roles table
        await roleRepo.addRole(userId, normalizedRole);
        if (normalizedRole == UserRole.businessOwner) {
          roles.add(UserRole.client);
          await roleRepo.addRole(userId, UserRole.client);
        }
      }

      final userWithRoles = profile.copyWith(roles: roles);
      ref.read(currentUserProvider.notifier).state = userWithRoles;

      // Set active role — admin is NEVER auto-selected (admin panel is only
      // entered via /admin-login); prefer business owner, then any other role.
      final activeRole = roles.contains(UserRole.businessOwner)
          ? UserRole.businessOwner
          : roles.firstWhere((r) => r != UserRole.admin,
              orElse: () => roles.first);
      ref.read(activeRoleProvider.notifier).state = activeRole;

      // Refresh business data if applicable
      if (userWithRoles.canBeBusiness) {
        ref.invalidate(businessesProvider);
      }

      ref.read(isLoggedInProvider.notifier).state = true;
    } else {
      // No profile yet — create a minimal one from auth metadata
      final user = session.user;
      final role = UserRole.fromDbString(user.userMetadata?['role'] as String?);

      if (roles.isEmpty) {
        roles = [role];
      }

      ref.read(currentUserProvider.notifier).state = AppUser(
        id: user.id,
        firstName: user.userMetadata?['first_name'] ??
            user.userMetadata?['full_name']?.toString().split(' ').first ??
            '',
        lastName: user.userMetadata?['last_name'] ??
            (() {
              final fullName = user.userMetadata?['full_name']?.toString() ?? '';
              final parts = fullName.split(' ');
              return parts.length > 1 ? parts.skip(1).join(' ') : '';
            })(),
        email: user.email ?? '',
        role: role,
        roles: roles,
        createdAt: DateTime.now(),
      );
      ref.read(activeRoleProvider.notifier).state = role;
      ref.read(isLoggedInProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ReservPy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
