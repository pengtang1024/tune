import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/utils/text_order.dart';

/// The order of a list follows the language of the reader.
///
/// A letter with an accent belongs next to the letter it is written with, so
/// a German title is not pushed behind every title that starts with a "Z".
void main() {
  test('the accent does not change the place of a letter', () {
    final titles = ['Zebra', 'Ärger', 'Apfel', 'Öl'];

    titles.sort(compareText);

    expect(titles, ['Apfel', 'Ärger', 'Öl', 'Zebra']);
  });

  test('the case does not change the place of a letter', () {
    final titles = ['banana', 'Apple', 'cherry'];

    titles.sort(compareText);

    expect(titles, ['Apple', 'banana', 'cherry']);
  });

  test('a letter that carries no accent keeps its own place', () {
    final titles = ['Ícaro', 'Alfa', 'Zeta'];

    titles.sort(compareText);

    expect(titles, ['Alfa', 'Ícaro', 'Zeta']);
  });

  test('a letter written as two letters keeps both of them', () {
    final titles = ['Strasse', 'Apfel', 'Straße'];

    titles.sort(compareText);

    expect(titles.first, 'Apfel');
  });

  test('a text without a latin letter keeps the order of its characters', () {
    final titles = ['香蕉', '苹果', '橘子'];

    titles.sort(compareText);

    // A script without an alphabet keeps the order of its characters, which
    // is the order the characters of the script are written in.
    expect(titles, ['橘子', '苹果', '香蕉']);
  });
}
