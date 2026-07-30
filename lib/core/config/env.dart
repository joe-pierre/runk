/// Expose la configuration d'environnement de l'application.
///
/// Les valeurs sont injectées à la compilation via `--dart-define-from-file`
/// (voir `scripts/run_dev.sh`) et ne doivent jamais être codées en dur ici.
class Env {
  const Env._();

  /// URL du projet Supabase utilisé par l'application.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clé publique (`anon`/`publishable`) du projet Supabase.
  ///
  /// Jamais la clé `service_role` : voir CONVENTIONS.md section Sécurité.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
}
