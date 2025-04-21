import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/task.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../utils/app_styles.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late List<Task> _tasks = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper.instance.getTasksByDate(_selectedDate);
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildCalendar(),
            _buildTaskList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyles.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _navigateToTaskForm(null),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Minhas Tarefas', style: AppStyles.headingStyle),
              Text(
                'Hoje',
                style: AppStyles.bodyStyle.copyWith(color: AppStyles.secondaryTextColor),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppStyles.primaryColor),
                onPressed: () {
                  // Botão de teste de notificações
                  NotificationService().showTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificação de teste enviada!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Testar notificação',
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppStyles.primaryLightColor,
                child: Icon(
                  Icons.person,
                  color: AppStyles.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppStyles.primaryLightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDate, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = DateTime(
              selectedDay.year,
              selectedDay.month,
              selectedDay.day,
            );
            _focusedDay = focusedDay;
          });
          _loadTasks();
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            color: AppStyles.primaryLightColor,
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppStyles.primaryColor,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: AppStyles.textColor),
          selectedTextStyle: const TextStyle(color: Colors.white),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppStyles.titleStyle,
          formatButtonDecoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppStyles.bodySmallStyle,
          weekendStyle: AppStyles.bodySmallStyle,
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return Expanded(
      child: _tasks.isEmpty
          ? Center(
              child: Text(
                'Nenhuma tarefa para hoje',
                style: AppStyles.bodyStyle,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return _buildTaskCard(task);
              },
            ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final startTime = task.startTime != null
        ? DateFormat('HH:mm').format(task.startTime!)
        : '';
    
    Color categoryColor = AppStyles.categoryColors[task.category] ?? 
        AppStyles.categoryColors['Geral']!;
        
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) async {
                await DatabaseHelper.instance.deleteTask(task.id!);
                await NotificationService().cancelNotification(task.id!);
                _loadTasks();
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Excluir',
              borderRadius: BorderRadius.circular(16),
            ),
            SlidableAction(
              onPressed: (_) {
                _navigateToTaskForm(task);
              },
              backgroundColor: AppStyles.accentColor,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Editar',
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => _navigateToTaskForm(task),
          child: Container(
            decoration: AppStyles.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (task.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.category,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        startTime,
                        style: AppStyles.bodySmallStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.title,
                    style: AppStyles.titleStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: AppStyles.bodyStyle,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 15,
                          child: Icon(
                            Icons.person_outline,
                            color: categoryColor,
                          ),
                        ),
                        Checkbox(
                          activeColor: AppStyles.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          value: task.isCompleted,
                          onChanged: (bool? value) async {
                            task.isCompleted = value!;
                            await DatabaseHelper.instance.updateTask(task);
                            _loadTasks();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTaskForm(Task? task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true) {
      _loadTasks();
    }
  }
}