-- ============================================================
-- ReservPy — Categorías DEFINITIVAS
-- Ejecutar en Supabase SQL Editor
-- ============================================================

-- 1. Limpiar datos de prueba (CASCADE borra services también)
DELETE FROM public.reservations;
DELETE FROM public.services;
DELETE FROM public.businesses;
DELETE FROM public.categories;

-- 2. Insertar categorías definitivas (30 categorías reales)
INSERT INTO public.categories (name, icon, color, sort_order) VALUES
  -- Belleza y Cuidado Personal
  ('Peluquería y Barbería',       'content_cut',        '#FF7043',  1),
  ('Belleza y Estética',          'spa',                '#E040FB',  2),
  ('Spa y Masajes',               'hot_tub',            '#AB47BC',  3),
  ('Uñas y Manicura',            'brush',              '#EC407A',  4),
  ('Tatuajes y Piercing',        'auto_awesome',       '#455A64',  5),

  -- Salud
  ('Medicina General',            'local_hospital',     '#42A5F5',  6),
  ('Odontología',                 'medical_services',   '#26C6DA',  7),
  ('Psicología y Terapia',        'psychology',         '#7E57C2',  8),
  ('Nutrición y Dietética',       'restaurant',         '#66BB6A',  9),
  ('Dermatología',                'healing',            '#EF9A9A', 10),
  ('Kinesiología y Fisioterapia', 'accessibility_new',  '#4DB6AC', 11),
  ('Podología',                   'do_not_step',        '#A1887F', 12),
  ('Oftalmología',                'visibility',         '#64B5F6', 13),

  -- Animales
  ('Veterinaria',                 'pets',               '#8D6E63', 14),

  -- Fitness y Deporte
  ('Fitness y Gimnasio',          'fitness_center',     '#EF5350', 15),
  ('Yoga y Pilates',              'self_improvement',   '#26A69A', 16),
  ('Deportes y Canchas',          'sports_soccer',      '#4CAF50', 17),

  -- Gastronomía
  ('Restaurante y Café',          'restaurant',         '#FF7043', 18),
  ('Bar y Cervecería',            'local_bar',          '#FFB74D', 19),

  -- Servicios Profesionales
  ('Abogados y Notaría',          'gavel',              '#78909C', 20),
  ('Contabilidad y Finanzas',     'account_balance',    '#5C6BC0', 21),
  ('Consultoría Empresarial',     'business_center',    '#42A5F5', 22),
  ('Arquitectura y Diseño',       'architecture',       '#80CBC4', 23),
  ('Inmobiliaria',                'home_work',          '#26A69A', 24),

  -- Creativos
  ('Fotografía y Video',          'camera_alt',         '#EC407A', 25),

  -- Automotriz
  ('Mecánica Automotriz',         'build',              '#FF8A65', 26),
  ('Lavadero de Autos',           'local_car_wash',     '#4FC3F7', 27),

  -- Educación
  ('Educación y Tutorías',        'school',             '#29B6F6', 28),

  -- Otros servicios
  ('Electrónica y Reparación',    'build',              '#FF9800', 29),
  ('Limpieza y Mantenimiento',    'cleaning_services',  '#66BB6A', 30),
  ('Eventos y Catering',          'celebration',        '#E91E63', 31),
  ('Coworking y Oficinas',        'meeting_room',       '#607D8B', 32),
  ('Otros',                       'category',           '#90A4AE', 99);
