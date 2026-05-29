import 'package:flutter/material.dart';
import 'models/models.dart';

/// Fallback categories used when Supabase is unreachable.
/// These should match the 25 categories in the Supabase `categories` table.
final List<BusinessCategory> mockCategories = [
  const BusinessCategory(
      id: 'cat-1', name: 'Salud', icon: Icons.local_hospital_rounded, color: Color(0xFF4FC3F7)),
  const BusinessCategory(
      id: 'cat-2', name: 'Belleza y estética', icon: Icons.spa_rounded, color: Color(0xFFE040FB)),
  const BusinessCategory(
      id: 'cat-3', name: 'Peluquería / Barbería', icon: Icons.content_cut_rounded, color: Color(0xFFFF7043)),
  const BusinessCategory(
      id: 'cat-4', name: 'Odontología', icon: Icons.medical_services_rounded, color: Color(0xFF26C6DA)),
  const BusinessCategory(
      id: 'cat-5', name: 'Psicología / Terapia', icon: Icons.psychology_rounded, color: Color(0xFF7E57C2)),
  const BusinessCategory(
      id: 'cat-6', name: 'Nutrición', icon: Icons.restaurant_menu_rounded, color: Color(0xFF66BB6A)),
  const BusinessCategory(
      id: 'cat-7', name: 'Veterinaria', icon: Icons.pets_rounded, color: Color(0xFF8D6E63)),
  const BusinessCategory(
      id: 'cat-8', name: 'Fitness / Gimnasio', icon: Icons.fitness_center_rounded, color: Color(0xFFEF5350)),
  const BusinessCategory(
      id: 'cat-9', name: 'Yoga / Pilates', icon: Icons.self_improvement_rounded, color: Color(0xFF26A69A)),
  const BusinessCategory(
      id: 'cat-10', name: 'Restaurante / Café', icon: Icons.restaurant_rounded, color: Color(0xFFFF7043)),
  const BusinessCategory(
      id: 'cat-11', name: 'Consultorio médico', icon: Icons.health_and_safety_rounded, color: Color(0xFF42A5F5)),
  const BusinessCategory(
      id: 'cat-12', name: 'Abogados / Notaría', icon: Icons.gavel_rounded, color: Color(0xFF78909C)),
  const BusinessCategory(
      id: 'cat-13', name: 'Contabilidad', icon: Icons.calculate_rounded, color: Color(0xFF5C6BC0)),
  const BusinessCategory(
      id: 'cat-14', name: 'Fotografía', icon: Icons.camera_alt_rounded, color: Color(0xFFEC407A)),
  const BusinessCategory(
      id: 'cat-15', name: 'Tatuajes / Piercing', icon: Icons.brush_rounded, color: Color(0xFF455A64)),
  const BusinessCategory(
      id: 'cat-16', name: 'Mecánica automotriz', icon: Icons.car_repair_rounded, color: Color(0xFFFF8A65)),
  const BusinessCategory(
      id: 'cat-17', name: 'Educación / Tutorías', icon: Icons.school_rounded, color: Color(0xFF29B6F6)),
  const BusinessCategory(
      id: 'cat-18', name: 'Masajes / Spa', icon: Icons.hot_tub_rounded, color: Color(0xFFAB47BC)),
  const BusinessCategory(
      id: 'cat-19', name: 'Consultoría', icon: Icons.work_rounded, color: Color(0xFF42A5F5)),
  const BusinessCategory(
      id: 'cat-20', name: 'Inmobiliaria', icon: Icons.home_work_rounded, color: Color(0xFF26A69A)),
  const BusinessCategory(
      id: 'cat-21', name: 'Limpieza', icon: Icons.cleaning_services_rounded, color: Color(0xFF66BB6A)),
  const BusinessCategory(
      id: 'cat-22', name: 'Electrónica / Reparación', icon: Icons.build_rounded, color: Color(0xFFFF9800)),
  const BusinessCategory(
      id: 'cat-23', name: 'Deportes / Canchas', icon: Icons.sports_soccer_rounded, color: Color(0xFF4CAF50)),
  const BusinessCategory(
      id: 'cat-24', name: 'Eventos / Catering', icon: Icons.celebration_rounded, color: Color(0xFFE91E63)),
  const BusinessCategory(
      id: 'cat-25', name: 'Otros', icon: Icons.category_rounded, color: Color(0xFF90A4AE)),
];
