import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which chapters the visitor has opened.
///
/// This is what turns a journey-map node from "unvisited" into "visited", and
/// it is deliberately separate from any widget so it can be unit-tested and so
/// scene rendering stays stateless.
class StoryProgress extends ChangeNotifier {
  StoryProgress({Set<String>? initial}) : _visited = {...?initial};

  static const _storageKey = 'gyan.portfolio.visited';

  final Set<String> _visited;

  /// An unmodifiable view; callers mutate only through [visit].
  Set<String> get visited => Set.unmodifiable(_visited);

  bool hasVisited(String id) => _visited.contains(id);

  int get count => _visited.length;

  /// Records a visit. Returns true when this was the first time.
  bool visit(String id) {
    if (!_visited.add(id)) return false;
    notifyListeners();
    _persist();
    return true;
  }

  void reset() {
    if (_visited.isEmpty) return;
    _visited.clear();
    notifyListeners();
    _persist();
  }

  /// Restores progress from browser storage. Failures are non-fatal — a
  /// visitor with blocked storage simply starts fresh.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_storageKey);
      if (stored == null || stored.isEmpty) return;
      _visited.addAll(stored);
      notifyListeners();
    } catch (_) {
      // Private windows and blocked site data land here; ignore.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _visited.toList());
    } catch (_) {
      // See [load].
    }
  }
}
