import 'dart:collection';

Map<String, T> createCaseInsensitiveMap<T>({ Map<String, T>? map }) {
  var result = LinkedHashMap<String, T>(
    equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
    hashCode: (e) => e.toLowerCase().hashCode,
  );
  if (map != null) {
    result.addAll(map);
  }
  return result;
}
