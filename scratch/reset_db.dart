import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('No se encontró el archivo .env');
    exit(1);
  }

  final lines = await envFile.readAsLines();
  String? supabaseUrl;
  String? supabaseAnonKey;
  String? supabaseServiceRoleKey;

  for (var line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final val = parts.sublist(1).join('=').trim();
      if (key == 'SUPABASE_URL') supabaseUrl = val;
      if (key == 'SUPABASE_ANON_KEY') supabaseAnonKey = val;
      if (key == 'SUPABASE_SERVICE_ROLE_KEY') supabaseServiceRoleKey = val;
    }
  }
  
  if (supabaseUrl == null || supabaseAnonKey == null) {
    print('Faltan credenciales en .env');
    exit(1);
  }

  print('Reiniciando base de datos...');
  
  try {
    final client = SupabaseClient(supabaseUrl, supabaseServiceRoleKey ?? supabaseAnonKey);

    final response = await client.from('profiles').select('user_id');
    final profiles = response as List;

    for (var profile in profiles) {
      final userId = profile['user_id'];
      await client.from('profiles').update({
        'last_login': null,
        'streak_count': 1,
        'coins': 0,
        'level': 1,
      }).eq('user_id', userId);
      print('Perfil $userId reseteado.');
    }
    
    print('Reseteo completado exitosamente.');
    exit(0);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
