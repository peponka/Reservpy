import 'package:flutter/material.dart';
import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:reservpy/src/core/constants/app_colors.dart';
import 'package:reservpy/src/core/constants/app_sizes.dart';
import 'package:reservpy/src/core/widgets/widgets.dart';
import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/shared/providers/providers.dart';
import 'package:reservpy/src/data/repositories/business_repository.dart';
import 'package:reservpy/src/data/repositories/service_repository.dart';
import 'package:reservpy/src/core/utils/string_utils.dart';

/// Business onboarding wizard — shown after first login.
///
/// **Step 0 — Seleccionar categoría**: Pick a business category from a grid.
///   Auto-populates default services for the chosen category.
/// **Step 1 — Crear servicios**: Service name, description, duration chips,
///   price & currency. Created services appear as cards below.
/// **Step 2 — Definir horarios**: Work-day toggles, open/close pickers,
///   slot duration, optional break, schedule preview.
/// **Step 3 — Compartir link**: Celebration animation, shareable link card,
///   QR placeholder, plan summary, CTA to dashboard.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;
  static const _uuid = Uuid();

  // ─── Step 0 state ──────────────────────────────────────
  String? _selectedCategoryId;
  // Rubro guardado en el registro, pendiente de aplicar cuando carguen las categorías
  String? _pendingCategoryId;
  final _businessNameController = TextEditingController();
  final _businessRepo = BusinessRepository();

  // ─── Step 1 state ──────────────────────────────────────
  final _serviceFormKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _servicePriceController = TextEditingController();
  int _selectedDuration = 30;
  String _selectedCurrency = 'PYG';
  final List<ServiceModel> _createdServices = [];
  bool _isCreatingService = false;

  // ─── Step 2 state ──────────────────────────────────────
  final List<bool> _workDays = [true, true, true, true, true, false, false]; // L-D
  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 18, minute: 0);
  int _slotDurationMinutes = 30;
  bool _hasBreak = false;
  TimeOfDay _breakStart = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _breakEnd = const TimeOfDay(hour: 13, minute: 0);

  // ─── Step 3 state ──────────────────────────────────────
  bool _linkCopied = false;

  // ─── Duration chip data ────────────────────────────────
  static const List<Map<String, dynamic>> _durationOptions = [
    {'label': '15 min', 'value': 15},
    {'label': '30 min', 'value': 30},
    {'label': '45 min', 'value': 45},
    {'label': '1 hora', 'value': 60},
    {'label': '1:30 hs', 'value': 90},
    {'label': '2 horas', 'value': 120},
  ];

  static const List<String> _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const List<String> _dayFullLabels = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  // ─── Default services by category ──────────────────────
  static const Map<String, List<Map<String, dynamic>>> _defaultServicesByCategory = {
    'Peluqueria y Barberia': [
      {'name': 'Corte de cabello', 'duration': 30, 'price': 50000},
      {'name': 'Corte + Barba', 'duration': 45, 'price': 70000},
      {'name': 'Tenido completo', 'duration': 90, 'price': 150000},
      {'name': 'Mechas / Reflejos', 'duration': 120, 'price': 200000},
      {'name': 'Alisado', 'duration': 90, 'price': 180000},
      {'name': 'Barba', 'duration': 20, 'price': 30000},
      {'name': 'Lavado y secado', 'duration': 30, 'price': 40000},
      {'name': 'Tratamiento capilar', 'duration': 45, 'price': 80000},
    ],
    'Belleza y Estetica': [
      {'name': 'Limpieza facial', 'duration': 60, 'price': 90000},
      {'name': 'Depilacion facial', 'duration': 30, 'price': 35000},
      {'name': 'Depilacion corporal', 'duration': 60, 'price': 80000},
      {'name': 'Maquillaje profesional', 'duration': 60, 'price': 120000},
      {'name': 'Extension de pestanas', 'duration': 90, 'price': 150000},
      {'name': 'Diseno de cejas', 'duration': 30, 'price': 40000},
    ],
    'Spa y Masajes': [
      {'name': 'Masaje relajante', 'duration': 60, 'price': 120000},
      {'name': 'Masaje descontracturante', 'duration': 60, 'price': 140000},
      {'name': 'Masaje con piedras calientes', 'duration': 90, 'price': 180000},
      {'name': 'Reflexologia podal', 'duration': 45, 'price': 80000},
      {'name': 'Circuito spa completo', 'duration': 120, 'price': 300000},
      {'name': 'Drenaje linfatico', 'duration': 60, 'price': 150000},
    ],
    'Unas y Manicura': [
      {'name': 'Manicura clasica', 'duration': 45, 'price': 50000},
      {'name': 'Pedicura clasica', 'duration': 60, 'price': 60000},
      {'name': 'Manicura + Pedicura', 'duration': 90, 'price': 100000},
      {'name': 'Unas esculpidas', 'duration': 90, 'price': 150000},
      {'name': 'Gelificado', 'duration': 60, 'price': 80000},
      {'name': 'Kapping', 'duration': 45, 'price': 70000},
    ],
    'Tatuajes y Piercing': [
      {'name': 'Tatuaje pequeno (5-10 cm)', 'duration': 60, 'price': 200000},
      {'name': 'Tatuaje mediano (10-20 cm)', 'duration': 120, 'price': 500000},
      {'name': 'Tatuaje grande (20+ cm)', 'duration': 240, 'price': 1000000},
      {'name': 'Piercing simple', 'duration': 15, 'price': 80000},
      {'name': 'Cover up / Correccion', 'duration': 180, 'price': 800000},
      {'name': 'Consulta y diseno', 'duration': 30, 'price': 0},
    ],
    'Medicina General': [
      {'name': 'Consulta medica general', 'duration': 30, 'price': 150000},
      {'name': 'Control de seguimiento', 'duration': 20, 'price': 100000},
      {'name': 'Certificado medico', 'duration': 15, 'price': 80000},
      {'name': 'Chequeo preventivo', 'duration': 60, 'price': 350000},
      {'name': 'Ecografia', 'duration': 30, 'price': 200000},
    ],
    'Odontologia': [
      {'name': 'Limpieza dental', 'duration': 45, 'price': 150000},
      {'name': 'Consulta odontologica', 'duration': 30, 'price': 120000},
      {'name': 'Extraccion simple', 'duration': 45, 'price': 200000},
      {'name': 'Blanqueamiento dental', 'duration': 60, 'price': 500000},
      {'name': 'Empaste dental', 'duration': 30, 'price': 180000},
      {'name': 'Ortodoncia - Control', 'duration': 30, 'price': 100000},
    ],
    'Psicologia y Terapia': [
      {'name': 'Sesion individual', 'duration': 50, 'price': 150000},
      {'name': 'Terapia de pareja', 'duration': 60, 'price': 200000},
      {'name': 'Evaluacion psicologica', 'duration': 90, 'price': 250000},
      {'name': 'Sesion online', 'duration': 50, 'price': 120000},
      {'name': 'Terapia infantil', 'duration': 45, 'price': 150000},
    ],
    'Nutricion y Dietetica': [
      {'name': 'Consulta nutricional', 'duration': 45, 'price': 120000},
      {'name': 'Plan alimentario personalizado', 'duration': 60, 'price': 180000},
      {'name': 'Control de seguimiento', 'duration': 30, 'price': 80000},
      {'name': 'Analisis de composicion corporal', 'duration': 30, 'price': 100000},
      {'name': 'Nutricion deportiva', 'duration': 45, 'price': 150000},
    ],
    'Dermatologia': [
      {'name': 'Consulta dermatologica', 'duration': 30, 'price': 200000},
      {'name': 'Control de lunares', 'duration': 30, 'price': 150000},
      {'name': 'Tratamiento acne', 'duration': 45, 'price': 180000},
      {'name': 'Peeling quimico', 'duration': 45, 'price': 250000},
      {'name': 'Crioterapia', 'duration': 30, 'price': 120000},
    ],
    'Kinesiologia y Fisioterapia': [
      {'name': 'Sesion de fisioterapia', 'duration': 45, 'price': 120000},
      {'name': 'Rehabilitacion post-quirurgica', 'duration': 60, 'price': 150000},
      {'name': 'Fisioterapia deportiva', 'duration': 45, 'price': 130000},
      {'name': 'Evaluacion postural', 'duration': 30, 'price': 100000},
      {'name': 'Terapia manual', 'duration': 45, 'price': 120000},
    ],
    'Podologia': [
      {'name': 'Consulta podologica', 'duration': 30, 'price': 80000},
      {'name': 'Tratamiento una encarnada', 'duration': 45, 'price': 120000},
      {'name': 'Tratamiento de callos', 'duration': 30, 'price': 80000},
      {'name': 'Tratamiento de hongos', 'duration': 30, 'price': 100000},
      {'name': 'Cuidado pie diabetico', 'duration': 45, 'price': 150000},
    ],
    'Oftalmologia': [
      {'name': 'Control de vista', 'duration': 30, 'price': 150000},
      {'name': 'Receta de lentes', 'duration': 30, 'price': 120000},
      {'name': 'Fondo de ojo', 'duration': 30, 'price': 180000},
      {'name': 'Consulta pre-quirurgica laser', 'duration': 45, 'price': 200000},
      {'name': 'Control de glaucoma', 'duration': 30, 'price': 150000},
    ],
    'Veterinaria': [
      {'name': 'Consulta veterinaria', 'duration': 30, 'price': 100000},
      {'name': 'Vacunacion', 'duration': 20, 'price': 80000},
      {'name': 'Desparasitacion', 'duration': 15, 'price': 50000},
      {'name': 'Bano y peluqueria canina', 'duration': 60, 'price': 100000},
      {'name': 'Cirugia menor', 'duration': 90, 'price': 300000},
      {'name': 'Castracion / Esterilizacion', 'duration': 60, 'price': 400000},
    ],
    'Fitness y Gimnasio': [
      {'name': 'Clase de musculacion', 'duration': 60, 'price': 30000},
      {'name': 'Entrenamiento personal', 'duration': 60, 'price': 80000},
      {'name': 'Clase de crossfit', 'duration': 45, 'price': 40000},
      {'name': 'Evaluacion fisica', 'duration': 45, 'price': 60000},
      {'name': 'Clase grupal (spinning/funcional)', 'duration': 45, 'price': 35000},
    ],
    'Yoga y Pilates': [
      {'name': 'Clase de yoga', 'duration': 60, 'price': 50000},
      {'name': 'Clase de pilates', 'duration': 60, 'price': 50000},
      {'name': 'Meditacion guiada', 'duration': 45, 'price': 40000},
      {'name': 'Yoga prenatal', 'duration': 60, 'price': 60000},
      {'name': 'Clase privada', 'duration': 60, 'price': 100000},
    ],
    'Deportes y Canchas': [
      {'name': 'Cancha futbol 5 (1 hora)', 'duration': 60, 'price': 300000},
      {'name': 'Cancha futbol 7 (1 hora)', 'duration': 60, 'price': 450000},
      {'name': 'Cancha tenis (1 hora)', 'duration': 60, 'price': 150000},
      {'name': 'Cancha padel (1 hora)', 'duration': 60, 'price': 200000},
      {'name': 'Clase con profesor', 'duration': 60, 'price': 100000},
    ],
    'Restaurante y Cafe': [
      {'name': 'Mesa 2 personas', 'duration': 90, 'price': 0},
      {'name': 'Mesa 4 personas', 'duration': 90, 'price': 0},
      {'name': 'Mesa 6+ personas', 'duration': 120, 'price': 0},
      {'name': 'Sector VIP', 'duration': 120, 'price': 50000},
      {'name': 'Evento privado', 'duration': 180, 'price': 500000},
    ],
    'Bar y Cerveceria': [
      {'name': 'Mesa 4 personas', 'duration': 120, 'price': 0},
      {'name': 'Mesa 6+ personas', 'duration': 120, 'price': 0},
      {'name': 'Sector VIP / Terraza', 'duration': 120, 'price': 50000},
      {'name': 'After office grupal', 'duration': 180, 'price': 0},
    ],
    'Abogados y Notaria': [
      {'name': 'Consulta legal', 'duration': 45, 'price': 200000},
      {'name': 'Redaccion de contrato', 'duration': 60, 'price': 500000},
      {'name': 'Asesoria laboral', 'duration': 45, 'price': 200000},
      {'name': 'Escritura publica', 'duration': 60, 'price': 600000},
      {'name': 'Constitucion de empresa', 'duration': 60, 'price': 2000000},
    ],
    'Contabilidad y Finanzas': [
      {'name': 'Consulta contable', 'duration': 45, 'price': 150000},
      {'name': 'Declaracion de IVA', 'duration': 30, 'price': 200000},
      {'name': 'Balance mensual', 'duration': 60, 'price': 500000},
      {'name': 'Liquidacion de sueldos', 'duration': 45, 'price': 300000},
      {'name': 'Asesoria tributaria', 'duration': 60, 'price': 250000},
      {'name': 'Apertura de empresa (SET)', 'duration': 90, 'price': 800000},
    ],
    'Consultoria Empresarial': [
      {'name': 'Consultoria empresarial', 'duration': 60, 'price': 300000},
      {'name': 'Plan de negocios', 'duration': 90, 'price': 500000},
      {'name': 'Consultoria de marketing', 'duration': 60, 'price': 250000},
      {'name': 'Consultoria financiera', 'duration': 60, 'price': 300000},
      {'name': 'Mentoria 1 a 1', 'duration': 60, 'price': 200000},
    ],
    'Arquitectura y Diseno': [
      {'name': 'Consulta inicial', 'duration': 60, 'price': 200000},
      {'name': 'Diseno de interiores', 'duration': 90, 'price': 500000},
      {'name': 'Planos y proyecto', 'duration': 120, 'price': 1000000},
      {'name': 'Supervision de obra', 'duration': 60, 'price': 400000},
      {'name': 'Remodelacion - presupuesto', 'duration': 60, 'price': 0},
    ],
    'Inmobiliaria': [
      {'name': 'Tasacion de propiedad', 'duration': 60, 'price': 500000},
      {'name': 'Visita guiada', 'duration': 45, 'price': 0},
      {'name': 'Consulta de compra/venta', 'duration': 30, 'price': 0},
      {'name': 'Asesoria de inversion', 'duration': 60, 'price': 300000},
      {'name': 'Gestion de alquiler', 'duration': 45, 'price': 200000},
    ],
    'Fotografia y Video': [
      {'name': 'Sesion individual', 'duration': 60, 'price': 300000},
      {'name': 'Sesion de pareja', 'duration': 90, 'price': 450000},
      {'name': 'Sesion familiar', 'duration': 90, 'price': 500000},
      {'name': 'Fotos de producto', 'duration': 120, 'price': 400000},
      {'name': 'Cobertura de evento', 'duration': 240, 'price': 1500000},
      {'name': 'Video corporativo', 'duration': 180, 'price': 2000000},
    ],
    'Mecanica Automotriz': [
      {'name': 'Service basico', 'duration': 60, 'price': 350000},
      {'name': 'Service completo', 'duration': 120, 'price': 700000},
      {'name': 'Cambio de aceite', 'duration': 30, 'price': 200000},
      {'name': 'Alineacion y balanceo', 'duration': 45, 'price': 180000},
      {'name': 'Diagnostico computarizado', 'duration': 30, 'price': 150000},
      {'name': 'Cambio de frenos', 'duration': 90, 'price': 400000},
    ],
    'Lavadero de Autos': [
      {'name': 'Lavado exterior', 'duration': 30, 'price': 50000},
      {'name': 'Lavado completo', 'duration': 60, 'price': 80000},
      {'name': 'Lavado premium / detailing', 'duration': 120, 'price': 200000},
      {'name': 'Lavado camioneta/SUV', 'duration': 60, 'price': 100000},
      {'name': 'Lavado de tapizado', 'duration': 90, 'price': 150000},
    ],
    'Educacion y Tutorias': [
      {'name': 'Clase particular (1 hora)', 'duration': 60, 'price': 80000},
      {'name': 'Clase particular (2 horas)', 'duration': 120, 'price': 140000},
      {'name': 'Clase de idiomas', 'duration': 60, 'price': 100000},
      {'name': 'Preparacion de examen', 'duration': 90, 'price': 120000},
      {'name': 'Clase de musica', 'duration': 60, 'price': 100000},
    ],
    'Electronica y Reparacion': [
      {'name': 'Diagnostico de celular', 'duration': 30, 'price': 50000},
      {'name': 'Cambio de pantalla', 'duration': 60, 'price': 300000},
      {'name': 'Reparacion de notebook', 'duration': 60, 'price': 200000},
      {'name': 'Formateo + instalacion', 'duration': 90, 'price': 150000},
      {'name': 'Reparacion de electrodomesticos', 'duration': 60, 'price': 150000},
    ],
    'Limpieza y Mantenimiento': [
      {'name': 'Limpieza basica', 'duration': 120, 'price': 150000},
      {'name': 'Limpieza profunda', 'duration': 240, 'price': 300000},
      {'name': 'Limpieza de oficina', 'duration': 120, 'price': 200000},
      {'name': 'Limpieza post-obra', 'duration': 480, 'price': 600000},
      {'name': 'Fumigacion', 'duration': 60, 'price': 250000},
    ],
    'Eventos y Catering': [
      {'name': 'Consulta y presupuesto', 'duration': 60, 'price': 0},
      {'name': 'Catering 20 personas', 'duration': 180, 'price': 1500000},
      {'name': 'Catering 50 personas', 'duration': 240, 'price': 3500000},
      {'name': 'Decoracion de evento', 'duration': 120, 'price': 800000},
      {'name': 'Organizacion integral', 'duration': 120, 'price': 2000000},
    ],
    'Coworking y Oficinas': [
      {'name': 'Escritorio por hora', 'duration': 60, 'price': 30000},
      {'name': 'Escritorio por dia', 'duration': 480, 'price': 100000},
      {'name': 'Oficina privada (dia)', 'duration': 480, 'price': 250000},
      {'name': 'Sala de reuniones (1h)', 'duration': 60, 'price': 80000},
      {'name': 'Sala de conferencias (2h)', 'duration': 120, 'price': 200000},
    ],
  };

  @override
  void initState() {
    super.initState();
    // Pre-cargar nombre + rubro del negocio guardados en el registro,
    // así el usuario no tiene que volver a escribirlos.
    final meta = SupabaseConfig.client.auth.currentUser?.userMetadata;
    if (meta != null) {
      final savedName = meta['business_name'] as String?;
      if (savedName != null && savedName.trim().isNotEmpty) {
        _businessNameController.text = savedName.trim();
      }
      final savedCategoryId = meta['category_id'] as String?;
      if (savedCategoryId != null && savedCategoryId.trim().isNotEmpty) {
        _pendingCategoryId = savedCategoryId.trim();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _serviceNameController.dispose();
    _serviceDescController.dispose();
    _servicePriceController.dispose();
    super.dispose();
  }

  /// Aplica el rubro guardado en el registro una vez que cargaron las categorías.
  void _applyPendingCategory(List<BusinessCategory> categories) {
    if (_pendingCategoryId == null ||
        _selectedCategoryId != null ||
        categories.isEmpty) {
      return;
    }
    final pending = _pendingCategoryId!;
    BusinessCategory? match;
    for (final c in categories) {
      if (c.id == pending) {
        match = c;
        break;
      }
    }
    if (match != null) {
      final found = match;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pendingCategoryId = null;
        _selectCategory(found);
      });
    }
  }

  // ─── Navigation ────────────────────────────────────────

  void _goToNextStep() {
    // Step 0: must enter business name and select a category
    if (_currentStep == 0) {
      if (_businessNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresá el nombre de tu negocio')),
        );
        return;
      }
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná una categoría para continuar')),
        );
        return;
      }
    }

    // Step 1: must have at least one service
    if (_currentStep == 1 && _createdServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creá al menos un servicio para continuar')),
      );
      return;
    }

    // Step 2: validate schedule
    if (_currentStep == 2) {
      if (!_workDays.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná al menos un día de atención')),
        );
        return;
      }
      _saveSchedule();
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ─── Category selection ────────────────────────────────

  void _selectCategory(BusinessCategory category) {
    final business = ref.read(currentBusinessProvider);
    final businessId = business?.id ?? 'biz-onboarding';

    setState(() {
      _selectedCategoryId = category.id;

      // Clear previous auto-populated services
      _createdServices.clear();

      // Find matching default services by category name
      final defaults = normalizedLookup(_defaultServicesByCategory, category.name);
      if (defaults != null) {
        for (final svc in defaults) {
          _createdServices.add(ServiceModel(
            id: _uuid.v4(),
            businessId: businessId,
            name: svc['name'] as String,
            durationMinutes: svc['duration'] as int,
            price: (svc['price'] as int).toDouble(),
            currency: 'PYG',
          ));
        }
      }
    });

    // Also update the business categoryId
    if (business != null) {
      ref.invalidate(businessesProvider);
    }
  }

  // ─── Service creation ──────────────────────────────────

  Future<void> _createService() async {
    if (!_serviceFormKey.currentState!.validate()) return;

    setState(() => _isCreatingService = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final business = ref.read(currentBusinessProvider);
    final businessId = business?.id ?? 'biz-onboarding';

    final price = _servicePriceController.text.trim().isNotEmpty
        ? double.tryParse(_servicePriceController.text.trim())
        : null;

    final service = ServiceModel(
      id: _uuid.v4(),
      businessId: businessId,
      name: _serviceNameController.text.trim(),
      description: _serviceDescController.text.trim().isNotEmpty
          ? _serviceDescController.text.trim()
          : null,
      durationMinutes: _selectedDuration,
      price: price,
      currency: _selectedCurrency,
    );

    setState(() {
      _createdServices.add(service);
      _isCreatingService = false;
      _serviceNameController.clear();
      _serviceDescController.clear();
      _servicePriceController.clear();
      _selectedDuration = 30;
      _selectedCurrency = 'PYG';
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSizes.s8),
            Expanded(child: Text('¡${service.name} creado!')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
      ),
    );
  }

  // ─── Schedule save ─────────────────────────────────────

  void _saveSchedule() {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    // Business configuration is updated when finalized.
    ref.invalidate(businessesProvider);
  }

  // ─── Time picking ──────────────────────────────────────

  Future<void> _pickTime({
    required bool isOpening,
    bool isBreakStart = false,
    bool isBreakEnd = false,
  }) async {
    TimeOfDay initial;
    if (isBreakStart) {
      initial = _breakStart;
    } else if (isBreakEnd) {
      initial = _breakEnd;
    } else {
      initial = isOpening ? _openingTime : _closingTime;
    }

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        if (isBreakStart) {
          _breakStart = picked;
        } else if (isBreakEnd) {
          _breakEnd = picked;
        } else if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  // ─── Copy link ─────────────────────────────────────────

  void _copyLink() {
    final business = ref.read(currentBusinessProvider);
    final slug = (business?.name ?? 'tu-negocio')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    Clipboard.setData(ClipboardData(text: 'https://reservpy.com.py/$slug'));
    setState(() => _linkCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 20),
            SizedBox(width: AppSizes.s8),
            Text('¡Link copiado al portapapeles!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  // ─── Navigate to dashboard ─────────────────────────────

  Future<void> _goToDashboard() async {
    // Use Supabase auth directly — owner_id MUST match auth.uid()
    final authUser = SupabaseConfig.client.auth.currentUser;
    if (authUser == null) {
      if (mounted) context.go('/login');
      return;
    }

    final user = ref.read(currentUserProvider);

    try {
      final businessName = _businessNameController.text.trim().isNotEmpty
          ? _businessNameController.text.trim()
          : '${user?.firstName ?? 'Mi'} Business';

      // ¿Ya existe un negocio de este dueño? (creado en el registro)
      // Si existe, lo ACTUALIZAMOS en vez de crear uno nuevo (evita duplicados).
      final existing = await _businessRepo.getByOwner(authUser.id);
      final Business created;
      if (existing.isNotEmpty) {
        final biz = existing.first;
        created = biz.copyWith(
          categoryId: _selectedCategoryId ?? biz.categoryId,
          name: businessName,
          openingTime: _openingTime,
          closingTime: _closingTime,
          slotDurationMinutes: _slotDurationMinutes,
        );
        await _businessRepo.update(created);
      } else {
        created = await _businessRepo.create(Business(
          id: '',
          ownerId: authUser.id, // auth.uid() — never from provider
          categoryId: _selectedCategoryId ?? '',
          name: businessName,
          openingTime: _openingTime,
          closingTime: _closingTime,
          slotDurationMinutes: _slotDurationMinutes,
          createdAt: DateTime.now(),
        ));
      }

      // ── Persist services to Supabase ──
      final serviceRepo = ServiceRepository();
      for (final svc in _createdServices) {
        await serviceRepo.create(ServiceModel(
          id: '',
          businessId: created.id,
          name: svc.name,
          description: svc.description,
          durationMinutes: svc.durationMinutes,
          price: svc.price,
          currency: svc.currency,
        ));
      }

      // Invalidate providers so BusinessShell refetches from Supabase
      ref.invalidate(businessesProvider);
      ref.invalidate(ownerBusinessProvider);

      if (!mounted) return;
      context.go('/business');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear negocio: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ─── Helpers ───────────────────────────────────────────

  String _formatTimeOfDay(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  String _businessSlug() {
    final business = ref.read(currentBusinessProvider);
    return (business?.name ?? 'tu-negocio')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  // ─── BUILD ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Banner ──────────────────────────────────
            _OnboardingBanner(currentStep: _currentStep),

            // ─── Step Indicator ──────────────────────────────
            _StepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
            ),

            const SizedBox(height: AppSizes.s8),

            // ─── Page Content ────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0(theme, colorScheme),
                  _buildStep1(theme, colorScheme),
                  _buildStep2(theme, colorScheme),
                  _buildStep3(theme, colorScheme),
                ],
              ),
            ),

            // ─── Bottom Navigation ───────────────────────────
            _buildBottomNav(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // STEP 0: Seleccionar Categoría
  // ════════════════════════════════════════════════════════

  Widget _buildStep0(ThemeData theme, ColorScheme colorScheme) {
    final rawCategories = ref.watch(categoriesProvider).value ?? [];
    final categories = [...rawCategories]..sort((a, b) {
      if (a.name == 'Otros') return 1;
      if (b.name == 'Otros') return -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    // Aplicar el rubro guardado en el registro (pre-carga automática)
    _applyPendingCategory(categories);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  size: 28,
                  color: AppColors.accent,
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // Title
              Text(
                '¿Qué tipo de negocio tenés?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSizes.s6),

              // Subtitle
              Text(
                'Elegí la categoría que mejor describa tu negocio. '
                'Te vamos a sugerir servicios populares para empezar rápido.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.s24),

              // Business name field
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
                child: AppTextField(
                  controller: _businessNameController,
                  label: 'Nombre de tu negocio *',
                  hint: 'Ej: Peluquería Style, Consultorio Dr. López...',
                  prefixIcon: Icons.store_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: AppSizes.s24),

              // ─── Category Grid ───────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSizes.s12,
                      mainAxisSpacing: AppSizes.s12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategoryId == cat.id;

                      return GestureDetector(
                        onTap: () => _selectCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.08)
                                : theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.success
                                  : colorScheme.outline.withValues(alpha: 0.15),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Category icon container
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: isSelected ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                ),
                                child: Icon(
                                  cat.icon,
                                  size: 26,
                                  color: cat.color,
                                ),
                              ),
                              const SizedBox(height: AppSizes.s8),
                              // Category name
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
                                child: Text(
                                  cat.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Selected check
                              if (isSelected) ...[
                                const SizedBox(height: AppSizes.s4),
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: AppSizes.s16),

              // Selected category feedback
              if (_selectedCategoryId != null) ...[
                Builder(builder: (context) {
                  final selectedCat = categories.firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => categories.first,
                  );
                  final defaultCount = _defaultServicesByCategory[selectedCat.name]?.length ?? 0;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.s16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.06),
                          AppColors.success.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSizes.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedCat.name} seleccionado',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSizes.s2),
                              Text(
                                defaultCount > 0
                                    ? 'Te sugerimos $defaultCount servicios populares'
                                    : 'Podrás agregar tus servicios en el siguiente paso',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // STEP 1: Crear Servicios
  // ════════════════════════════════════════════════════════

  Widget _buildStep1(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // Title
              Text(
                'Configurá tus servicios',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSizes.s6),

              // Subtitle
              Text(
                'Te sugerimos servicios populares para tu categoría. '
                'Podés eliminar los que no necesites o agregar nuevos.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.s24),

              // ─── Created Services (show first if auto-populated) ───
              if (_createdServices.isNotEmpty) ...[
                SectionHeader(
                  title: 'Servicios (${_createdServices.length})',
                ),
                const SizedBox(height: AppSizes.s4),
                ..._createdServices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final svc = entry.value;
                  return _CreatedServiceCard(
                    service: svc,
                    index: index,
                    onDelete: () {
                      setState(() => _createdServices.removeAt(index));
                    },
                  );
                }),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'Podés eliminar los que no necesites o agregar más abajo.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
                const SizedBox(height: AppSizes.s16),
              ],

              // ─── Add New Service Section ─────────────────────
              Text(
                'Agregar servicio personalizado',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.s12),

              // ─── Service Form ───────────────────────────────
              Form(
                key: _serviceFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    AppTextField(
                      controller: _serviceNameController,
                      label: 'Nombre del servicio *',
                      hint: 'Ej: Corte de cabello',
                      prefixIcon: Icons.design_services_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizes.s16),

                    // Description
                    AppTextField(
                      controller: _serviceDescController,
                      label: 'Descripción (opcional)',
                      hint: 'Describí brevemente el servicio...',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 2,
                    ),

                    const SizedBox(height: AppSizes.s20),

                    // Duration chips
                    Text(
                      'Duración *',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Wrap(
                      spacing: AppSizes.s8,
                      runSpacing: AppSizes.s8,
                      children: _durationOptions.map((opt) {
                        final isSelected = _selectedDuration == opt['value'];
                        return ChoiceChip(
                          label: Text(opt['label'] as String),
                          selected: isSelected,
                          onSelected: (_) => setState(
                            () => _selectedDuration = opt['value'] as int,
                          ),
                          selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSizes.s20),

                    // Price & Currency row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            controller: _servicePriceController,
                            label: 'Precio',
                            hint: '50000',
                            prefixIcon: Icons.attach_money_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSizes.s12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCurrency,
                            decoration: InputDecoration(
                              labelText: 'Moneda',
                              prefixIcon: const Icon(Icons.currency_exchange_rounded, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PYG', child: Text('PYG')),
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCurrency = v);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.s24),

                    // Create button
                    AppButton(
                      label: '+ Crear servicio',
                      icon: Icons.add_rounded,
                      isLoading: _isCreatingService,
                      onPressed: _isCreatingService ? null : _createService,
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // STEP 2: Definir Horarios
  // ════════════════════════════════════════════════════════

  Widget _buildStep2(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 28,
                  color: AppColors.info,
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // Title
              Text(
                'Definí tus horarios de atención',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSizes.s6),

              Text(
                'Configurá los días y horarios en los que atendés',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: AppSizes.s24),

              // ─── Work Days Toggles ──────────────────────────
              Text(
                'Días de atención',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.s12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final isActive = _workDays[i];
                  return GestureDetector(
                    onTap: () => setState(() => _workDays[i] = !_workDays[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSizes.s24),

              // ─── Time Pickers ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Apertura',
                      time: _formatTimeOfDay(_openingTime),
                      icon: Icons.wb_sunny_rounded,
                      onTap: () => _pickTime(isOpening: true),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: _TimePickerTile(
                      label: 'Cierre',
                      time: _formatTimeOfDay(_closingTime),
                      icon: Icons.nights_stay_rounded,
                      onTap: () => _pickTime(isOpening: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.s20),

              // ─── Slot Duration ──────────────────────────────
              Text(
                'Duración de turnos',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.s8),
              DropdownButtonFormField<int>(
                initialValue: _slotDurationMinutes,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 minutos')),
                  DropdownMenuItem(value: 30, child: Text('30 minutos')),
                  DropdownMenuItem(value: 45, child: Text('45 minutos')),
                  DropdownMenuItem(value: 60, child: Text('60 minutos')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _slotDurationMinutes = v);
                },
              ),

              const SizedBox(height: AppSizes.s20),

              // ─── Break Time ─────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.s16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.free_breakfast_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSizes.s8),
                        Expanded(
                          child: Text(
                            'Horario de descanso',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Switch(
                          value: _hasBreak,
                          onChanged: (v) => setState(() => _hasBreak = v),
                          activeThumbColor: colorScheme.primary,
                        ),
                      ],
                    ),
                    if (_hasBreak) ...[
                      const SizedBox(height: AppSizes.s12),
                      Row(
                        children: [
                          Expanded(
                            child: _TimePickerTile(
                              label: 'Inicio',
                              time: _formatTimeOfDay(_breakStart),
                              icon: Icons.pause_circle_outline_rounded,
                              onTap: () => _pickTime(
                                isOpening: false,
                                isBreakStart: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.s12),
                          Expanded(
                            child: _TimePickerTile(
                              label: 'Fin',
                              time: _formatTimeOfDay(_breakEnd),
                              icon: Icons.play_circle_outline_rounded,
                              onTap: () => _pickTime(
                                isOpening: false,
                                isBreakEnd: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.s24),

              // ─── Schedule Preview ───────────────────────────
              _SchedulePreviewCard(
                workDays: _workDays,
                dayFullLabels: _dayFullLabels,
                openingTime: _formatTimeOfDay(_openingTime),
                closingTime: _formatTimeOfDay(_closingTime),
                slotDuration: _slotDurationMinutes,
                hasBreak: _hasBreak,
                breakStart: _formatTimeOfDay(_breakStart),
                breakEnd: _formatTimeOfDay(_breakEnd),
              ),

              const SizedBox(height: AppSizes.s32),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // STEP 3: Compartir Link
  // ════════════════════════════════════════════════════════

  Widget _buildStep3(ThemeData theme, ColorScheme colorScheme) {
    final slug = _businessSlug();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.s16),

              // ─── Celebration ─────────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.2),
                          colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.celebration_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.s24),

              // Confetti-like particles
              SizedBox(
                height: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final icons = [
                      Icons.star_rounded,
                      Icons.auto_awesome,
                      Icons.star_rounded,
                      Icons.auto_awesome,
                      Icons.star_rounded,
                    ];
                    final colors = [
                      AppColors.primary,
                      AppColors.warning,
                      AppColors.info,
                      AppColors.success,
                      AppColors.primary,
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s8),
                      child: Icon(icons[i], size: 18, color: colors[i]),
                    );
                  }),
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // Title
              Text(
                '¡Tu negocio está listo!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.s8),

              Text(
                'Compartí tu link para empezar a recibir reservas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.s32),

              // ─── Link Card ──────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.s20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Icon(
                            Icons.link_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tu link de reservas',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: AppSizes.s2),
                              Text(
                                'reservpy.com.py/$slug',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _copyLink,
                          icon: Icon(
                            _linkCopied ? Icons.check_rounded : Icons.copy_rounded,
                            color: _linkCopied ? AppColors.success : colorScheme.primary,
                          ),
                          tooltip: 'Copiar link',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // ─── Share Buttons ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF20A482),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Compartir por WhatsApp (próximamente)')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.copy_rounded,
                      label: 'Copiar',
                      color: AppColors.info,
                      onTap: _copyLink,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.share_rounded,
                      label: 'Compartir',
                      color: AppColors.accent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Compartir (próximamente)')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.s24),

              // ─── QR Placeholder ─────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppSizes.s24),
                child: Column(
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 80,
                            color: colorScheme.onSurface.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: AppSizes.s4),
                          Text(
                            'Código QR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s12),
                    Text(
                      'Imprimí este código y colocalo en tu local',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.s24),

              // ─── Plan Summary ───────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.s16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.06),
                      colorScheme.primary.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu plan: Gratis',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSizes.s2),
                          Text(
                            '10 turnos/mes · ${_createdServices.length} servicio${_createdServices.length != 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: 'GRATIS',
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.s32),

              // ─── CTA Button ─────────────────────────────────
              AppButton(
                label: 'Ir al panel de control →',
                icon: Icons.dashboard_rounded,
                onPressed: _goToDashboard,
              ),

              const SizedBox(height: AppSizes.s24),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Bottom navigation bar
  // ════════════════════════════════════════════════════════

  Widget _buildBottomNav(ThemeData theme, ColorScheme colorScheme) {
    // Hide on step 3 — CTA is inline
    if (_currentStep == 3) return const SizedBox.shrink();

    final bool canProceed;
    if (_currentStep == 0) {
      canProceed = _selectedCategoryId != null;
    } else if (_currentStep == 1) {
      canProceed = _createdServices.isNotEmpty;
    } else {
      canProceed = true;
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                label: '← Anterior',
                icon: Icons.arrow_back_rounded,
                isOutlined: true,
                onPressed: _goToPreviousStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppSizes.s12),
          Expanded(
            child: AppButton(
              label: 'Siguiente →',
              icon: Icons.arrow_forward_rounded,
              onPressed: canProceed ? _goToNextStep : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ══════════════════════════════════════════════════════════

/// Top gradient banner with onboarding title and subtitle.
class _OnboardingBanner extends StatelessWidget {
  final int currentStep;

  const _OnboardingBanner({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s24,
        AppSizes.s20,
        AppSizes.s24,
        AppSizes.s16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accent.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurá tu negocio',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            '4 pasos rápidos para empezar a recibir reservas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step indicator with numbered circles and connecting lines.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  static const List<String> _stepLabels = [
    'Categoría',
    'Servicios',
    'Horarios',
    'Compartir',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s24,
        vertical: AppSizes.s16,
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          // Odd indices are connecting lines
          if (i.isOdd) {
            final stepBefore = i ~/ 2;
            final isComplete = stepBefore < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isComplete
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          // Even indices are step circles
          final stepIndex = i ~/ 2;
          final isActive = stepIndex == currentStep;
          final isComplete = stepIndex < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete
                      ? colorScheme.primary
                      : isActive
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.15),
                  border: isActive && !isComplete
                      ? Border.all(color: colorScheme.primary, width: 2.5)
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isComplete
                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.s4),
              Text(
                _stepLabels[stepIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive || isComplete
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Card showing a created service with delete action.
class _CreatedServiceCard extends StatelessWidget {
  final ServiceModel service;
  final int index;
  final VoidCallback onDelete;

  const _CreatedServiceCard({
    required this.service,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.s8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              Icons.design_services_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.s2),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: colorScheme.outline),
                    const SizedBox(width: AppSizes.s4),
                    Text(
                      service.formattedDuration,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: AppSizes.s12),
                    Icon(Icons.attach_money_rounded, size: 14, color: colorScheme.outline),
                    const SizedBox(width: AppSizes.s2),
                    Text(
                      service.formattedPrice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                if (service.description != null && service.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    service.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: colorScheme.error,
            ),
            onPressed: onDelete,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

/// Time picker tile for opening/closing/break times.
class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: AppSizes.s6),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              time,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview card showing the configured schedule.
class _SchedulePreviewCard extends StatelessWidget {
  final List<bool> workDays;
  final List<String> dayFullLabels;
  final String openingTime;
  final String closingTime;
  final int slotDuration;
  final bool hasBreak;
  final String breakStart;
  final String breakEnd;

  const _SchedulePreviewCard({
    required this.workDays,
    required this.dayFullLabels,
    required this.openingTime,
    required this.closingTime,
    required this.slotDuration,
    required this.hasBreak,
    required this.breakStart,
    required this.breakEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeDays = <String>[];
    for (int i = 0; i < workDays.length; i++) {
      if (workDays[i]) activeDays.add(dayFullLabels[i]);
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSizes.s8),
              Text(
                'Vista previa del horario',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),

          // Days
          _PreviewRow(
            icon: Icons.calendar_today_rounded,
            label: 'Días',
            value: activeDays.isEmpty ? 'Sin días' : activeDays.join(', '),
          ),
          const SizedBox(height: AppSizes.s12),

          // Hours
          _PreviewRow(
            icon: Icons.access_time_rounded,
            label: 'Horario',
            value: '$openingTime – $closingTime',
          ),
          const SizedBox(height: AppSizes.s12),

          // Slot
          _PreviewRow(
            icon: Icons.timer_outlined,
            label: 'Turnos de',
            value: '$slotDuration min',
          ),

          if (hasBreak) ...[
            const SizedBox(height: AppSizes.s12),
            _PreviewRow(
              icon: Icons.free_breakfast_rounded,
              label: 'Descanso',
              value: '$breakStart – $breakEnd',
            ),
          ],

          const SizedBox(height: AppSizes.s16),
          Divider(color: colorScheme.outline.withValues(alpha: 0.15)),
          const SizedBox(height: AppSizes.s8),

          // Slots count
          Builder(
            builder: (context) {
              // Parse times to compute slot count
              final openParts = openingTime.split(':');
              final closeParts = closingTime.split(':');
              final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
              final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
              var availableMin = closeMin - openMin;

              if (hasBreak) {
                final bsParts = breakStart.split(':');
                final beParts = breakEnd.split(':');
                final bsMin = int.parse(bsParts[0]) * 60 + int.parse(bsParts[1]);
                final beMin = int.parse(beParts[0]) * 60 + int.parse(beParts[1]);
                availableMin -= (beMin - bsMin);
              }

              final slotsPerDay = availableMin > 0 ? (availableMin / slotDuration).floor() : 0;
              final daysPerWeek = workDays.where((d) => d).length;

              return Row(
                children: [
                  StatusBadge(
                    label: '$slotsPerDay turnos/día',
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  StatusBadge(
                    label: '${slotsPerDay * daysPerWeek} turnos/semana',
                    color: AppColors.info,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Single row in the schedule preview.
class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.outline),
        const SizedBox(width: AppSizes.s8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Share action button (WhatsApp, copy, share).
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.s12,
          horizontal: AppSizes.s8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: AppSizes.s4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
