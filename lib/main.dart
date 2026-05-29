import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'src/core/supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();

  try {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('en', null);
  } catch (e) {
    // Safely fallback if date localization fails
  }

  runApp(
    const ProviderScope(
      child: ReservPyApp(),
    ),
  );
}
