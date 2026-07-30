import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Gère l'initialisation du client Supabase.
///
/// Responsabilité unique : démarrer le SDK Supabase et exposer le client
/// initialisé. Ne contient aucune logique métier (requêtes, mapping, etc.),
/// celle-ci vit dans les `Repository` de chaque feature.
class SupabaseService {
  const SupabaseService._();

  /// Initialise le SDK Supabase avec les identifiants de [Env].
  ///
  /// Doit être appelée une seule fois, avant `runApp`.
  static Future<void> initialize() {
    return Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  /// Client Supabase initialisé, à utiliser par les `Repository`.
  static SupabaseClient get client => Supabase.instance.client;
}
