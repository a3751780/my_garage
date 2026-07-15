import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vehicles/data/vehicle.dart';
import '../../vehicles/providers/vehicles_providers.dart';
import '../data/maintenance_record.dart';
import '../providers/maintenance_records_providers.dart';

class AddMaintenanceRecordPage extends ConsumerStatefulWidget {
  const AddMaintenanceRecordPage({
    super.key,
    required this.vehicle,
    this.record,
  });

  final Vehicle vehicle;
  final MaintenanceRecord? record;

  @override
  ConsumerState<AddMaintenanceRecordPage> createState() =>
      _AddMaintenanceRecordPageState();
}

class _AddMaintenanceRecordPageState
    extends ConsumerState<AddMaintenanceRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _dateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _servicedAt = DateTime.now();
  MaintenanceServiceType _serviceType = MaintenanceServiceType.shop;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;

    if (record != null) {
      _servicedAt = record.servicedAt;
      _itemController.text = record.item;
      _dateController.text = _formatDisplayDate(record.servicedAt);
      _odometerController.text = record.odometer.toString();
      _amountController.text = record.amount.toString();
      _serviceType = record.serviceType;
      _noteController.text = record.note ?? '';
      return;
    }

    _dateController.text = _formatDisplayDate(_servicedAt);
    _odometerController.text = widget.vehicle.currentMileage.toString();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _dateController.dispose();
    _odometerController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '編輯保養改裝紀錄' : '新增保養改裝紀錄')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _itemController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '項目',
                  hintText: '例如 機油、輪胎、煞車皮',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入保養項目';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '日期',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _odometerController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '里程',
                  hintText: '公里',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
                validator: _validatePositiveInt,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '金額',
                  hintText: '本次保養費用',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: _validatePositiveNumber,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MaintenanceServiceType>(
                value: _serviceType,
                decoration: const InputDecoration(
                  labelText: '施工方式',
                  prefixIcon: Icon(Icons.handyman_outlined),
                ),
                items: MaintenanceServiceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() => _serviceType = value);
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '備註',
                  hintText: '可留空',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveMaintenanceRecord,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isEditing ? '更新保養改裝紀錄' : '儲存保養改裝紀錄'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _servicedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _servicedAt = selectedDate;
      _dateController.text = _formatDisplayDate(selectedDate);
    });
  }

  Future<void> _saveMaintenanceRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final input = NewMaintenanceRecordInput(
        vehicleId: widget.vehicle.id,
        item: _itemController.text.trim(),
        servicedAt: _servicedAt,
        odometer: int.parse(_odometerController.text.trim()),
        amount: double.parse(_amountController.text.trim()),
        serviceType: _serviceType,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      final record = widget.record;
      if (record == null) {
        await ref
            .read(maintenanceRecordsRepositoryProvider)
            .addMaintenanceRecord(input);
      } else {
        await ref
            .read(maintenanceRecordsRepositoryProvider)
            .updateMaintenanceRecord(
              recordId: record.id,
              input: input,
            );
      }

      ref.invalidate(maintenanceRecordsProvider(widget.vehicle.id));
      ref.invalidate(vehiclesViewModelProvider);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _isSaving = false;
        _errorMessage = error.toString();
      });
    }
  }

  String? _validatePositiveInt(String? value) {
    final number = int.tryParse(value?.trim() ?? '');

    if (number == null || number < 0) {
      return '請輸入 0 以上的整數';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value) {
    final number = double.tryParse(value?.trim() ?? '');

    if (number == null || number < 0) {
      return '請輸入 0 以上的金額';
    }

    return null;
  }

  String _formatDisplayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}/$month/$day';
  }
}
