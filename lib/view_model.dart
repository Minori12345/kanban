import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model.dart';

class KanbanViewModel extends ChangeNotifier {
  KanbanViewModel({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
  }) : prefs = preferences ?? SharedPreferencesAsync(),
       _now = now ?? DateTime.now {
    _today = _date(_now());
    selectedDate = _today;
  }

  final SharedPreferencesAsync prefs;
  final DateTime Function() _now;
  final _habits = <Task>[];
  final _days = <String, List<Task>>{};
  late DateTime _today;
  late DateTime selectedDate;
  int _nextId = 0;
  Future<void> _pendingSave = Future.value();

  static DateTime _date(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool get isToday => selectedDate == _today;
  bool get hasRecord => _days.containsKey(_key(selectedDate));
  List<Task> get tasks =>
      List.unmodifiable(_days[_key(selectedDate)] ?? <Task>[]);
  int get completed => tasks.where((task) => task.done).length;
  int get percentage =>
      tasks.isEmpty ? 0 : (completed / tasks.length * 100).round();

  Future<void> load() async {
    final data = await prefs.getString('daily_habits');
    _habits.clear();
    _days.clear();
    _today = _date(_now());
    selectedDate = _today;
    if (data != null) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      _nextId = json['nextId'] as int;
      _habits.addAll(
        (json['habits'] as List).map(
          (item) => Task.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      );
      for (final entry in (json['days'] as Map<String, dynamic>).entries) {
        _days[entry.key] = (entry.value as List)
            .map(
              (item) => Task.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
    } else {
      final legacy = await prefs.getString('kanban');
      if (legacy != null) {
        for (final item in jsonDecode(legacy) as List) {
          _habits.add(
            Task(
              '${_nextId++}',
              item['title'] as String,
              done: item['status'] == 2,
            ),
          );
        }
      }
    }
    _ensureToday();
    await save();
  }

  void _ensureToday() {
    _days.putIfAbsent(
      _key(_today),
      () => [for (final task in _habits) task.copy()],
    );
    for (final task in _habits) {
      task.done = false;
    }
  }

  void refreshDate() {
    final today = _date(_now());
    if (today == _today) return;
    final wasToday = isToday;
    _today = today;
    if (wasToday || selectedDate.isAfter(today)) selectedDate = today;
    _ensureToday();
    save();
  }

  void selectDate(DateTime date) {
    refreshDate();
    final selected = _date(date);
    if (selected.isAfter(_today)) return;
    selectedDate = selected;
    notifyListeners();
  }

  void showToday() {
    refreshDate();
    selectDate(_today);
  }

  Future<void> save() {
    final data = jsonEncode({
      'nextId': _nextId,
      'habits': [for (final task in _habits) task.toJson()],
      'days': _days.map(
        (key, value) =>
            MapEntry(key, [for (final task in value) task.toJson()]),
      ),
    });
    // Keep writes in order when several actions happen quickly.
    _pendingSave = _pendingSave.then(
      (_) => prefs.setString('daily_habits', data),
    );
    notifyListeners();
    return _pendingSave;
  }

  bool _canEdit() {
    final previous = selectedDate;
    refreshDate();
    return isToday && previous == selectedDate;
  }

  void add(String text) {
    if (!_canEdit() || text.trim().isEmpty) return;
    final task = Task('${_nextId++}', text.trim());
    _habits.add(task);
    _days[_key(_today)]!.add(task.copy());
    save();
  }

  void move(Task task, bool done) {
    if (!_canEdit() || !tasks.contains(task)) return;
    task.done = done;
    save();
  }

  void rename(Task task, String text) {
    if (!_canEdit() || !tasks.contains(task) || text.trim().isEmpty) return;
    task.title = text.trim();
    _habits.firstWhere((habit) => habit.id == task.id).title = task.title;
    save();
  }

  void remove(Task task) {
    if (!_canEdit() || !tasks.contains(task)) return;
    _habits.removeWhere((habit) => habit.id == task.id);
    _days[_key(_today)]!.remove(task);
    save();
  }
}
