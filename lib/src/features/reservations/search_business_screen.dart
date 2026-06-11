import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/data/repositories/category_repository.dart';
import 'package:reservpy/src/features/favorites/favorite_button.dart';

// --- Local state -------------------------------------------------------------
final _selectedCategoryProvider = StateProvider<BusinessCategory?>((ref) => null);
final _businessFilterProvider = StateProvider<_BusinessFilter>((ref) => _BusinessFilter.all);

enum _BusinessFilter { all, open, recent }

/// Two-page search screen:
///   Page 1 — Browse categories (grid with business counts)
///   Page 2 — View businesses in the selected category (rich cards, filters)
class SearchBusinessScreen extends ConsumerStatefulWidget {
  const SearchBusinessScreen({super.key});

  @override
  ConsumerState<SearchBusinessScreen> createState() =>
      _SearchBusinessScreenState();
}

class _SearchBusinessScreenState extends ConsumerState<SearchBusinessScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).state = _searchController.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(_selectedCategoryProvider);

    if (selectedCategory != null) {
      return _BusinessListPage(
        category: selectedCategory,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        onBack: () {
          ref.read(_selectedCategoryProvider.notifier).state = null;
          ref.read(_businessFilterProvider.notifier).state = _BusinessFilter.all;
          _searchController.clear();
        },
      );
    }

    return _CategoriesPage(
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
    );
  }
}

// -----------------------------------------------------------------------------
// PAGE 1: CATEGORIES
// -----------------------------------------------------------------------------
class _CategoriesPage extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const _CategoriesPage({
    required this.searchController,
    required this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final businessCounts = ref.watch(businessCountByCategoryProvider);
    final query = searchController.text.toLowerCase().trim();

    // Sort: alphabetically, "Otros" last
    final sorted = [...categories]..sort((a, b) {
      if (a.name == 'Otros') return 1;
      if (b.name == 'Otros') return -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    // Filter by search
    final filtered = query.isEmpty
        ? sorted
        : sorted.where((c) => c.name.toLowerCase().contains(query)).toList();

    // Total business count
    final totalBusinesses = businessCounts.values.fold<int>(0, (a, b) => a + b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossCount;
        if (width >= 1000) {
          crossCount = 5;
        } else if (width >= 700) {
          crossCount = 4;
        } else if (width >= 480) {
          crossCount = 3;
        } else {
          crossCount = 2;
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -- Hero Header --
                _buildHeader(context, totalBusinesses),
                const SizedBox(height: AppSizes.s24),

                // -- Section title --
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: Text(
                          'Categorías',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      // Category count
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          '${filtered.length} categorías',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Elegí una categoría para ver los negocios disponibles',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s20),

                // -- Categories Grid --
                filtered.isEmpty
                    ? _buildEmptySearch(context)
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.s24),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: AppSizes.s12,
                            mainAxisSpacing: AppSizes.s12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final cat = filtered[index];
                            final count = businessCounts[cat.id] ?? 0;
                            return _CategoryCard(
                              category: cat,
                              businessCount: count,
                              onTap: () {
                                ref
                                    .read(_selectedCategoryProvider.notifier)
                                    .state = cat;
                              },
                            );
                          },
                        ),
                      ),

                const SizedBox(height: AppSizes.s32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int totalBusinesses) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.s24, AppSizes.s16, AppSizes.s24, 0),
      padding: const EdgeInsets.all(AppSizes.s24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF20A482), Color(0xFF198A6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20A482).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar negocios',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalBusinesses negocios disponibles',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s20),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.accent),
              decoration: InputDecoration(
                hintText: 'Buscá por categoría...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF20A482), size: 22),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: () => searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide:
                      const BorderSide(color: Color(0xFF20A482), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s24, vertical: AppSizes.s48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF20A482).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 40, color: Color(0xFF20A482)),
            ),
            const SizedBox(height: AppSizes.s20),
            Text(
              'No se encontraron categorías',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              'Probá con otro término de búsqueda',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CATEGORY CARD — Enhanced with business count
// -----------------------------------------------------------------------------
class _CategoryCard extends StatefulWidget {
  final BusinessCategory category;
  final int businessCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.businessCount,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: _isHovered
                ? cat.color.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: _isHovered
                  ? cat.color.withValues(alpha: 0.4)
                  : AppColors.divider,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? cat.color.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 16 : 6,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: _isHovered ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat.icon,
                    color: cat.color, size: _isHovered ? 28 : 26),
              ),
              const SizedBox(height: AppSizes.s8),
              // Label
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.s6),
                child: Text(
                  cat.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              // Business count badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.businessCount > 0
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.textMuted.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  widget.businessCount > 0
                      ? '${widget.businessCount} negocio${widget.businessCount == 1 ? '' : 's'}'
                      : 'Próximamente',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.businessCount > 0
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAGE 2: BUSINESSES IN CATEGORY
// -----------------------------------------------------------------------------
class _BusinessListPage extends ConsumerStatefulWidget {
  final BusinessCategory category;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onBack;

  const _BusinessListPage({
    required this.category,
    required this.searchController,
    required this.searchFocusNode,
    required this.onBack,
  });

  @override
  ConsumerState<_BusinessListPage> createState() => _BusinessListPageState();
}

class _BusinessListPageState extends ConsumerState<_BusinessListPage> {
  final _newCategoryController = TextEditingController();
  String? _categoryError;

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBusinesses = ref.watch(businessesProvider).value ?? [];
    final query = ref.watch(searchQueryProvider).toLowerCase().trim();
    final activeFilter = ref.watch(_businessFilterProvider);
    final now = DateTime.now();

    // Filter by category
    var filtered = allBusinesses
        .where((b) => b.categoryId == widget.category.id && b.isActive)
        .toList();

    // Filter by search text
    if (query.isNotEmpty) {
      filtered = filtered.where((b) {
        final name = b.name.toLowerCase();
        final addr = (b.address ?? '').toLowerCase();
        final desc = (b.description ?? '').toLowerCase();
        return name.contains(query) ||
            addr.contains(query) ||
            desc.contains(query);
      }).toList();
    }

    // Apply filter chips
    switch (activeFilter) {
      case _BusinessFilter.open:
        filtered = filtered.where((b) => b.isCurrentlyOpen).toList();
        break;
      case _BusinessFilter.recent:
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        filtered =
            filtered.where((b) => b.createdAt.isAfter(sevenDaysAgo)).toList();
        break;
      case _BusinessFilter.all:
        break;
    }

    // Smart sort: open first, then by name
    filtered.sort((a, b) {
      if (a.isCurrentlyOpen && !b.isCurrentlyOpen) return -1;
      if (!a.isCurrentlyOpen && b.isCurrentlyOpen) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossCount;
        double aspectRatio;
        if (width >= 1000) {
          crossCount = 3;
          aspectRatio = 0.72;
        } else if (width >= 650) {
          crossCount = 2;
          aspectRatio = 0.75;
        } else {
          // Mobile: una sola columna, card "alta" para mostrar todo
          // (nombre, categoría, horarios, precios y botones sin cortes).
          crossCount = 1;
          aspectRatio = 0.85;
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -- Category header --
                _buildCategoryHeader(context, widget.category, filtered.length),

                const SizedBox(height: AppSizes.s16),

                // -- Search bar --
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: widget.searchController,
                      focusNode: widget.searchFocusNode,
                      style: GoogleFonts.inter(
                          fontSize: 15, color: AppColors.accent),
                      decoration: InputDecoration(
                        hintText: 'Buscar en ${widget.category.name}...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: widget.category.color, size: 22),
                        suffixIcon: widget.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.textSecondary, size: 20),
                                onPressed: () {
                                  widget.searchController.clear();
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.s16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide(
                              color: widget.category.color, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.s16),

                // -- Filter Chips --
                _buildFilterChips(ref, activeFilter),

                const SizedBox(height: AppSizes.s16),

                // -- Results count --
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.s24),
                  child: Text(
                    '${filtered.length} negocio${filtered.length == 1 ? '' : 's'} encontrado${filtered.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.s16),

                // -- Business cards or empty state --
                if (filtered.isEmpty)
                  _buildEmptyState(context, widget.category)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s24),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: AppSizes.s20,
                        // Más respiración entre cards (antes pegadas)
                        mainAxisSpacing: AppSizes.s24,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _BusinessCard(
                          business: filtered[index],
                          category: widget.category,
                        );
                      },
                    ),
                  ),

                const SizedBox(height: AppSizes.s32),
              ],
            ),
          ),
        );
      },
    );
  }

  // -- Filter Chips Row --
  Widget _buildFilterChips(WidgetRef ref, _BusinessFilter active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChipButton(
              label: 'Todos',
              icon: Icons.apps_rounded,
              isActive: active == _BusinessFilter.all,
              color: widget.category.color,
              onTap: () => ref.read(_businessFilterProvider.notifier).state =
                  _BusinessFilter.all,
            ),
            const SizedBox(width: AppSizes.s8),
            _FilterChipButton(
              label: 'Abiertos ahora',
              icon: Icons.access_time_filled_rounded,
              isActive: active == _BusinessFilter.open,
              color: AppColors.success,
              onTap: () => ref.read(_businessFilterProvider.notifier).state =
                  _BusinessFilter.open,
            ),
            const SizedBox(width: AppSizes.s8),
            _FilterChipButton(
              label: 'Nuevos',
              icon: Icons.new_releases_rounded,
              isActive: active == _BusinessFilter.recent,
              color: AppColors.info,
              onTap: () => ref.read(_businessFilterProvider.notifier).state =
                  _BusinessFilter.recent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(
      BuildContext context, BusinessCategory category, int resultsCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.s24, AppSizes.s16, AppSizes.s24, 0),
      padding: const EdgeInsets.all(AppSizes.s20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            category.color,
            category.color.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Text(
                  'Volver a categorías',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(category.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Negocios disponibles para reservar',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, BusinessCategory category) {
    final isOtros = category.name == 'Otros';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s24, vertical: AppSizes.s48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(category.icon, size: 40, color: category.color),
            ),
            const SizedBox(height: AppSizes.s20),
            Text(
              isOtros
                  ? '¿No encontrás tu categoría?'
                  : 'Todavía no hay negocios',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              isOtros
                  ? 'Creá una nueva categoría para tu tipo de negocio.\nSi ya existe, te avisaremos.'
                  : 'Aún no hay negocios registrados en ${category.name}.\n¡Pronto habrá opciones disponibles!',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (isOtros) ...[
              const SizedBox(height: AppSizes.s24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateCategoryDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Crear nueva categoría',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20A482),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows dialog to create a new category. Rejects duplicates.
  void _showCreateCategoryDialog(BuildContext context) {
    _newCategoryController.clear();
    _categoryError = null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF20A482).withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: Color(0xFF20A482), size: 22),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Text(
                      'Crear nueva categoría',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¿No encontrás la categoría que buscás?\nCreá una nueva para tu tipo de negocio.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s20),
                  TextField(
                    controller: _newCategoryController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.inter(
                        fontSize: 15, color: AppColors.accent),
                    decoration: InputDecoration(
                      labelText: 'Nombre de la categoría',
                      labelStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary),
                      hintText: 'Ej: Tatuajes, Coaching, etc.',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textMuted),
                      errorText: _categoryError,
                      errorStyle: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.error),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: const Icon(Icons.category_rounded,
                          color: Color(0xFF20A482), size: 20),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: const BorderSide(
                            color: Color(0xFF20A482), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: BorderSide(color: AppColors.error),
                      ),
                    ),
                    onChanged: (_) {
                      if (_categoryError != null) {
                        setDialogState(() => _categoryError = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = _newCategoryController.text.trim();

                    if (name.isEmpty) {
                      setDialogState(() {
                        _categoryError =
                            'Ingresá un nombre para la categoría';
                      });
                      return;
                    }

                    if (name.length < 3) {
                      setDialogState(() {
                        _categoryError =
                            'El nombre debe tener al menos 3 caracteres';
                      });
                      return;
                    }

                    final categories =
                        ref.read(categoriesProvider).value ?? [];
                    final exists = categories.any(
                        (c) => c.name.toLowerCase() == name.toLowerCase());

                    if (exists) {
                      setDialogState(() {
                        _categoryError =
                            'Ya existe una categoría con ese nombre';
                      });
                      return;
                    }

                    final hue = (name.hashCode % 360).toDouble().abs();
                    final catColor =
                        HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();
                    final hexColor =
                        '#${catColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

                    try {
                      final newCategory =
                          await CategoryRepository().create(
                        name,
                        color: hexColor,
                      );

                      ref.invalidate(categoriesProvider);

                      ref
                          .read(_selectedCategoryProvider.notifier)
                          .state = newCategory;

                      if (!context.mounted) return;
                      Navigator.of(dialogContext).pop();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Categoría "$name" creada exitosamente',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF20A482),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() {
                        _categoryError = 'Error al crear: $e';
                      });
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Crear categoría',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20A482),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s16, vertical: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// FILTER CHIP BUTTON
// -----------------------------------------------------------------------------
class _FilterChipButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color.withValues(alpha: 0.12)
                : _isHovered
                    ? widget.color.withValues(alpha: 0.05)
                    : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: widget.isActive
                  ? widget.color
                  : _isHovered
                      ? widget.color.withValues(alpha: 0.4)
                      : AppColors.divider,
              width: widget.isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 16,
                  color: widget.isActive
                      ? widget.color
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isActive
                      ? widget.color
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM BUSINESS CARD — Enhanced with services, prices, badges, dual CTA
// -----------------------------------------------------------------------------
class _BusinessCard extends ConsumerStatefulWidget {
  final Business business;
  final BusinessCategory category;

  const _BusinessCard({
    required this.business,
    required this.category,
  });

  @override
  ConsumerState<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends ConsumerState<_BusinessCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final business = widget.business;
    final category = widget.category;
    final services =
        ref.watch(businessServicesProvider(business.id)).value ?? [];
    final isOpen = business.isCurrentlyOpen;
    final initial =
        business.name.isNotEmpty ? business.name[0].toUpperCase() : '?';

    // Is new? (< 7 days)
    final isNew = DateTime.now().difference(business.createdAt).inDays < 7;

    // Price range
    final prices = services
        .where((s) => s.price != null && s.price! > 0)
        .map((s) => s.price!)
        .toList()
      ..sort();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: _isHovered
                ? category.color.withValues(alpha: 0.35)
                : AppColors.divider.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? category.color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -- Top: Gradient Hero --
              Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      category.color,
                      category.color.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -15,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Initial avatar
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: category.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Status badge (top right)
                    Positioned(
                      top: AppSizes.s8,
                      right: AppSizes.s8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.success.withValues(alpha: 0.9)
                              : AppColors.error.withValues(alpha: 0.9),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOpen ? 'Abierto' : 'Cerrado',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // "Nuevo" badge (top left)
                    if (isNew)
                      Positioned(
                        top: AppSizes.s8,
                        left: AppSizes.s8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.9),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.new_releases_rounded,
                                  size: 11, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                'Nuevo',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // -- Body --
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.s16, AppSizes.s12, AppSizes.s16, AppSizes.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business name + Favorite
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              business.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          FavoriteButton(businessId: business.id),
                        ],
                      ),
                      const SizedBox(height: AppSizes.s6),

                      // Category + services count row
                      Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  category.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(category.icon,
                                    size: 11, color: category.color),
                                const SizedBox(width: 3),
                                Text(
                                  category.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: category.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.s6),
                          // Service count
                          if (services.isNotEmpty)
                            Text(
                              '${services.length} servicio${services.length == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.s8),

                      // Address
                      if (business.address != null &&
                          business.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.s6),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: AppColors.textMuted),
                              const SizedBox(width: AppSizes.s4),
                              Expanded(
                                child: Text(
                                  business.address!,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Schedule + Price range row
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: AppSizes.s4),
                          Text(
                            '${business.openingTimeStr} - ${business.closingTimeStr}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          // Price range
                          if (prices.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm),
                              ),
                              child: Text(
                                prices.length == 1
                                    ? _formatPrice(prices.first)
                                    : '${_formatPrice(prices.first)} – ${_formatPrice(prices.last)}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.s12),

                      // -- Dual CTA Row --
                      Row(
                        children: [
                          // "Ver negocio" outline button
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.push(
                                      '/business-detail/${business.id}');
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(
                                      color: AppColors.divider, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusSm),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                                child: Text(
                                  'Ver negocio',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.s8),
                          // "Reservar" filled button
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push(
                                      '/reserve/${business.id}/service');
                                },
                                icon: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14),
                                label: Text(
                                  'Reservar',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusSm),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final intPrice = price.toInt();
    if (intPrice >= 1000000) {
      return '${(intPrice / 1000000).toStringAsFixed(1)}M';
    }
    if (intPrice >= 1000) {
      return '${(intPrice / 1000).toStringAsFixed(0)}K';
    }
    return intPrice.toString();
  }
}
