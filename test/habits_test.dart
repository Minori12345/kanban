import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kanban/main.dart';
import 'package:kanban/view.dart';
import 'package:kanban/view_model.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final data = <String, String>{};
  @override
  Future<String?> getString(String key) async => data[key];
  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MemoryPreferences prefs;
  late DateTime now;
  late KanbanViewModel vm;
  setUp(() async {
    prefs = MemoryPreferences();
    now = DateTime(2026, 11, 6);
    vm = KanbanViewModel(preferences: prefs, now: () => now);
    await vm.load();
  });

  test('percentage, undo and restart preserve daily completion', () async {
    expect(vm.percentage, 0);
    for (var i = 0; i < 5; i++) {
      vm.add('習慣$i');
    }
    for (final task in vm.tasks.take(3)) {
      vm.move(task, true);
    }
    expect(vm.percentage, 60);
    for (final task in vm.tasks) {
      vm.move(task, true);
    }
    expect(vm.percentage, 100);
    vm.move(vm.tasks.first, false);
    expect(vm.percentage, 80);
    await vm.save();
    final restored = KanbanViewModel(preferences: prefs, now: () => now);
    await restored.load();
    expect(restored.percentage, 80);
    expect(restored.tasks.length, 5);
  });

  test(
    'new day resets, edits preserve history, skipped day has no record',
    () async {
      vm.add('読書');
      vm.move(vm.tasks.single, true);
      now = DateTime(2026, 11, 8);
      vm.refreshDate();
      expect(vm.completed, 0);
      vm.rename(vm.tasks.single, 'ストレッチ');
      vm.add('歯磨き');
      vm.remove(vm.tasks.first);
      vm.selectDate(DateTime(2026, 11, 6));
      expect(vm.tasks.single.title, '読書');
      expect(vm.percentage, 100);
      vm.add('変更不可');
      vm.move(vm.tasks.single, false);
      vm.rename(vm.tasks.single, '変更不可');
      vm.remove(vm.tasks.single);
      expect(vm.tasks.single.title, '読書');
      expect(vm.completed, 1);
      vm.selectDate(DateTime(2026, 11, 7));
      expect(vm.hasRecord, false);
      vm.showToday();
      expect(vm.tasks.single.title, '歯磨き');
      vm.selectDate(DateTime(2026, 11, 9));
      expect(vm.isToday, true);
      await vm.save();
    },
  );

  test('legacy migration retains completed tasks and runs once', () async {
    prefs.data.remove('daily_habits');
    prefs.data['kanban'] = jsonEncode([
      {'title': '朝ごはん', 'status': 0},
      {'title': 'お風呂', 'status': 1},
      {'title': '歯磨き', 'status': 2},
    ]);
    await vm.load();
    expect(vm.tasks.map((task) => task.done), [false, false, true]);
    expect(vm.tasks.map((task) => task.id).toSet().length, 3);
    vm.remove(vm.tasks.first);
    await vm.save();
    await vm.load();
    expect(vm.tasks.length, 2);
  });

  testWidgets(
    'phone layout scrolls between two lanes and history is read only',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      vm.add('読書する');
      await tester.pumpWidget(
        MaterialApp(theme: habitTheme(), home: KanbanView(vm)),
      );
      expect(find.text('0%（0 / 1）'), findsOneWidget);
      await tester.tap(find.text('できた →'));
      await tester.pumpAndSettle();
      expect(find.text('100%（1 / 1）'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('← できてないに戻す').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      now = DateTime(2026, 11, 7);
      vm.refreshDate();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('前日'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('習慣の操作'), findsNothing);
      expect(find.text('100%（1 / 1）'), findsOneWidget);
      await tester.tap(find.byTooltip('前日'));
      await tester.pumpAndSettle();
      expect(find.text('記録なし'), findsOneWidget);
    },
  );
}
