import 'package:flutter/material.dart';
import 'model.dart';
import 'view_model.dart';

class KanbanView extends StatefulWidget {
  final KanbanViewModel vm;
  const KanbanView(this.vm, {super.key});

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> with WidgetsBindingObserver {
  final input = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.vm.refreshDate();
  }

  Future<void> edit(Task task) async {
    var text = task.title;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('習慣を編集'),
        content: TextFormField(
          initialValue: text,
          autofocus: true,
          onChanged: (value) => text = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) widget.vm.rename(task, result);
  }

  Widget taskCard(Task task) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = task.done ? scheme.onPrimary : scheme.onSurface;
    return Card(
      color: task.done ? scheme.primary : scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.done) ...[
                  Icon(Icons.check_circle, color: foreground, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(task.title, style: TextStyle(color: foreground)),
                ),
                if (widget.vm.isToday)
                  PopupMenuButton<String>(
                    tooltip: '習慣の操作',
                    iconColor: foreground,
                    onSelected: (value) {
                      if (value == 'edit') {
                        edit(task);
                      } else {
                        widget.vm.remove(task);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('編集')),
                      PopupMenuItem(value: 'delete', child: Text('削除')),
                    ],
                  ),
              ],
            ),
            if (widget.vm.isToday)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: foreground),
                onPressed: () => widget.vm.move(task, !task.done),
                child: Text(task.done ? '← できてないに戻す' : 'できた →'),
              ),
          ],
        ),
      ),
    );
  }

  Widget lane(bool done) {
    final cards = widget.vm.tasks.where((task) => task.done == done).toList();
    return SizedBox(
      width: 300,
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text(done ? 'できた' : 'できてない'),
              trailing: Text('${cards.length}件'),
            ),
            Expanded(
              child: ListView(
                children: [for (final task in cards) taskCard(task)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('毎日の習慣')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          final vm = widget.vm;
          final date = vm.selectedDate;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: '前日',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => vm.selectDate(
                      DateTime(date.year, date.month, date.day - 1),
                    ),
                  ),
                  Flexible(
                    child: Text('${date.year}/${date.month}/${date.day}'),
                  ),
                  IconButton(
                    tooltip: '翌日',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: vm.isToday
                        ? null
                        : () => vm.selectDate(
                            DateTime(date.year, date.month, date.day + 1),
                          ),
                  ),
                  TextButton(onPressed: vm.showToday, child: const Text('今日')),
                ],
              ),
              if (vm.hasRecord)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${vm.percentage}%（${vm.completed} / ${vm.tasks.length}）',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              if (vm.isToday)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: input,
                          decoration: const InputDecoration(
                            labelText: '毎日やること',
                            hintText: '例：ストレッチする',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ValueListenableBuilder(
                            valueListenable: input,
                            builder: (context, value, _) => FilledButton.icon(
                              onPressed: value.text.trim().isEmpty
                                  ? null
                                  : () {
                                      vm.add(input.text);
                                      input.clear();
                                    },
                              icon: const Icon(Icons.add),
                              label: const Text('追加'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: vm.hasRecord
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        children: [lane(false), lane(true)],
                      )
                    : const Center(child: Text('記録なし')),
              ),
            ],
          );
        },
      ),
    ),
  );
}
