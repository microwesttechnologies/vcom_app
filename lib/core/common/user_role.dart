/// Normalizacion unica de roles de usuario.
///
/// El claim `role_user` del JWT llega con el nombre del rol tal cual esta en
/// base de datos ("Modelo", "Monitor", "Monitor de modelos", ...), por lo que
/// comparar con igualdad exacta es fragil.
class UserRole {
  UserRole._();

  static const String modelo = 'MODELO';
  static const String monitor = 'MONITOR';
  static const String admin = 'ADMIN';
  static const String store = 'STORE';

  /// Normaliza el rol crudo (mayusculas, acentos, espacios y variantes).
  /// Devuelve el valor en mayusculas cuando no corresponde a un rol conocido.
  static String normalize(String? raw) {
    final value = _stripAccents((raw ?? '').trim().toLowerCase());
    if (value.isEmpty) return '';

    // "monitor" se evalua primero: nombres como "monitor de modelos"
    // contienen ambas palabras.
    if (value.contains('monitor')) return monitor;
    if (value.contains('model') || value.contains('modal')) return modelo;
    if (value.contains('admin')) return admin;
    if (value.contains('store') || value.contains('tienda')) return store;

    return value.toUpperCase();
  }

  static bool isModelo(String? raw) => normalize(raw) == modelo;

  static bool isMonitor(String? raw) => normalize(raw) == monitor;

  static bool isAdmin(String? raw) => normalize(raw) == admin;

  /// Experiencia visual de modelo/monitor.
  ///
  /// Esta app es exclusiva para modelos y monitores: siempre la misma UI.
  static bool usesModeloExperience(String? raw) => true;

  static String _stripAccents(String value) {
    const accented = 'áàäâãéèëêíìïîóòöôõúùüûñ';
    const plain = 'aaaaaeeeeiiiiooooouuuun';

    var result = value;
    for (var i = 0; i < accented.length; i++) {
      result = result.replaceAll(accented[i], plain[i]);
    }
    return result;
  }
}
