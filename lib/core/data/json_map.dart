typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(Object? value) {
  if (value is JsonMap) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, dynamic value) => MapEntry(key.toString(), value),
    );
  }

  throw FormatException('Expected a JSON object but received $value.');
}

List<JsonMap> asJsonList(Object? value) {
  if (value == null) {
    return const [];
  }

  if (value is! List) {
    throw FormatException('Expected a JSON list but received $value.');
  }

  return value.map(asJsonMap).toList(growable: false);
}

String? normalizeNullableString(String? value) {
  if (value == null) {
    return null;
  }

  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? asNullableString(Object? value) {
  if (value == null) {
    return null;
  }

  return normalizeNullableString(value.toString());
}

int? asNullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double? asNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

bool? asNullableBool(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  final normalized = value.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') {
    return true;
  }

  if (normalized == 'false' || normalized == '0') {
    return false;
  }

  return null;
}

DateTime? asNullableDateTime(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

String? asDateOnlyString(DateTime? value) {
  if (value == null) {
    return null;
  }

  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
