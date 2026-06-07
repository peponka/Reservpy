import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla de éxito que se muestra justo después de registrar un negocio.
/// Confirma que el negocio fue creado y lleva al panel del negocio.
class BusinessCreatedScreen extends StatefulWidget {
  final String businessName;

  const BusinessCreatedScreen({super.key, required this.businessName});

  @override
  State<BusinessCreatedScreen> createState() => _BusinessCreatedScreenState();
}

class _BusinessCreatedScreenState extends State<BusinessCreatedScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF20A482);
  static const Color _textPrimary = Color(0xFF1A1A2E);

  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Check animado dentro de un círculo
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Text(
                      '¡Tu negocio fue creado! ??',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.businessName.trim().isNotEmpty
                          ? '"${widget.businessName.trim()}" ya está listo para empezar a recibir reservas.'
                          : 'Tu negocio ya está listo para empezar a recibir reservas.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _textPrimary.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Botón ? panel del negocio
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/business'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Ir a mi negocio ?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
