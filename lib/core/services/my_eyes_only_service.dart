import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère le code (PIN) protégeant l'accès à la section "My Eyes Only" (Tâche
/// 22, voir DECISIONS.md).
///
/// Stockage `SharedPreferences` uniquement, strictement local à cet appareil
/// et **jamais synchronisé vers Supabase** — contrairement au champ
/// `VideoBookmark.isHidden`, qui l'est comme n'importe quel autre champ de
/// bookmark. Seul le hash SHA-256 du code est persisté, jamais le code en
/// clair.
///
/// **Limite de sécurité assumée :** ce code ne protège l'accès que depuis
/// l'interface de l'app — les bookmarks masqués restent en clair dans Isar
/// et dans Supabase (protégés par RLS comme tous les autres bookmarks, donc
/// invisibles aux autres utilisateurs, mais pas chiffrés pour le
/// propriétaire lui-même). C'est une fonctionnalité de confidentialité
/// d'usage, pas un chiffrement fort.
class MyEyesOnlyService {
  MyEyesOnlyService(this._preferences);

  final SharedPreferences _preferences;

  static const _pinHashKey = 'my_eyes_only_pin_hash';

  /// Vrai si un code a déjà été défini sur cet appareil.
  bool hasPinSet() => _preferences.containsKey(_pinHashKey);

  /// Enregistre [pin] : seul son hash SHA-256 est persisté, jamais le code
  /// en clair.
  Future<void> setPin(String pin) {
    return _preferences.setString(_pinHashKey, _hash(pin));
  }

  /// Vrai si [pin] correspond au code actuellement enregistré (comparaison
  /// de hash, jamais du code en clair). Faux si aucun code n'est enregistré.
  bool verifyPin(String pin) {
    final storedHash = _preferences.getString(_pinHashKey);
    return storedHash != null && storedHash == _hash(pin);
  }

  /// Efface le code enregistré (flux "Code oublié ?", voir DECISIONS.md) —
  /// c'est à l'appelant de démasquer les bookmarks concernés via
  /// `BookmarkRepository.unhideAllBookmarks`, cette classe ne connaissant
  /// que le code, jamais les bookmarks eux-mêmes.
  Future<void> resetPin() {
    return _preferences.remove(_pinHashKey);
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();
}
