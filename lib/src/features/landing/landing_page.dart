import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'landing_theme.dart';
import 'sections/navbar.dart';
import 'sections/hero_section.dart';
import 'sections/dashboard_mockup.dart';
import 'sections/industries_section.dart';
import 'sections/stats_section.dart';
import 'sections/features_section.dart';
import 'sections/reservbot_section.dart';
import 'sections/seo_block.dart';
import 'sections/how_it_works.dart';
import 'sections/testimonials_section.dart';
import 'sections/pricing_section.dart';
import 'sections/faq_section.dart';
import 'sections/final_cta.dart';
import 'sections/footer_section.dart';

/// Main landing page that composes all 14 sections into a single
/// scrollable marketing page for Reservly Paraguay.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final ScrollController _scrollController;

  // GlobalKeys for scroll-to-section navigation
  final _featuresKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _testimonialsKey = GlobalKey();
  final _pricingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: LandingColors.bgWhite,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.light(
          primary: LandingColors.primary,
          onPrimary: Colors.white,
          surface: LandingColors.bgWhite,
          onSurface: LandingColors.textPrimary,
        ),
      ),
      child: Scaffold(
        backgroundColor: LandingColors.bgWhite,
        body: Stack(
          children: [
            // ─── Scrollable content ─────────────────────
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Spacer for fixed navbar
                  const SizedBox(height: 72),

                  // 1. Hero
                  const HeroSection(),

                  // 2. Dashboard Mockup
                  const DashboardMockup(),

                  // 3. Industries
                  const IndustriesSection(),

                  // 4. Stats
                  const StatsSection(),

                  // 5. Features
                  Container(
                    key: _featuresKey,
                    child: const FeaturesSection(),
                  ),

                  // 6. Reservbot
                  const ReservbotSection(),

                  // 7. SEO Block
                  const SeoBlock(),

                  // 8. How it works
                  Container(
                    key: _howItWorksKey,
                    child: const HowItWorksSection(),
                  ),

                  // 9. Testimonials
                  Container(
                    key: _testimonialsKey,
                    child: const TestimonialsSection(),
                  ),

                  // 10. Pricing
                  Container(
                    key: _pricingKey,
                    child: const PricingSection(),
                  ),

                  // 11. FAQ
                  const FaqSection(),

                  // 12. Final CTA
                  const FinalCtaSection(),

                  // 13. Footer
                  const FooterSection(),
                ],
              ),
            ),

            // ─── Fixed Navbar ───────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LandingNavbar(
                onFeaturesPressed: () => _scrollToSection(_featuresKey),
                onHowItWorksPressed: () => _scrollToSection(_howItWorksKey),
                onTestimonialsPressed: () => _scrollToSection(_testimonialsKey),
                onPricingPressed: () => _scrollToSection(_pricingKey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
