import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:task_manager/models/task.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initNotification() async {
    // Inicialização do timezone
    tz.initializeTimeZones();
    
    // Definir timezone local como Brasil/São Paulo
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Configurações para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações de inicialização
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Manipula o clique na notificação
        debugPrint('Notificação clicada: ${notificationResponse.payload}');
      },
    );
    
    // Solicitar permissão explicitamente
    await _requestPermissions();
    
    // Criar canal de notificação com alta importância
    await _createNotificationChannel();
  }
  
  Future<void> _requestPermissions() async {
    // Para versão 19.1.0 do flutter_local_notifications
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      // Usar o método de permissão compatível com a versão 19.1.0
      await androidPlugin.requestNotificationsPermission();
    }
  }
  
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_channel',
      'Lembretes de Tarefas',
      description: 'Notificações para lembrar sobre tarefas',
      importance: Importance.high,
    );
    
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  // Agenda uma notificação para uma tarefa
  Future<void> scheduleTaskNotification(Task task) async {
    if (task.id == null) return;
    
    // Cancelar qualquer notificação existente para essa tarefa
    await cancelNotification(task.id!);
    
    // Se notifyMinutesBefore for null, significa que o usuário não quer notificação
    if (task.notifyMinutesBefore == null) return;
    
    // Calcula o tempo de notificação baseado nos minutos definidos pelo usuário
    final DateTime notificationTime = task.startTime != null 
        ? task.startTime!.subtract(Duration(minutes: task.notifyMinutesBefore!))
        : task.dueDate.subtract(Duration(minutes: task.notifyMinutesBefore!));
    
    // Não agendar se a data já passou
    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint('Não agendando notificação pois a data já passou: ${notificationTime.toString()}');
      return;
    }

    // Para debug
    debugPrint('Agendando notificação para: ${notificationTime.toString()}');
    debugPrint('Minutos antes: ${task.notifyMinutesBefore}');
    
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!,
        'Lembrete de Tarefa: ${task.title}',
        'A tarefa "${task.title}" começará em ${task.notifyMinutesBefore} minutos',
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Lembretes de Tarefas',
            channelDescription: 'Notificações para lembrar sobre tarefas',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'Lembrete de tarefa',
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Notificação agendada com sucesso.');
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
  }

  // Para testar se as notificações funcionam
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Lembretes de Tarefas',
      channelDescription: 'Notificações para lembrar sobre tarefas',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      0, 
      'Teste de Notificação',
      'Esta é uma notificação de teste para verificar se está funcionando',
      platformDetails,
    );
  }

  // Cancelar uma notificação específica
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}