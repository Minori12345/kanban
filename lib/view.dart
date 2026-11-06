import 'package:flutter/material.dart';
import 'model.dart';
import 'view_model.dart';

final names = ['📝 未着手 (To Do)', '🔨 作業中 (Doing)', '✅ 完了 (Done)'];
final labels = ['未着手', '作業中', '完了'];
final colors = [Colors.blue.shade50, Colors.orange.shade50, Colors.green.shade50];

class KanbanView extends StatefulWidget {
  final KanbanViewModel vm;
  KanbanView(this.vm, {super.key});

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  final input = TextEditingController();

  void add() {
    widget.vm.add(input.text);
    input.clear();
  }

  Future<void> edit(Task t) async {
    var text = t.title;
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('タスクを編集'),
        content: TextFormField(
          initialValue: text,
          autofocus: true,
          onChanged: (v) => text = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, text),
            child: Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) widget.vm.rename(t, result);
  }

  Widget taskCard(Task t) {
    final s = t.status;
    final buttons = Wrap(spacing: 4, children: [
      if (s > 0)
        TextButton(
          onPressed: () => widget.vm.move(t, s - 1),
          child: Text('← ${labels[s - 1]}へ'),
        ),
      if (s < 2)
        FilledButton(
          onPressed: () => widget.vm.move(t, s + 1),
          child: Text('${labels[s + 1]}へ →'),
        ),
    ]);
    return Card(child: ListTile(
      title: Text(t.title),
      subtitle: buttons,
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () => edit(t),
      ),
    ));
  }

  Widget lane(int s) {
    final cards = [
      for (final t in widget.vm.tasks)
        if (t.status == s) taskCard(t),
    ];
    return SizedBox(
      width: 300,
      child: Card(
        color: colors[s],
        child: Column(children: [
          ListTile(
            title: Text(names[s]),
            trailing: Text('${cards.length}件'),
          ),
          Expanded(child: ListView(children: cards)),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: input,
      decoration: InputDecoration(
        labelText: '新しいタスク',
        hintText: '例：レポートを書く',
        border: OutlineInputBorder(),
      ),
    );
    final button = ValueListenableBuilder(
      valueListenable: input,
      builder: (context, value, child) => FilledButton.icon(
        onPressed: value.text.isEmpty ? null : add,
        icon: Icon(Icons.add),
        label: Text('未着手に追加'),
      ),
    );
    final entry = Card(child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(children: [
        field,
        Align(alignment: Alignment.centerRight, child: button),
      ]),
    ));
    final board = ListenableBuilder(
      listenable: widget.vm,
      builder: (context, child) => ListView(
        scrollDirection: Axis.horizontal,
        children: [for (int s = 0; s < 3; s++) lane(s)],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('📋 Kanban')),
      body: Column(children: [
        entry,
        Expanded(child: board),
      ]),
    );
  }
}