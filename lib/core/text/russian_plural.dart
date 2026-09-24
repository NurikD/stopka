/// Picks the right Russian noun form for a count: 1 буква, 2 буквы, 5 букв.
String pluralRu(int n, {required String one, required String few, required String many}) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}
