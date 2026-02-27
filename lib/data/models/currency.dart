class Currency {
  final String code;
  final String name;

  const Currency({required this.code, required this.name});

  String get displayName => '$code - $name';

  factory Currency.fromJson(String code, String name) {
    return Currency(code: code, name: name);
  }

  Map<String, dynamic> toMap() => {'code': code, 'name': name};

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      code: map['code'] as String,
      name: map['name'] as String,
    );
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => displayName;
}
