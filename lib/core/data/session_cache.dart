abstract final class SessionCache {
  static final Map<String, Object?> _store = <String, Object?>{};

  static T? get<T>(String key) {
    final value = _store[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  static void set<T>(String key, T value) {
    _store[key] = value;
  }

  static void remove(String key) {
    _store.remove(key);
  }

  static void removeWherePrefix(String prefix) {
    final keys = _store.keys
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in keys) {
      _store.remove(key);
    }
  }
}
