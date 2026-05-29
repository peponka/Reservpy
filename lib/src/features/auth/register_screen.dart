
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';

import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_strings.dart';
import 'package:reservpy/src/core/utils/validators.dart';
import 'package:reservpy/src/data/repositories/auth_repository.dart';
import 'package:reservpy/src/data/repositories/profile_repository.dart';
import 'package:reservpy/src/data/repositories/user_role_repository.dart';
import 'package:reservpy/src/data/services/email_service.dart';


// ═══════════════════════════════════════════════════════════════════════════
// REGISTER SCREEN — Multi-step premium SaaS registration flow
// ═══════════════════════════════════════════════════════════════════════════

/// Multi-step registration screen with:
///   Step 1 → Role selection (business vs client)
///   Step 2 → Registration form (split-screen for business)
///   Step 3 → Email verification (simulated OTP + success)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  // ─── Page / Step ───────────────────────────────────────────
  final _pageController = PageController();
  int _currentStep = 0;

  // ─── Role ─────────────────────────────────────────────────
  UserRole? _selectedRole;

  // ─── Form ─────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _selectedCategoryId;

  // ─── Repositories ────────────────────────────────────────
  final _authRepo = AuthRepository();
  final _profileRepo = ProfileRepository();
  final _roleRepo = UserRoleRepository();


  // ─── OTP / Verification ───────────────────────────────────
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerified = false;
  bool _isVerifying = false;

  // ─── Animation ────────────────────────────────────────────
  late AnimationController _checkAnimController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _checkAnimController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  // NAVIGATION HELPERS
  // ═════════════════════════════════════════════════════════════

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentStep = step);
  }

  void _selectRole(UserRole role) {
    setState(() => _selectedRole = role);
    _goToStep(1);
  }

  void _goBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  // ═════════════════════════════════════════════════════════════
  // FORM SUBMISSION
  // ═════════════════════════════════════════════════════════════

  Future<void> _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final role = _selectedRole ?? UserRole.client;
      // Normalize: business -> business_owner for DB
      final dbRole = (role == UserRole.business) ? UserRole.businessOwner : role;

      final response = await _authRepo.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: dbRole.dbValue,
      );

      if (!mounted) return;

      if (response.user != null) {
        // Update profile with correct role and data
        try {
          await _profileRepo.updateProfile(AppUser(
            id: response.user!.id,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            role: role,
            createdAt: DateTime.now(),
          ));
        } catch (_) {
          // Profile update is non-fatal — trigger already created it
        }

        // Insert role(s) into user_roles table
        try {
          await _roleRepo.addRole(response.user!.id, dbRole);
          if (dbRole == UserRole.businessOwner) {
            await _roleRepo.addRole(response.user!.id, UserRole.client);
          }
        } catch (_) {
          // Role insert is non-fatal on registration
        }

        // NOTE: Business creation is NOT done here.
        // The onboarding flow (OnboardingScreen) handles creating the
        // business + services + schedule after the user's first login.

        // ── Send welcome email (fire-and-forget) ──
        final userEmail = _emailController.text.trim();
        final userFirstName = _firstNameController.text.trim();
        if (role == UserRole.business) {
          EmailService.enviarEmailBienvenida(
            email: userEmail,
            firstName: userFirstName,
            role: 'business',
          );
        } else {
          EmailService.enviarEmailAltaCliente(
            email: userEmail,
            firstName: userFirstName,
          );
        }

        // Sign out after registration — user must log in
        await _authRepo.signOut();

        if (!mounted) return;

        GoRouter.of(context).go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Cuenta creada con éxito! Iniciá sesión para continuar.'),
            backgroundColor: const Color(0xFF00C896),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      String message = e.message;
      if (message.contains('already registered')) {
        message = 'Este email ya está registrado. Intentá iniciar sesión.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═════════════════════════════════════════════════════════════
  // VERIFICATION
  // ═════════════════════════════════════════════════════════════

  Future<void> _handleVerify() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresá los 6 dígitos del código'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _isVerified = true;
    });
    _checkAnimController.forward();

    // After showing success, create user + navigate
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _completeRegistration();
  }

  void _completeRegistration() {
    // This is now a fallback — main registration happens in _handleFormSubmit
    GoRouter.of(context).go('/login');
  }

  // ═════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ────────────────────────────────────
            _TopBar(
              currentStep: _currentStep,
              onBack: _goBack,
              showBack: _currentStep > 0 && !_isVerified,
            ),

            // ─── Step indicator ─────────────────────────────
            if (!_isVerified)
              _StepIndicator(currentStep: _currentStep),

            // ─── Pages ──────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepRoleSelection(onSelectRole: _selectRole),
                  _StepRegistrationForm(
                    selectedRole: _selectedRole ?? UserRole.client,
                    formKey: _formKey,
                    businessNameController: _businessNameController,
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    selectedCategoryId: _selectedCategoryId,
                    onCategoryChanged: (v) => setState(() => _selectedCategoryId = v),
                    categories: ref.watch(categoriesProvider).value ?? [],
                    obscurePassword: _obscurePassword,
                    obscureConfirm: _obscureConfirm,
                    isLoading: _isLoading,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onToggleConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onSubmit: _handleFormSubmit,
                    onSwitchRole: () => _goToStep(0),
                  ),
                  _StepVerification(
                    email: _emailController.text.trim(),
                    otpControllers: _otpControllers,
                    otpFocusNodes: _otpFocusNodes,
                    isVerified: _isVerified,
                    isVerifying: _isVerifying,
                    checkAnimation: _checkAnimation,
                    onVerify: _handleVerify,
                    onGoToLogin: () => context.go('/login'),
                    onNavigateAfterSuccess: _completeRegistration,
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

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;
  final bool showBack;

  const _TopBar({
    required this.currentStep,
    required this.onBack,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s8,
        vertical: AppSizes.s4,
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: showBack ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IconButton(
              onPressed: showBack ? onBack : null,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: AppStrings.back,
            ),
          ),
          const Spacer(),
          Text(
            AppStrings.appName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // balance
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;


    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s32,
        vertical: AppSizes.s8,
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i <= currentStep;
          final isCurrent = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 2,
                      color: i <= currentStep
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: isCurrent ? 32 : 24,
                  height: isCurrent ? 32 : 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.15),
                    border: isCurrent
                        ? Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 3,
                          )
                        : null,
                  ),
                  child: Center(
                    child: i < currentStep
                        ? Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: isCurrent ? 13 : 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 2,
                      color: i < currentStep
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 1 — ROLE SELECTION
// ═══════════════════════════════════════════════════════════════════════════

class _StepRoleSelection extends StatelessWidget {
  final void Function(UserRole role) onSelectRole;

  const _StepRoleSelection({required this.onSelectRole});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > AppSizes.breakpointTablet;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.s32),

              // ─── Header ───────────────────────────────────
              Text(
                '¿Cómo querés usar ReservPy?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.1, end: 0, duration: 500.ms),

              const SizedBox(height: AppSizes.s8),

              Text(
                'Elegí el tipo de cuenta según lo que necesités',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s40),

              // ─── Role Cards ───────────────────────────────
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _RoleCard(
                            icon: Icons.store_rounded,
                            iconColor: AppColors.primary,
                            title: 'Tengo un negocio',
                            subtitle:
                                'Quiero recibir reservas de mis clientes y gestionar mi agenda online.',
                            features: const [
                              'Página de reservas propia',
                              'Panel de administración',
                              'Gratis hasta 10 turnos/mes',
                            ],
                            ctaLabel: 'Crear mi negocio →',
                            ctaColor: AppColors.primary,
                            delay: 200,
                            onTap: () => onSelectRole(UserRole.business),
                          ),
                        ),
                        const SizedBox(width: AppSizes.s24),
                        Expanded(
                          child: _RoleCard(
                            icon: Icons.person_rounded,
                            iconColor: AppColors.accent,
                            title: 'Quiero reservar turnos',
                            subtitle:
                                'Quiero reservar turnos en negocios que usen ReservPy.',
                            features: const [
                              'Reservar en cualquier negocio',
                              'Ver y gestionar mis turnos',
                              'Cancelar o reprogramar',
                            ],
                            ctaLabel: 'Crear cuenta →',
                            ctaColor: AppColors.accent,
                            delay: 350,
                            onTap: () => onSelectRole(UserRole.client),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _RoleCard(
                          icon: Icons.store_rounded,
                          iconColor: AppColors.primary,
                          title: 'Tengo un negocio',
                          subtitle:
                              'Quiero recibir reservas de mis clientes y gestionar mi agenda online.',
                          features: const [
                            'Página de reservas propia',
                            'Panel de administración',
                            'Gratis hasta 10 turnos/mes',
                          ],
                          ctaLabel: 'Crear mi negocio →',
                          ctaColor: AppColors.primary,
                          delay: 200,
                          onTap: () => onSelectRole(UserRole.business),
                        ),
                        const SizedBox(height: AppSizes.s16),
                        _RoleCard(
                          icon: Icons.person_rounded,
                          iconColor: AppColors.accent,
                          title: 'Quiero reservar turnos',
                          subtitle:
                              'Quiero reservar turnos en negocios que usen ReservPy.',
                          features: const [
                            'Reservar en cualquier negocio',
                            'Ver y gestionar mis turnos',
                            'Cancelar o reprogramar',
                          ],
                          ctaLabel: 'Crear cuenta →',
                          ctaColor: AppColors.accent,
                          delay: 350,
                          onTap: () => onSelectRole(UserRole.client),
                        ),
                      ],
                    ),

              const SizedBox(height: AppSizes.s40),

              // ─── Login link ───────────────────────────────
              _LoginLink()
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role Card ──────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> features;
  final String ctaLabel;
  final Color ctaColor;
  final int delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.ctaLabel,
    required this.ctaColor,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          elevation: _isHovered ? 8 : 2,
          shadowColor: widget.iconColor.withValues(alpha: _isHovered ? 0.25 : 0.08),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.s24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: _isHovered
                      ? widget.iconColor.withValues(alpha: 0.4)
                      : colorScheme.outline.withValues(alpha: 0.12),
                  width: _isHovered ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 28),
                  ),

                  const SizedBox(height: AppSizes.s16),

                  // Title
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSizes.s8),

                  // Subtitle
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppSizes.s20),

                  // Features
                  ...widget.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.s8),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s8),
                          Expanded(
                            child: Text(
                              f,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.s20),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonMd,
                    child: ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.ctaColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      child: Text(
                        widget.ctaLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: widget.delay),
          duration: 500.ms,
        )
        .slideY(
          begin: 0.12,
          end: 0,
          delay: Duration(milliseconds: widget.delay),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 2 — REGISTRATION FORM
// ═══════════════════════════════════════════════════════════════════════════

class _StepRegistrationForm extends StatelessWidget {
  final UserRole selectedRole;
  final GlobalKey<FormState> formKey;
  final TextEditingController businessNameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final List<BusinessCategory> categories;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchRole;

  const _StepRegistrationForm({
    required this.selectedRole,
    required this.formKey,
    required this.businessNameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.categories,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedRole == UserRole.business) {
      return _buildBusinessLayout(context);
    }
    return _buildClientLayout(context);
  }

  // ─── BUSINESS LAYOUT (split-screen on wide) ───────────────

  Widget _buildBusinessLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > AppSizes.breakpointTablet;

        if (isWide) {
          return Row(
            children: [
              // LEFT — Hero panel
              Expanded(
                flex: 5,
                child: _BusinessHeroPanel(),
              ),
              // RIGHT — Form
              Expanded(
                flex: 5,
                child: _buildBusinessFormPanel(context),
              ),
            ],
          );
        }

        // Narrow: just the form
        return _buildBusinessFormPanel(context);
      },
    );
  }

  Widget _buildBusinessFormPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s24,
        vertical: AppSizes.s16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.s8),

                // Header
                Text(
                  'Crear cuenta de negocio',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.08, end: 0, duration: 400.ms),

                const SizedBox(height: AppSizes.s4),

                Text(
                  'Empezá a recibir reservas hoy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // Google button (placeholder)
                _GoogleSignUpButton()
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s20),

                // Divider
                _OrDivider()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s20),

                // Business name
                AppTextField(
                  controller: businessNameController,
                  label: AppStrings.businessName,
                  hint: 'Mi Negocio',
                  prefixIcon: Icons.storefront_rounded,
                  validator: (v) =>
                      Validators.required(v, AppStrings.businessName),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Category selector (Rubro) — Premium bottom sheet
                Builder(
                  builder: (context) {
                    final selectedCat = selectedCategoryId != null
                        ? categories.firstWhere(
                            (c) => c.id == selectedCategoryId,
                            orElse: () => categories.last,
                          )
                        : null;

                    return GestureDetector(
                      onTap: () => _showCategoryPicker(
                        context,
                        selectedCategoryId,
                        onCategoryChanged,
                        categories,
                      ),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Rubro del negocio *',
                            hintText: 'Seleccioná tu rubro',
                            prefixIcon: selectedCat != null
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: selectedCat.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(selectedCat.icon, size: 16, color: selectedCat.color),
                                    ),
                                  )
                                : const Icon(Icons.category_rounded),
                            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            ),
                          ),
                          controller: TextEditingController(
                            text: selectedCat?.name ?? '',
                          ),
                          validator: (_) =>
                              selectedCategoryId == null ? 'Seleccioná un rubro' : null,
                        ),
                      ),
                    );
                  },
                )
                    .animate()
                    .fadeIn(delay: 220.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 220.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Name row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: firstNameController,
                        label: AppStrings.firstName,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) =>
                            Validators.required(v, AppStrings.firstName),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: AppTextField(
                        controller: lastNameController,
                        label: AppStrings.lastName,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) =>
                            Validators.required(v, AppStrings.lastName),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 250.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Email
                AppTextField(
                  controller: emailController,
                  label: AppStrings.email,
                  hint: 'tu@negocio.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 300.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Password row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: passwordController,
                        label: AppStrings.password,
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: obscurePassword,
                        validator: Validators.password,
                        suffix: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onPressed: onTogglePassword,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: AppTextField(
                        controller: confirmPasswordController,
                        label: AppStrings.confirmPassword,
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: obscureConfirm,
                        validator: (v) => Validators.confirmPassword(
                          v,
                          passwordController.text,
                        ),
                        suffix: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onPressed: onToggleConfirm,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 350.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // Submit CTA
                _GradientButton(
                  label: 'Crear mi negocio gratis →',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : onSubmit,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 400.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s12),

                // Small text
                Text(
                  'Gratis hasta 10 reservas/mes · Sin tarjeta de crédito',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s8),

                // Terms
                Text(
                  'Al crear tu cuenta, aceptás los Términos de Servicio y la Política de Privacidad de ReservPy.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 475.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // Login link
                _LoginLink()
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s8),

                // Switch to client
                Center(
                  child: GestureDetector(
                    onTap: onSwitchRole,
                    child: Text.rich(
                      TextSpan(
                        text: '¿Querés reservar un turno? ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        children: [
                          TextSpan(
                            text: 'Crear cuenta de usuario',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 525.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── CLIENT LAYOUT (simple form) ──────────────────────────

  Widget _buildClientLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s24,
        vertical: AppSizes.s16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.s16),

                // Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: AppColors.accent,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                    ),

                const SizedBox(height: AppSizes.s16),

                Text(
                  'Crear cuenta',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s4),

                Text(
                  'Completá tus datos para empezar a reservar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s32),

                // Google button
                _GoogleSignUpButton()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 150.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s20),

                _OrDivider()
                    .animate()
                    .fadeIn(delay: 175.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s20),

                // Name row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: firstNameController,
                        label: AppStrings.firstName,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) =>
                            Validators.required(v, AppStrings.firstName),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: AppTextField(
                        controller: lastNameController,
                        label: AppStrings.lastName,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) =>
                            Validators.required(v, AppStrings.lastName),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Email
                AppTextField(
                  controller: emailController,
                  label: AppStrings.email,
                  hint: 'tu@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 250.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Phone (optional)
                AppTextField(
                  controller: phoneController,
                  label: '${AppStrings.phone} (opcional)',
                  hint: '+595 981 123456',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 300.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Password
                AppTextField(
                  controller: passwordController,
                  label: AppStrings.password,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: obscurePassword,
                  validator: Validators.password,
                  suffix: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: onTogglePassword,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 350.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s16),

                // Confirm password
                AppTextField(
                  controller: confirmPasswordController,
                  label: AppStrings.confirmPassword,
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: obscureConfirm,
                  validator: (v) => Validators.confirmPassword(
                    v,
                    passwordController.text,
                  ),
                  suffix: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: onToggleConfirm,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 400.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                // Submit
                AppButton(
                  label: 'Crear cuenta',
                  icon: Icons.person_add_rounded,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : onSubmit,
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, delay: 450.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s8),

                // Terms
                Text(
                  'Al crear tu cuenta, aceptás los Términos de Servicio y la Política de Privacidad de ReservPy.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 475.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s24),

                _LoginLink()
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s8),

                // Switch to business
                Center(
                  child: GestureDetector(
                    onTap: onSwitchRole,
                    child: Text.rich(
                      TextSpan(
                        text: '¿Tenés un negocio? ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        children: [
                          TextSpan(
                            text: 'Crear cuenta de negocio',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 525.ms, duration: 400.ms),

                const SizedBox(height: AppSizes.s32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Business Hero Panel (left side on wide screens) ────────────────────

class _BusinessHeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.accent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSizes.s32),

            // Logo / Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 36,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                ),

            const SizedBox(height: AppSizes.s24),

            // Title
            Text(
              'Tu negocio recibiendo\nturnos online en minutos',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 500.ms)
                .slideX(begin: -0.08, end: 0, delay: 100.ms, duration: 500.ms),

            const SizedBox(height: AppSizes.s12),

            // Subtitle
            Text(
              'Creá tu cuenta, configurá tus servicios y compartí tu link. Tus clientes reservan solos.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms),

            const SizedBox(height: AppSizes.s32),

            // Bullet points
            _HeroBullet(
              text: 'Creá tu página de reservas en minutos',
              delay: 300,
            ),
            _HeroBullet(
              text: 'Recibí turnos online 24/7',
              delay: 400,
            ),
            _HeroBullet(
              text: 'Gratis hasta 10 reservas por mes',
              delay: 500,
            ),

            const SizedBox(height: AppSizes.s48),

            // Testimonial card
            Container(
              padding: const EdgeInsets.all(AppSizes.s20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 24,
                      ),
                      const Spacer(),
                      ...List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber.shade300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Text(
                    'Dejé de perder tiempo coordinando turnos por WhatsApp. En un día ya tenía todo funcionando.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s12),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Text(
                            'SR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s8),
                      Text(
                        '— Sofía R., Psicóloga',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms)
                .slideY(begin: 0.1, end: 0, delay: 600.ms, duration: 500.ms),

            const SizedBox(height: AppSizes.s40),
          ],
        ),
      ),
    );
  }
}

class _HeroBullet extends StatelessWidget {
  final String text;
  final int delay;

  const _HeroBullet({required this.text, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        )
        .slideX(
          begin: -0.05,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 3 — EMAIL VERIFICATION
// ═══════════════════════════════════════════════════════════════════════════

class _StepVerification extends StatelessWidget {
  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool isVerified;
  final bool isVerifying;
  final Animation<double> checkAnimation;
  final VoidCallback onVerify;
  final VoidCallback onGoToLogin;
  final VoidCallback onNavigateAfterSuccess;

  const _StepVerification({
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.isVerified,
    required this.isVerifying,
    required this.checkAnimation,
    required this.onVerify,
    required this.onGoToLogin,
    required this.onNavigateAfterSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: isVerified
                ? _VerificationSuccess(
                    key: const ValueKey('success'),
                    checkAnimation: checkAnimation,
                    onContinue: onNavigateAfterSuccess,
                  )
                : _VerificationForm(
                    key: const ValueKey('form'),
                    email: email,
                    otpControllers: otpControllers,
                    otpFocusNodes: otpFocusNodes,
                    isVerifying: isVerifying,
                    onVerify: onVerify,
                    onGoToLogin: onGoToLogin,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Verification Form ──────────────────────────────────────────────────

class _VerificationForm extends StatelessWidget {
  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool isVerifying;
  final VoidCallback onVerify;
  final VoidCallback onGoToLogin;

  const _VerificationForm({
    super.key,
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.isVerifying,
    required this.onVerify,
    required this.onGoToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        const SizedBox(height: AppSizes.s40),

        // Mail icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_unread_rounded,
            size: 40,
            color: colorScheme.primary,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: AppSizes.s24),

        Text(
          'Verificá tu email',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s8),

        Text.rich(
          TextSpan(
            text: 'Enviamos un código de 6 dígitos a ',
            children: [
              TextSpan(
                text: email.isNotEmpty ? email : 'tu correo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s40),

        // OTP fields
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            return Container(
              width: 48,
              height: 56,
              margin: EdgeInsets.only(
                right: i < 5 ? (i == 2 ? AppSizes.s16 : AppSizes.s8) : 0,
              ),
              child: TextField(
                controller: otpControllers[i],
                focusNode: otpFocusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && i < 5) {
                    otpFocusNodes[i + 1].requestFocus();
                  } else if (value.isEmpty && i > 0) {
                    otpFocusNodes[i - 1].requestFocus();
                  }
                  // Auto-verify when all filled
                  if (i == 5 && value.isNotEmpty) {
                    final code =
                        otpControllers.map((c) => c.text).join();
                    if (code.length == 6) {
                      Future.delayed(
                        const Duration(milliseconds: 300),
                        onVerify,
                      );
                    }
                  }
                },
              ),
            );
          }),
        )
            .animate()
            .fadeIn(delay: 250.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, delay: 250.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s32),

        // Verify CTA
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Verificar cuenta',
            icon: Icons.verified_rounded,
            isLoading: isVerifying,
            onPressed: isVerifying ? null : onVerify,
          ),
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0, delay: 350.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s24),

        // Expiry info
        Text(
          'El código expira en 15 minutos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s4),

        // Resend link
        GestureDetector(
          onTap: onGoToLogin,
          child: Text(
            '¿No llegó? Registrate de nuevo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        )
            .animate()
            .fadeIn(delay: 425.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s16),

        // Wrong email link
        GestureDetector(
          onTap: () {
            // Navigate back to form step
            // This is handled by the back button in the top bar
          },
          child: Text(
            'Escribí mal mi correo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        )
            .animate()
            .fadeIn(delay: 450.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s32),
      ],
    );
  }
}

// ─── Verification Success ───────────────────────────────────────────────

class _VerificationSuccess extends StatelessWidget {
  final Animation<double> checkAnimation;
  final VoidCallback onContinue;

  const _VerificationSuccess({
    super.key,
    required this.checkAnimation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSizes.s64),

        // Animated checkmark
        ScaleTransition(
          scale: checkAnimation,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.s32),

        Text(
          '¡Cuenta verificada!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.success,
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s8),

        Text(
          'Tu email fue confirmado. Ya podés ingresar.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 450.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s40),

        // Confetti-like dots (decorative)
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final colors = [
                AppColors.primary,
                AppColors.success,
                AppColors.info,
                AppColors.warning,
                AppColors.primary,
              ];
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 500 + i * 100),
                    duration: 300.ms,
                  )
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    delay: Duration(milliseconds: 500 + i * 100),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  );
            }),
          ),
        ),

        const SizedBox(height: AppSizes.s32),

        // CTA
        SizedBox(
          width: double.infinity,
          child: _GradientButton(
            label: 'Ir a iniciar sesión →',
            onPressed: onContinue,
          ),
        )
            .animate()
            .fadeIn(delay: 700.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0, delay: 700.ms, duration: 400.ms),

        const SizedBox(height: AppSizes.s32),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${AppStrings.hasAccount} ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            AppStrings.signIn,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleSignUpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonMd,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            final authRepo = AuthRepository();
            await authRepo.signInWithGoogle();
            // OAuth redirect handles the rest — the app will reload with the session
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error con Google: $e'),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            );
          }
        },
        icon: Icon(
          Icons.g_mobiledata_rounded,
          size: 28,
          color: colorScheme.onSurface,
        ),
        label: Text(
          'Registrarse con Google',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
          child: Text(
            'o con email',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonLg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CATEGORY PICKER — Premium bottom sheet
// ═══════════════════════════════════════════════════════════════════════════

void _showCategoryPicker(
  BuildContext context,
  String? currentlySelected,
  ValueChanged<String?> onChanged,
  List<BusinessCategory> categories,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CategoryPickerSheet(
      selected: currentlySelected,
      categories: categories,
      onSelect: (id) {
        onChanged(id);
        Navigator.of(ctx).pop();
      },
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({required this.selected, required this.onSelect, required this.categories});
  final String? selected;
  final ValueChanged<String> onSelect;
  final List<BusinessCategory> categories;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String _search = '';

  List<BusinessCategory> get _filtered => _search.isEmpty
      ? widget.categories
      : widget.categories
            .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.category_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Seleccioná tu rubro',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Search ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Buscar rubro...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Grid ──
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final cat = _filtered[i];
                final isSelected = cat.id == widget.selected;

                return GestureDetector(
                  onTap: () => widget.onSelect(cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.12)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? cat.color : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: cat.color.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.2)
                                : cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cat.icon,
                            size: 22,
                            color: cat.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? cat.color : Colors.grey.shade700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Icon(Icons.check_circle_rounded, size: 16, color: cat.color),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

