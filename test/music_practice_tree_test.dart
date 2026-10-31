import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/MusicPractice/practice_tree.dart';

void main() {
  test(
    'tree order keeps children under their actual parents independent of input order',
    () {
      final tree = PracticeTree([
        {'id': 4, 'parentId': 2, 'published': true, 'position': 1},
        {'id': 1, 'parentId': null, 'published': true, 'position': 1},
        {'id': 3, 'parentId': 2, 'published': true, 'position': 0},
        {'id': 2, 'parentId': 1, 'published': true, 'position': 0},
        {'id': 5, 'parentId': null, 'published': true, 'position': 2},
      ]);
      expect(tree.ordered.map((n) => n['id']), [1, 2, 3, 4, 5]);
      expect(tree.available(4), true);
      tree.nodes.firstWhere((n) => n['id'] == 1)['published'] = false;
      expect(tree.available(4), false);
      expect(tree.available(2), false);
      expect(tree.available(5), true);
    },
  );
  test('cyclic and missing parents cannot enable a subtree', () {
    final tree = PracticeTree([
      {'id': 1, 'parentId': 2, 'published': true},
      {'id': 2, 'parentId': 1, 'published': true},
      {'id': 3, 'parentId': 99, 'published': true},
    ]);
    expect(tree.available(1), false);
    expect(tree.available(3), false);
    expect(tree.ordered, hasLength(3));
  });
}
