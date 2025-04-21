class Task {
  int? id;
  String title;
  String description;
  bool isCompleted;
  DateTime dueDate;
  String category;
  DateTime? startTime;
  DateTime? endTime;
  int? notifyMinutesBefore; // Novo campo para armazenar minutos antes para notificação. Null significa sem notificação

  Task({
    this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.dueDate,
    this.category = 'Geral',
    this.startTime,
    this.endTime,
    this.notifyMinutesBefore,
  });

  // Converte uma Task para um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notifyMinutesBefore': notifyMinutesBefore,
    };
  }

  // Cria uma Task a partir de um Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      dueDate: DateTime.parse(map['dueDate']),
      category: map['category'] ?? 'Geral',
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      notifyMinutesBefore: map['notifyMinutesBefore'],
    );
  }

  // Clone task para edição
  Task copy({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    String? category,
    DateTime? startTime,
    DateTime? endTime,
    int? notifyMinutesBefore,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notifyMinutesBefore: notifyMinutesBefore ?? this.notifyMinutesBefore,
    );
  }
}