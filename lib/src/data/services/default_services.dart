import 'package:reservpy/src/shared/models/models.dart';
import 'package:reservpy/src/core/utils/string_utils.dart';

/// Servicios sugeridos por defecto para cada rubro (con duración en minutos y
/// precio en guaraníes). Se usan tanto en el registro (al crear el negocio)
/// como en el asistente de configuración.
const Map<String, List<Map<String, dynamic>>> kDefaultServicesByCategory = {
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

/// Devuelve los servicios sugeridos (como ServiceModel) para un rubro dado.
/// Si el rubro no tiene servicios por defecto, devuelve una lista vacía.
List<ServiceModel> defaultServicesForCategory(
  String categoryName,
  String businessId,
) {
  final defaults = normalizedLookup(kDefaultServicesByCategory, categoryName);
  if (defaults == null) return [];
  return defaults
      .map((svc) => ServiceModel(
            id: '',
            businessId: businessId,
            name: svc['name'] as String,
            durationMinutes: svc['duration'] as int,
            price: (svc['price'] as int).toDouble(),
            currency: 'PYG',
          ))
      .toList();
}
