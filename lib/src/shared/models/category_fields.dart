/// Dynamic form fields per business category.
///
/// When a client makes a reservation, additional fields are shown
/// based on the business's category. For example, a vet asks for
/// pet name and breed, while a mechanic asks for vehicle plate.
library;

import 'package:reservpy/src/core/utils/string_utils.dart';

/// Field type enum used to render the correct input widget.
enum CategoryFieldType {
  text,      // free-form text input
  number,    // numeric input
  select,    // dropdown / chip selector
  multiSelect, // multiple choice chips
  toggle,    // yes/no switch
  date,      // date picker
  textarea,  // long text
  phone,     // phone input
}

/// Describes a single form field for a category.
class CategoryField {
  final String key;           // unique key for storage (e.g., 'pet_name')
  final String label;         // display label (e.g., 'Nombre de la mascota')
  final CategoryFieldType type;
  final bool required;
  final String? hint;         // placeholder hint
  final List<String>? options; // for select/multiSelect types
  final String? defaultValue;

  const CategoryField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.hint,
    this.options,
    this.defaultValue,
  });
}

/// Master map of category name → form fields.
/// Keys MUST match the category names in Supabase exactly.
const Map<String, List<CategoryField>> categoryFormFields = {

  // ═══════════════════════════════════════════════════════════════
  // BELLEZA Y CUIDADO PERSONAL
  // ═══════════════════════════════════════════════════════════════

  'Peluqueria y Barberia': [
    CategoryField(key: 'hair_type', label: 'Tipo de cabello', type: CategoryFieldType.select, options: ['Liso', 'Ondulado', 'Rizado', 'Crespo'], hint: 'Selecciona tu tipo de cabello'),
    CategoryField(key: 'hair_length', label: 'Largo del cabello', type: CategoryFieldType.select, options: ['Corto', 'Medio', 'Largo', 'Muy largo']),
    CategoryField(key: 'service_detail', label: 'Estilo o corte deseado', type: CategoryFieldType.textarea, hint: 'Describi el corte o estilo que buscas'),
    CategoryField(key: 'allergies', label: 'Alergias a productos', type: CategoryFieldType.text, hint: 'Ej: tintes, amoniaco...'),
  ],

  'Belleza y Estetica': [
    CategoryField(key: 'skin_type', label: 'Tipo de piel', type: CategoryFieldType.select, options: ['Normal', 'Seca', 'Grasa', 'Mixta', 'Sensible']),
    CategoryField(key: 'treatment_area', label: 'Zona a tratar', type: CategoryFieldType.multiSelect, options: ['Rostro', 'Manos', 'Pies', 'Piernas', 'Cuerpo completo']),
    CategoryField(key: 'allergies', label: 'Alergias conocidas', type: CategoryFieldType.text, hint: 'Ej: latex, esmaltes, fragancias...'),
    CategoryField(key: 'first_time', label: 'Primera vez en este servicio?', type: CategoryFieldType.toggle, defaultValue: 'false'),
  ],

  'Spa y Masajes': [
    CategoryField(key: 'massage_type', label: 'Tipo de masaje preferido', type: CategoryFieldType.select, options: ['Relajante', 'Descontracturante', 'Deportivo', 'Piedras calientes', 'Reflexologia', 'Sin preferencia']),
    CategoryField(key: 'pressure', label: 'Presion preferida', type: CategoryFieldType.select, options: ['Suave', 'Media', 'Firme', 'Sin preferencia']),
    CategoryField(key: 'focus_area', label: 'Zonas de tension', type: CategoryFieldType.multiSelect, options: ['Cuello', 'Espalda alta', 'Espalda baja', 'Hombros', 'Piernas', 'Pies', 'Cuerpo completo']),
    CategoryField(key: 'conditions', label: 'Condiciones medicas', type: CategoryFieldType.text, hint: 'Ej: embarazo, cirugia reciente...'),
    CategoryField(key: 'gender_preference', label: 'Preferencia de terapeuta', type: CategoryFieldType.select, options: ['Sin preferencia', 'Femenino', 'Masculino']),
  ],

  'Unas y Manicura': [
    CategoryField(key: 'service_type', label: 'Tipo de servicio', type: CategoryFieldType.select, required: true, options: ['Manicura', 'Pedicura', 'Manicura + Pedicura', 'Unas esculpidas', 'Gelificado', 'Kapping']),
    CategoryField(key: 'nail_shape', label: 'Forma de una deseada', type: CategoryFieldType.select, options: ['Cuadrada', 'Ovalada', 'Almendra', 'Coffin', 'Stiletto', 'Sin preferencia']),
    CategoryField(key: 'design', label: 'Diseno deseado', type: CategoryFieldType.textarea, hint: 'Describi el diseno, color o estilo que queres'),
    CategoryField(key: 'allergies', label: 'Alergias a productos', type: CategoryFieldType.text, hint: 'Ej: acrilico, acetona...'),
  ],

  'Tatuajes y Piercing': [
    CategoryField(key: 'type', label: 'Tipo de trabajo', type: CategoryFieldType.select, required: true, options: ['Tatuaje nuevo', 'Cover up', 'Retoque', 'Piercing']),
    CategoryField(key: 'body_area', label: 'Zona del cuerpo', type: CategoryFieldType.text, required: true, hint: 'Ej: antebrazo derecho, lobulo...'),
    CategoryField(key: 'size', label: 'Tamano aproximado (cm)', type: CategoryFieldType.text, hint: 'Ej: 10x15 cm'),
    CategoryField(key: 'style', label: 'Estilo', type: CategoryFieldType.select, options: ['Realismo', 'Traditional', 'Blackwork', 'Minimalista', 'Acuarela', 'Geometrico', 'Lettering', 'Otro']),
    CategoryField(key: 'reference', label: 'Descripcion o referencia', type: CategoryFieldType.textarea, hint: 'Describi el diseno que queres'),
    CategoryField(key: 'first_tattoo', label: 'Es tu primer tatuaje?', type: CategoryFieldType.toggle, defaultValue: 'false'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // SALUD
  // ═══════════════════════════════════════════════════════════════

  'Medicina General': [
    CategoryField(key: 'reason', label: 'Motivo de consulta', type: CategoryFieldType.textarea, required: true, hint: 'Describi brevemente el motivo de tu consulta'),
    CategoryField(key: 'symptoms', label: 'Sintomas actuales', type: CategoryFieldType.textarea, hint: 'Lista los sintomas que presentas'),
    CategoryField(key: 'medications', label: 'Medicamentos actuales', type: CategoryFieldType.text, hint: 'Ej: Ibuprofeno 400mg'),
    CategoryField(key: 'insurance', label: 'Obra social / Seguro', type: CategoryFieldType.text, hint: 'Nombre de tu cobertura medica'),
    CategoryField(key: 'blood_type', label: 'Grupo sanguineo', type: CategoryFieldType.select, options: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'No se']),
  ],

  'Odontologia': [
    CategoryField(key: 'reason', label: 'Motivo de consulta', type: CategoryFieldType.textarea, required: true, hint: 'Ej: dolor de muela, limpieza, control...'),
    CategoryField(key: 'pain_level', label: 'Nivel de dolor', type: CategoryFieldType.select, options: ['Sin dolor', 'Leve', 'Moderado', 'Intenso', 'Insoportable']),
    CategoryField(key: 'last_visit', label: 'Ultima visita al dentista', type: CategoryFieldType.select, options: ['Menos de 6 meses', '6-12 meses', '1-2 anos', 'Mas de 2 anos']),
    CategoryField(key: 'insurance', label: 'Obra social / Seguro dental', type: CategoryFieldType.text, hint: 'Nombre de tu cobertura'),
    CategoryField(key: 'allergies', label: 'Alergias a anestesia', type: CategoryFieldType.toggle, defaultValue: 'false'),
  ],

  'Psicologia y Terapia': [
    CategoryField(key: 'session_type', label: 'Tipo de sesion', type: CategoryFieldType.select, required: true, options: ['Individual', 'Pareja', 'Familiar', 'Infantil']),
    CategoryField(key: 'modality', label: 'Modalidad preferida', type: CategoryFieldType.select, options: ['Presencial', 'Online', 'Sin preferencia']),
    CategoryField(key: 'reason', label: 'Motivo de consulta (opcional)', type: CategoryFieldType.textarea, hint: 'Breve descripcion de lo que te gustaria trabajar'),
    CategoryField(key: 'previous_therapy', label: 'Terapia previa?', type: CategoryFieldType.toggle, defaultValue: 'false'),
  ],

  'Nutricion y Dietetica': [
    CategoryField(key: 'goal', label: 'Objetivo', type: CategoryFieldType.select, required: true, options: ['Bajar de peso', 'Subir de peso', 'Mantener peso', 'Ganar masa muscular', 'Alimentacion saludable', 'Patologia especifica']),
    CategoryField(key: 'restrictions', label: 'Restricciones alimentarias', type: CategoryFieldType.multiSelect, options: ['Sin gluten', 'Sin lactosa', 'Vegetariano', 'Vegano', 'Kosher', 'Sin restricciones']),
    CategoryField(key: 'weight', label: 'Peso actual (kg)', type: CategoryFieldType.number, hint: 'Ej: 72'),
    CategoryField(key: 'height', label: 'Altura (cm)', type: CategoryFieldType.number, hint: 'Ej: 170'),
    CategoryField(key: 'conditions', label: 'Condiciones medicas', type: CategoryFieldType.text, hint: 'Ej: diabetes, hipertension...'),
  ],

  'Dermatologia': [
    CategoryField(key: 'reason', label: 'Motivo de consulta', type: CategoryFieldType.textarea, required: true, hint: 'Ej: acne, manchas, control de lunares...'),
    CategoryField(key: 'skin_type', label: 'Tipo de piel', type: CategoryFieldType.select, options: ['Normal', 'Seca', 'Grasa', 'Mixta', 'Sensible']),
    CategoryField(key: 'affected_area', label: 'Zona afectada', type: CategoryFieldType.multiSelect, options: ['Rostro', 'Cuello', 'Espalda', 'Brazos', 'Piernas', 'Cuerpo completo']),
    CategoryField(key: 'current_treatment', label: 'Tratamiento actual', type: CategoryFieldType.text, hint: 'Cremas o medicamentos que uses'),
    CategoryField(key: 'insurance', label: 'Obra social / Seguro', type: CategoryFieldType.text, hint: 'Nombre de tu cobertura'),
  ],

  'Kinesiologia y Fisioterapia': [
    CategoryField(key: 'reason', label: 'Motivo de consulta', type: CategoryFieldType.textarea, required: true, hint: 'Ej: dolor lumbar, rehabilitacion post-cirugia...'),
    CategoryField(key: 'injury_area', label: 'Zona afectada', type: CategoryFieldType.multiSelect, options: ['Cuello', 'Hombro', 'Espalda', 'Cadera', 'Rodilla', 'Tobillo', 'Otro']),
    CategoryField(key: 'origin', label: 'Origen de la lesion', type: CategoryFieldType.select, options: ['Deportiva', 'Laboral', 'Accidente', 'Post-quirurgica', 'Cronica', 'No se']),
    CategoryField(key: 'medical_order', label: 'Tenes orden medica?', type: CategoryFieldType.toggle, defaultValue: 'false'),
    CategoryField(key: 'insurance', label: 'Obra social / Seguro', type: CategoryFieldType.text, hint: 'Nombre de tu cobertura'),
  ],

  'Podologia': [
    CategoryField(key: 'reason', label: 'Motivo de consulta', type: CategoryFieldType.select, required: true, options: ['Una encarnada', 'Callos', 'Hongos', 'Pie diabetico', 'Control general', 'Otro']),
    CategoryField(key: 'affected_foot', label: 'Pie afectado', type: CategoryFieldType.select, options: ['Izquierdo', 'Derecho', 'Ambos']),
    CategoryField(key: 'diabetes', label: 'Tenes diabetes?', type: CategoryFieldType.toggle, defaultValue: 'false'),
    CategoryField(key: 'details', label: 'Detalles adicionales', type: CategoryFieldType.textarea, hint: 'Describi tu situacion'),
  ],

  'Oftalmologia': [
    CategoryField(key: 'reason', label: 'Motivo de consulta', type: CategoryFieldType.select, required: true, options: ['Control de vista', 'Receta de lentes', 'Ojo rojo / irritacion', 'Dolor ocular', 'Cirugia laser', 'Otro']),
    CategoryField(key: 'uses_glasses', label: 'Usas lentes?', type: CategoryFieldType.toggle, defaultValue: 'false'),
    CategoryField(key: 'last_checkup', label: 'Ultimo control oftalmologico', type: CategoryFieldType.select, options: ['Menos de 1 ano', '1-2 anos', 'Mas de 2 anos', 'Nunca']),
    CategoryField(key: 'insurance', label: 'Obra social / Seguro', type: CategoryFieldType.text, hint: 'Nombre de tu cobertura'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // ANIMALES
  // ═══════════════════════════════════════════════════════════════

  'Veterinaria': [
    CategoryField(key: 'pet_name', label: 'Nombre de la mascota', type: CategoryFieldType.text, required: true, hint: 'Ej: Rocky'),
    CategoryField(key: 'pet_type', label: 'Tipo de animal', type: CategoryFieldType.select, required: true, options: ['Perro', 'Gato', 'Ave', 'Conejo', 'Reptil', 'Otro']),
    CategoryField(key: 'breed', label: 'Raza', type: CategoryFieldType.text, hint: 'Ej: Labrador, Siames...'),
    CategoryField(key: 'pet_age', label: 'Edad', type: CategoryFieldType.text, hint: 'Ej: 3 anos'),
    CategoryField(key: 'pet_weight', label: 'Peso aproximado (kg)', type: CategoryFieldType.number, hint: 'Ej: 15'),
    CategoryField(key: 'symptoms', label: 'Sintomas o motivo', type: CategoryFieldType.textarea, required: true, hint: 'Describi el motivo de la visita'),
    CategoryField(key: 'vaccinated', label: 'Vacunas al dia?', type: CategoryFieldType.toggle, defaultValue: 'true'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // FITNESS Y DEPORTE
  // ═══════════════════════════════════════════════════════════════

  'Fitness y Gimnasio': [
    CategoryField(key: 'goal', label: 'Objetivo', type: CategoryFieldType.select, required: true, options: ['Perder peso', 'Ganar masa', 'Tonificar', 'Mejorar resistencia', 'Rehabilitacion']),
    CategoryField(key: 'experience', label: 'Nivel de experiencia', type: CategoryFieldType.select, options: ['Principiante', 'Intermedio', 'Avanzado']),
    CategoryField(key: 'injuries', label: 'Lesiones o limitaciones', type: CategoryFieldType.text, hint: 'Ej: dolor de rodilla, hernia...'),
    CategoryField(key: 'preferred_time', label: 'Horario preferido', type: CategoryFieldType.select, options: ['Manana', 'Mediodia', 'Tarde', 'Noche']),
  ],

  'Yoga y Pilates': [
    CategoryField(key: 'experience', label: 'Nivel de experiencia', type: CategoryFieldType.select, required: true, options: ['Principiante', 'Intermedio', 'Avanzado']),
    CategoryField(key: 'style', label: 'Estilo preferido', type: CategoryFieldType.select, options: ['Hatha', 'Vinyasa', 'Ashtanga', 'Kundalini', 'Pilates Mat', 'Pilates Reformer', 'Sin preferencia']),
    CategoryField(key: 'injuries', label: 'Lesiones o limitaciones', type: CategoryFieldType.text, hint: 'Ej: dolor lumbar, embarazo...'),
    CategoryField(key: 'own_mat', label: 'Traes tu propio mat?', type: CategoryFieldType.toggle, defaultValue: 'false'),
  ],

  'Deportes y Canchas': [
    CategoryField(key: 'sport', label: 'Deporte', type: CategoryFieldType.select, required: true, options: ['Futbol 5', 'Futbol 7', 'Futbol 11', 'Tenis', 'Padel', 'Basquet', 'Voley', 'Otro']),
    CategoryField(key: 'players', label: 'Cantidad de jugadores', type: CategoryFieldType.number, required: true, hint: 'Ej: 10'),
    CategoryField(key: 'surface', label: 'Superficie preferida', type: CategoryFieldType.select, options: ['Sintetica', 'Natural', 'Cemento', 'Sin preferencia']),
    CategoryField(key: 'equipment', label: 'Necesitas equipamiento?', type: CategoryFieldType.toggle, defaultValue: 'false'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // GASTRONOMIA
  // ═══════════════════════════════════════════════════════════════

  'Restaurante y Cafe': [
    CategoryField(key: 'guests', label: 'Cantidad de personas', type: CategoryFieldType.number, required: true, hint: 'Ej: 4'),
    CategoryField(key: 'occasion', label: 'Ocasion', type: CategoryFieldType.select, options: ['Casual', 'Cumpleanos', 'Aniversario', 'Reunion de negocios', 'Cita', 'Otro']),
    CategoryField(key: 'seating', label: 'Ubicacion preferida', type: CategoryFieldType.select, options: ['Interior', 'Terraza', 'Barra', 'Sin preferencia']),
    CategoryField(key: 'dietary', label: 'Restricciones alimentarias', type: CategoryFieldType.multiSelect, options: ['Vegetariano', 'Vegano', 'Sin gluten', 'Sin lactosa', 'Ninguna']),
    CategoryField(key: 'special_requests', label: 'Pedidos especiales', type: CategoryFieldType.textarea, hint: 'Ej: silla para bebe, torta de cumpleanos...'),
  ],

  'Bar y Cerveceria': [
    CategoryField(key: 'guests', label: 'Cantidad de personas', type: CategoryFieldType.number, required: true, hint: 'Ej: 6'),
    CategoryField(key: 'occasion', label: 'Ocasion', type: CategoryFieldType.select, options: ['Casual', 'Cumpleanos', 'After office', 'Despedida', 'Otro']),
    CategoryField(key: 'seating', label: 'Ubicacion preferida', type: CategoryFieldType.select, options: ['Interior', 'Terraza', 'Barra', 'Sin preferencia']),
    CategoryField(key: 'special_requests', label: 'Pedidos especiales', type: CategoryFieldType.textarea, hint: 'Ej: mesa con pantalla, zona VIP...'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // SERVICIOS PROFESIONALES
  // ═══════════════════════════════════════════════════════════════

  'Abogados y Notaria': [
    CategoryField(key: 'area', label: 'Area legal', type: CategoryFieldType.select, required: true, options: ['Civil', 'Penal', 'Laboral', 'Comercial', 'Familia', 'Inmobiliario', 'Otro']),
    CategoryField(key: 'case_description', label: 'Breve descripcion del caso', type: CategoryFieldType.textarea, required: true, hint: 'Describi tu situacion legal'),
    CategoryField(key: 'urgency', label: 'Nivel de urgencia', type: CategoryFieldType.select, options: ['Normal', 'Urgente', 'Muy urgente']),
    CategoryField(key: 'documents', label: 'Documentos a presentar', type: CategoryFieldType.textarea, hint: 'Lista los documentos que vas a traer'),
  ],

  'Contabilidad y Finanzas': [
    CategoryField(key: 'service_type', label: 'Tipo de servicio', type: CategoryFieldType.select, required: true, options: ['Declaracion de IVA', 'Balance', 'Liquidacion de sueldos', 'Apertura de empresa', 'Asesoria tributaria', 'Otro']),
    CategoryField(key: 'business_type', label: 'Tipo de contribuyente', type: CategoryFieldType.select, options: ['Persona fisica', 'Unipersonal', 'SRL', 'SA', 'Otro']),
    CategoryField(key: 'ruc', label: 'RUC (si tiene)', type: CategoryFieldType.text, hint: 'Numero de RUC'),
    CategoryField(key: 'details', label: 'Detalle de lo que necesitas', type: CategoryFieldType.textarea, hint: 'Describi tu consulta contable'),
  ],

  'Consultoria Empresarial': [
    CategoryField(key: 'area', label: 'Area de consultoria', type: CategoryFieldType.select, required: true, options: ['Empresarial', 'Marketing', 'Financiera', 'Tecnologia', 'Recursos Humanos', 'Legal', 'Otra']),
    CategoryField(key: 'company_name', label: 'Nombre de la empresa', type: CategoryFieldType.text, hint: 'Tu empresa o emprendimiento'),
    CategoryField(key: 'company_size', label: 'Tamano de empresa', type: CategoryFieldType.select, options: ['Unipersonal', '2-10 empleados', '11-50 empleados', '50+ empleados']),
    CategoryField(key: 'challenge', label: 'Desafio principal', type: CategoryFieldType.textarea, required: true, hint: 'Describi el problema o desafio que enfrentas'),
  ],

  'Arquitectura y Diseno': [
    CategoryField(key: 'project_type', label: 'Tipo de proyecto', type: CategoryFieldType.select, required: true, options: ['Construccion nueva', 'Remodelacion', 'Diseno de interiores', 'Planos y permisos', 'Tasacion', 'Otro']),
    CategoryField(key: 'property_type', label: 'Tipo de propiedad', type: CategoryFieldType.select, options: ['Casa', 'Departamento', 'Local comercial', 'Oficina', 'Otro']),
    CategoryField(key: 'location', label: 'Ubicacion del proyecto', type: CategoryFieldType.text, hint: 'Direccion o zona'),
    CategoryField(key: 'area_m2', label: 'Superficie estimada (m2)', type: CategoryFieldType.number, hint: 'Ej: 120'),
    CategoryField(key: 'details', label: 'Descripcion del proyecto', type: CategoryFieldType.textarea, hint: 'Describi lo que necesitas'),
  ],

  'Inmobiliaria': [
    CategoryField(key: 'operation', label: 'Tipo de operacion', type: CategoryFieldType.select, required: true, options: ['Compra', 'Venta', 'Alquiler', 'Tasacion', 'Inversion']),
    CategoryField(key: 'property_type', label: 'Tipo de propiedad', type: CategoryFieldType.select, options: ['Casa', 'Departamento', 'Terreno', 'Local comercial', 'Oficina', 'Campo']),
    CategoryField(key: 'location', label: 'Zona de interes', type: CategoryFieldType.text, hint: 'Ej: Asuncion centro, Luque...'),
    CategoryField(key: 'budget', label: 'Presupuesto aproximado (USD)', type: CategoryFieldType.text, hint: 'Ej: 50.000 - 80.000'),
    CategoryField(key: 'requirements', label: 'Requisitos especiales', type: CategoryFieldType.textarea, hint: 'Ej: 3 dormitorios, garage, piscina...'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // CREATIVOS
  // ═══════════════════════════════════════════════════════════════

  'Fotografia y Video': [
    CategoryField(key: 'session_type', label: 'Tipo de sesion', type: CategoryFieldType.select, required: true, options: ['Individual', 'Pareja', 'Familiar', 'Producto', 'Evento', 'Book profesional', 'Video corporativo']),
    CategoryField(key: 'location', label: 'Ubicacion de la sesion', type: CategoryFieldType.select, options: ['Estudio', 'Exterior', 'Domicilio', 'Por definir']),
    CategoryField(key: 'people_count', label: 'Cantidad de personas', type: CategoryFieldType.number, hint: 'Ej: 3'),
    CategoryField(key: 'style', label: 'Estilo deseado', type: CategoryFieldType.text, hint: 'Ej: natural, formal, artistico...'),
    CategoryField(key: 'special_requests', label: 'Pedidos especiales', type: CategoryFieldType.textarea, hint: 'Props, vestuario, tematica...'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // AUTOMOTRIZ
  // ═══════════════════════════════════════════════════════════════

  'Mecanica Automotriz': [
    CategoryField(key: 'vehicle_brand', label: 'Marca del vehiculo', type: CategoryFieldType.text, required: true, hint: 'Ej: Toyota, Chevrolet...'),
    CategoryField(key: 'vehicle_model', label: 'Modelo', type: CategoryFieldType.text, required: true, hint: 'Ej: Corolla 2020'),
    CategoryField(key: 'plate', label: 'Patente / Chapa', type: CategoryFieldType.text, required: true, hint: 'Ej: ABC 123'),
    CategoryField(key: 'mileage', label: 'Kilometraje actual', type: CategoryFieldType.number, hint: 'Ej: 45000'),
    CategoryField(key: 'problem', label: 'Descripcion del problema', type: CategoryFieldType.textarea, required: true, hint: 'Describi el problema o servicio que necesitas'),
    CategoryField(key: 'fuel_type', label: 'Combustible', type: CategoryFieldType.select, options: ['Nafta', 'Diesel', 'GNC', 'Electrico', 'Hibrido']),
  ],

  'Lavadero de Autos': [
    CategoryField(key: 'vehicle_type', label: 'Tipo de vehiculo', type: CategoryFieldType.select, required: true, options: ['Auto', 'Camioneta', 'SUV', 'Moto', 'Camion']),
    CategoryField(key: 'vehicle_brand', label: 'Marca y modelo', type: CategoryFieldType.text, hint: 'Ej: Toyota Hilux'),
    CategoryField(key: 'wash_type', label: 'Tipo de lavado', type: CategoryFieldType.select, options: ['Exterior', 'Interior', 'Completo', 'Premium / Detailing']),
    CategoryField(key: 'plate', label: 'Patente / Chapa', type: CategoryFieldType.text, hint: 'Ej: ABC 123'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // EDUCACION
  // ═══════════════════════════════════════════════════════════════

  'Educacion y Tutorias': [
    CategoryField(key: 'subject', label: 'Materia / Tema', type: CategoryFieldType.text, required: true, hint: 'Ej: Matematicas, Ingles, Guitarra...'),
    CategoryField(key: 'level', label: 'Nivel', type: CategoryFieldType.select, required: true, options: ['Primaria', 'Secundaria', 'Universitario', 'Adulto']),
    CategoryField(key: 'modality', label: 'Modalidad', type: CategoryFieldType.select, options: ['Presencial', 'Online', 'Sin preferencia']),
    CategoryField(key: 'goals', label: 'Objetivo de la clase', type: CategoryFieldType.textarea, hint: 'Ej: preparar examen, reforzar tema...'),
    CategoryField(key: 'student_age', label: 'Edad del alumno', type: CategoryFieldType.number, hint: 'Ej: 15'),
  ],

  // ═══════════════════════════════════════════════════════════════
  // OTROS SERVICIOS
  // ═══════════════════════════════════════════════════════════════

  'Electronica y Reparacion': [
    CategoryField(key: 'device_type', label: 'Tipo de dispositivo', type: CategoryFieldType.select, required: true, options: ['Celular', 'Notebook', 'PC de escritorio', 'Tablet', 'Electrodomestico', 'Otro']),
    CategoryField(key: 'brand_model', label: 'Marca y modelo', type: CategoryFieldType.text, required: true, hint: 'Ej: iPhone 14, Samsung Galaxy S23...'),
    CategoryField(key: 'problem', label: 'Descripcion del problema', type: CategoryFieldType.textarea, required: true, hint: 'Describi que le pasa al dispositivo'),
    CategoryField(key: 'warranty', label: 'Esta en garantia?', type: CategoryFieldType.toggle, defaultValue: 'false'),
    CategoryField(key: 'backup', label: 'Necesitas backup de datos?', type: CategoryFieldType.toggle, defaultValue: 'false'),
  ],

  'Limpieza y Mantenimiento': [
    CategoryField(key: 'space_type', label: 'Tipo de espacio', type: CategoryFieldType.select, required: true, options: ['Casa', 'Departamento', 'Oficina', 'Local comercial', 'Post-obra']),
    CategoryField(key: 'space_size', label: 'Tamano aproximado (m2)', type: CategoryFieldType.number, hint: 'Ej: 80'),
    CategoryField(key: 'cleaning_type', label: 'Tipo de limpieza', type: CategoryFieldType.select, options: ['Basica', 'Profunda', 'Mantenimiento', 'Post-obra', 'Mudanza']),
    CategoryField(key: 'rooms', label: 'Cantidad de ambientes', type: CategoryFieldType.number, hint: 'Ej: 5'),
    CategoryField(key: 'pets', label: 'Hay mascotas en el hogar?', type: CategoryFieldType.toggle, defaultValue: 'false'),
    CategoryField(key: 'supplies', label: 'Proveen materiales?', type: CategoryFieldType.toggle, defaultValue: 'true'),
  ],

  'Eventos y Catering': [
    CategoryField(key: 'event_type', label: 'Tipo de evento', type: CategoryFieldType.select, required: true, options: ['Cumpleanos', 'Casamiento', 'Corporativo', 'Baby shower', 'Graduacion', 'Otro']),
    CategoryField(key: 'guests', label: 'Cantidad de invitados', type: CategoryFieldType.number, required: true, hint: 'Ej: 50'),
    CategoryField(key: 'event_date', label: 'Fecha del evento', type: CategoryFieldType.date),
    CategoryField(key: 'venue', label: 'Lugar del evento', type: CategoryFieldType.text, hint: 'Direccion o nombre del salon'),
    CategoryField(key: 'services_needed', label: 'Servicios necesarios', type: CategoryFieldType.multiSelect, options: ['Catering', 'Decoracion', 'DJ/Musica', 'Fotografia', 'Torta', 'Mobiliario']),
    CategoryField(key: 'budget', label: 'Presupuesto estimado (Gs)', type: CategoryFieldType.text, hint: 'Ej: 5.000.000'),
  ],

  'Coworking y Oficinas': [
    CategoryField(key: 'space_type', label: 'Tipo de espacio', type: CategoryFieldType.select, required: true, options: ['Escritorio individual', 'Oficina privada', 'Sala de reuniones', 'Sala de conferencias', 'Espacio compartido']),
    CategoryField(key: 'people', label: 'Cantidad de personas', type: CategoryFieldType.number, required: true, hint: 'Ej: 4'),
    CategoryField(key: 'duration', label: 'Duracion', type: CategoryFieldType.select, options: ['Por hora', 'Medio dia', 'Dia completo', 'Semanal', 'Mensual']),
    CategoryField(key: 'equipment', label: 'Necesitas equipamiento?', type: CategoryFieldType.multiSelect, options: ['Proyector', 'Pizarra', 'Monitor externo', 'Impresora', 'Ninguno']),
  ],

  'Otros': [
    CategoryField(key: 'description', label: 'Descripcion del servicio que necesitas', type: CategoryFieldType.textarea, required: true, hint: 'Describi que servicio buscas'),
    CategoryField(key: 'special_requests', label: 'Pedidos especiales', type: CategoryFieldType.textarea, hint: 'Informacion adicional relevante'),
  ],
};

/// Returns form fields for a category name.
/// Falls back to a minimal generic form if the category has no specific fields.
List<CategoryField> getFieldsForCategory(String categoryName) {
  return normalizedLookup(categoryFormFields, categoryName) ?? const [
    CategoryField(
      key: 'notes',
      label: 'Notas adicionales',
      type: CategoryFieldType.textarea,
      hint: 'Agrega cualquier informacion relevante para tu reserva',
    ),
  ];
}
