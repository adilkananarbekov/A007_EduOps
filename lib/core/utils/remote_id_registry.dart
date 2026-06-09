class RemoteIdRegistry {
  static final Map<String, int> _remoteToLocal = {};
  static final Map<int, String> _localToRemote = {};
  static final Map<int, Map<String, String>> _scheduleMeta = {};
  static final Map<int, String> _groupNames = {};
  static final Map<int, String> _subjectNames = {};

  static int localId(dynamic value, {String namespace = 'default'}) {
    if (value is num) {
      return value.toInt();
    }

    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return 0;
    }

    final numeric = int.tryParse(raw);
    if (numeric != null) {
      return numeric;
    }

    final key = '$namespace:$raw';
    final existing = _remoteToLocal[key];
    if (existing != null) {
      return existing;
    }

    var local = _stableHash(key);
    while (_localToRemote.containsKey(local) && _localToRemote[local] != raw) {
      local++;
    }

    _remoteToLocal[key] = local;
    _localToRemote[local] = raw;
    return local;
  }

  static String remoteId(int localId, {String? fallback}) {
    return _localToRemote[localId] ?? fallback ?? localId.toString();
  }

  static String remoteValue(dynamic value, {String? fallback}) {
    if (value is int) {
      return remoteId(value, fallback: fallback);
    }
    final raw = value?.toString().trim();
    return raw == null || raw.isEmpty ? (fallback ?? '') : raw;
  }

  static void registerGroupName(int groupId, String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      _groupNames[groupId] = trimmed;
    }
  }

  static String? groupName(int groupId) => _groupNames[groupId];

  static void registerSubjectName(int subjectId, String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      _subjectNames[subjectId] = trimmed;
    }
  }

  static String? subjectName(int subjectId) => _subjectNames[subjectId];

  static void registerScheduleMeta(
    int scheduleId, {
    String? className,
    String? subjectName,
  }) {
    final meta = _scheduleMeta.putIfAbsent(
      scheduleId,
      () => <String, String>{},
    );
    final classNameValue = className?.trim();
    if (classNameValue != null && classNameValue.isNotEmpty) {
      meta['className'] = classNameValue;
    }
    final subjectNameValue = subjectName?.trim();
    if (subjectNameValue != null && subjectNameValue.isNotEmpty) {
      meta['subjectName'] = subjectNameValue;
    }
  }

  static String? scheduleClassName(int scheduleId) =>
      _scheduleMeta[scheduleId]?['className'];

  static String? scheduleSubjectName(int scheduleId) =>
      _scheduleMeta[scheduleId]?['subjectName'];

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash + 1000;
  }
}
