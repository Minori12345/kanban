class Task {
  final String id;
  String title;
  bool done;

  Task(this.id, this.title, {this.done = false});

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    json['id'] as String,
    json['title'] as String,
    done: json['done'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  Task copy() => Task(id, title, done: done);
}
