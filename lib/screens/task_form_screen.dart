import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // Importação para função min

import '../models/task.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../utils/app_styles.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notificationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  String _selectedCategory = 'Desenvolvimento';
  int? _notifyMinutesBefore; // Novo campo para controlar a notificação
  bool _enableNotification = false; // Controle se a notificação está habilitada
  
  // Lista de opções predefinidas para notificação
  final List<int> _notificationOptions = [5, 10, 15, 30, 60, 120];
  
  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedCategory = widget.task!.category;
      
      if (widget.task!.startTime != null) {
        _startTime = TimeOfDay.fromDateTime(widget.task!.startTime!);
        _startTimeController.text = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      }
      
      if (widget.task!.endTime != null) {
        _endTime = TimeOfDay.fromDateTime(widget.task!.endTime!);
        _endTimeController.text = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
      }
      
      // Configurar notificação se existir
      if (widget.task!.notifyMinutesBefore != null) {
        _enableNotification = true;
        _notifyMinutesBefore = widget.task!.notifyMinutesBefore;
        _notificationController.text = _notifyMinutesBefore.toString();
      }
    } else {
      // Inicialização para nova tarefa
      _startTimeController.text = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      _endTimeController.text = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
    }
    
    // Adicionar listeners para formatar os campos de hora
    _startTimeController.addListener(_formatTimeInput);
    _endTimeController.addListener(_formatTimeInput);
  }
  
  @override
  void dispose() {
    // Remover listeners
    _startTimeController.removeListener(_formatTimeInput);
    _endTimeController.removeListener(_formatTimeInput);
    super.dispose();
  }
  
  void _formatTimeInput() {
    // Formato HH:MM para campos de hora
    final text = _startTimeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 0) {
      String formattedText = text;
      
      // Inserir dois pontos após os primeiros dois dígitos se houver mais de 2 dígitos
      if (text.length >= 3) {
        formattedText = '${text.substring(0, 2)}:${text.substring(2, min(4, text.length))}';
      }
      
      // Atualiza o valor do campo apenas se for diferente para evitar loop infinito
      if (_startTimeController.text != formattedText) {
        _startTimeController.value = TextEditingValue(
          text: formattedText,
          selection: TextSelection.collapsed(offset: formattedText.length),
        );
      }
    }
    
    // Fazer o mesmo para o campo endTimeController
    final endText = _endTimeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (endText.length > 0) {
      String formattedEndText = endText;
      
      if (endText.length >= 3) {
        formattedEndText = '${endText.substring(0, 2)}:${endText.substring(2, min(4, endText.length))}';
      }
      
      if (_endTimeController.text != formattedEndText) {
        _endTimeController.value = TextEditingValue(
          text: formattedEndText,
          selection: TextSelection.collapsed(offset: formattedEndText.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppStyles.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.task == null ? 'Criar Nova Tarefa' : 'Editar Tarefa',
          style: AppStyles.subHeadingStyle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo de nome da tarefa
              _buildSectionTitle('Nome da Tarefa'),
              _buildTextField(
                controller: _titleController,
                hintText: 'Reunião de Equipe',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Seleção de categoria
              _buildSectionTitle('Selecionar Categoria'),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              
              // Campo de data
              _buildSectionTitle('Data'),
              _buildDateSelector(),
              const SizedBox(height: 24),
              
              // Campos de horário
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Hora Início'),
                        _buildTextField(
                          controller: _startTimeController,
                          hintText: 'HH:mm',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira a hora de início';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            FilteringTextInputFormatter.allow(RegExp(r'^[0-2]?[0-9]?[0-5]?[0-9]?$')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Hora Término'),
                        _buildTextField(
                          controller: _endTimeController,
                          hintText: 'HH:mm',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira a hora de término';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            FilteringTextInputFormatter.allow(RegExp(r'^[0-2]?[0-9]?[0-5]?[0-9]?$')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Campo de descrição
              _buildSectionTitle('Descrição'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Discutir todas as questões sobre novos projetos',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Campo de notificação
              _buildSectionTitle('Notificação'),
              _buildNotificationSelector(),
              const SizedBox(height: 40),
              
              // Botão de criar/salvar
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.task == null ? 'Criar Tarefa' : 'Atualizar Tarefa',
                  style: AppStyles.titleStyle.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppStyles.bodyStyle.copyWith(
        color: AppStyles.secondaryTextColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppStyles.bodyStyle.copyWith(color: Colors.grey[400]),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppStyles.primaryColor),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppStyles.categories.map((category) {
              final bool isSelected = _selectedCategory == category;
              final color = AppStyles.categoryColors[category] ?? AppStyles.categoryColors['Geral']!;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Chip(
                    label: Text(category),
                    backgroundColor: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                    side: BorderSide(
                      color: isSelected ? color : Colors.transparent,
                      width: isSelected ? 1.5 : 0,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? color : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Implementar no futuro: mostrar todas as categorias
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Ver todas',
              style: AppStyles.bodySmallStyle.copyWith(
                color: AppStyles.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('EEEE, d MMMM', 'pt_BR');
    
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        child: Row(
          children: [
            Text(
              dateFormat.format(_selectedDate),
              style: AppStyles.bodyStyle,
            ),
            const Spacer(),
            const Icon(
              Icons.calendar_today_outlined,
              color: AppStyles.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Switch para ativar/desativar notificações
        Row(
          children: [
            Switch(
              value: _enableNotification,
              activeColor: AppStyles.primaryColor,
              onChanged: (value) {
                setState(() {
                  _enableNotification = value;
                  if (value && _notifyMinutesBefore == null) {
                    // Definir um valor padrão quando ativar as notificações
                    _notifyMinutesBefore = 30;
                    _notificationController.text = '30';
                  }
                });
              },
            ),
            Text(
              _enableNotification ? "Notificações ativadas" : "Notificações desativadas",
              style: AppStyles.bodyStyle,
            ),
          ],
        ),
        
        // Opções de tempo para notificação (visíveis apenas quando as notificações estão ativadas)
        if (_enableNotification) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _notificationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Notificar antes',
                    hintText: 'Minutos antes',
                    hintStyle: AppStyles.bodyStyle.copyWith(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppStyles.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixText: 'min',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _notifyMinutesBefore = int.tryParse(value);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppStyles.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppStyles.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        // Preservar apenas a data, sem alterar a hora original
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
      });
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Validar os formatos de hora
        if (!_validateTimeFormat(_startTimeController.text) || !_validateTimeFormat(_endTimeController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formato de hora inválido. Use o formato HH:MM (ex: 14:30)')),
          );
          return;
        }
        
        // Converter os horários para DateTime
        final startTimeParts = _startTimeController.text.split(':');
        final endTimeParts = _endTimeController.text.split(':');
        
        final startHour = int.parse(startTimeParts[0]);
        final startMinute = int.parse(startTimeParts[1]);
        final endHour = int.parse(endTimeParts[0]);
        final endMinute = int.parse(endTimeParts[1]);
        
        // Verificar se os horários são válidos
        if (startHour < 0 || startHour > 23 || startMinute < 0 || startMinute > 59 ||
            endHour < 0 || endHour > 23 || endMinute < 0 || endMinute > 59) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Horário inválido. Hora deve estar entre 00-23 e minutos entre 00-59')),
          );
          return;
        }
        
        final startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          startHour,
          startMinute,
        );
        
        final endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          endHour,
          endMinute,
        );
        
        // Verificar se hora de término é após hora de início
        if (endDateTime.isBefore(startDateTime)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A hora de término deve ser após a hora de início')),
          );
          return;
        }

        final task = Task(
          id: widget.task?.id,
          title: _titleController.text,
          description: _descriptionController.text,
          isCompleted: widget.task?.isCompleted ?? false,
          dueDate: _selectedDate,
          category: _selectedCategory,
          startTime: startDateTime,
          endTime: endDateTime,
          notifyMinutesBefore: _enableNotification ? _notifyMinutesBefore : null,
        );

        if (widget.task == null) {
          // Criar nova tarefa
          await DatabaseHelper.instance.createTask(task);
        } else {
          // Atualizar tarefa existente
          await DatabaseHelper.instance.updateTask(task);
        }
        
        // Agendar notificação
        await NotificationService().scheduleTaskNotification(task);
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar a tarefa: $e')),
          );
        }
        print('Erro ao salvar tarefa: $e');  // Para diagnóstico
      }
    }
  }
  
  // Método para validar o formato de hora (HH:MM)
  bool _validateTimeFormat(String timeStr) {
    final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):([0-5][0-9])$');
    return timeRegex.hasMatch(timeStr);
  }
}