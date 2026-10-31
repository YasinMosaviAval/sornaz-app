typedef PracticeTreeRow = Map<String, dynamic>;

class PracticeTree {
  PracticeTree(Iterable<PracticeTreeRow> rows) : nodes = rows.toList() {
    nodes.sort((a, b) {
      final order = (a['position'] as int? ?? 0).compareTo(
        b['position'] as int? ?? 0,
      );
      return order != 0 ? order : (a['id'] as int).compareTo(b['id'] as int);
    });
  }
  final List<PracticeTreeRow> nodes;
  List<PracticeTreeRow> children(int? parent) => nodes
      .where((n) => (n['parentId'] == 0 ? null : n['parentId']) == parent)
      .toList();
  List<PracticeTreeRow> get ordered {
    final result = <PracticeTreeRow>[], visited = <int>{};
    void add(PracticeTreeRow node) {
      if (!visited.add(node['id'] as int)) return;
      result.add(node);
      for (final child in children(node['id'] as int)) {
        add(child);
      }
    }

    for (final node in children(null)) {
      add(node);
    }
    for (final node in nodes) {
      add(node);
    }
    return result;
  }

  bool available(int? id) {
    final visited = <int>{};
    while (id != null && id != 0) {
      if (!visited.add(id)) return false;
      final matches = nodes.where((n) => n['id'] == id);
      if (matches.isEmpty || matches.first['published'] != true) return false;
      id = matches.first['parentId'] as int?;
    }
    return true;
  }
}
