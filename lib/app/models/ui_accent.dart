enum UiAccent {
  red,
  blue,
  green,
  gray,
  orange,
}

extension UiAccentJson on UiAccent {
  String get value => name;

  static UiAccent fromValue(String raw) {
    return UiAccent.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => UiAccent.gray,
    );
  }
}
