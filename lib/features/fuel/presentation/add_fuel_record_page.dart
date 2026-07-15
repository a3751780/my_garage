import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vehicles/data/vehicle.dart';
import '../../vehicles/providers/vehicles_providers.dart';
import '../data/fuel_record.dart';
import '../providers/fuel_records_providers.dart';

class AddFuelRecordPage extends ConsumerStatefulWidget {
  const AddFuelRecordPage({
    super.key,
    required this.vehicle,
    this.record,
  });

  final Vehicle vehicle;
  final FuelRecord? record;

  @override
  ConsumerState<AddFuelRecordPage> createState() => _AddFuelRecordPageState();
}

class _AddFuelRecordPageState extends ConsumerState<AddFuelRecordPage> {
  static const _fuelTypes = ['92 無鉛', '95 無鉛', '98 無鉛', '柴油', '其他'];

  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _fuelVolumeController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _fueledAt = DateTime.now();
  String _fuelType = _fuelTypes.first;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;

    if (record != null) {
      _fueledAt = record.fueledAt;
      _fuelType = _fuelTypes.contains(record.fuelType)
          ? record.fuelType
          : _fuelTypes.last;
      _dateController.text = _formatDisplayDate(record.fueledAt);
      _odometerController.text = record.odometer.toString();
      _fuelVolumeController.text = record.fuelVolume.toString();
      _amountController.text = record.amount.toString();
      _noteController.text = record.note ?? '';
      return;
    }

    _dateController.text = _formatDisplayDate(_fueledAt);
    _odometerController.text = widget.vehicle.currentMileage.toString();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _odometerController.dispose();
    _fuelVolumeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '編輯加油紀錄' : '新增加油紀錄')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
                controller: _fuelVolumeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '加油量',
                  hintText: '公升',
                  prefixIcon: Icon(Icons.local_gas_station_outlined),
                ),
                validator: _validatePositiveNumber,
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
                  hintText: '本次加油費用',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: _validatePositiveNumber,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _fuelType,
                decoration: const InputDecoration(
                  labelText: '油品',
                  prefixIcon: Icon(Icons.oil_barrel_outlined),
                ),
                items: _fuelTypes
                    .map(
                      (fuelType) => DropdownMenuItem(
                        value: fuelType,
                        child: Text(fuelType),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() => _fuelType = value);
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
                onPressed: _isSaving ? null : _saveFuelRecord,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isEditing ? '更新加油紀錄' : '儲存加油紀錄'),
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
      initialDate: _fueledAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _fueledAt = selectedDate;
      _dateController.text = _formatDisplayDate(selectedDate);
    });
  }

  Future<void> _saveFuelRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final input = NewFuelRecordInput(
        vehicleId: widget.vehicle.id,
        fueledAt: _fueledAt,
        odometer: int.parse(_odometerController.text.trim()),
        fuelVolume: double.parse(_fuelVolumeController.text.trim()),
        amount: double.parse(_amountController.text.trim()),
        fuelType: _fuelType,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      final record = widget.record;
      if (record == null) {
        await ref.read(fuelRecordsRepositoryProvider).addFuelRecord(input);
      } else {
        await ref.read(fuelRecordsRepositoryProvider).updateFuelRecord(
              recordId: record.id,
              input: input,
            );
      }

      ref.invalidate(fuelRecordsProvider(widget.vehicle.id));
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

    if (number == null || number <= 0) {
      return '請輸入大於 0 的數字';
    }

    return null;
  }

  String _formatDisplayDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}/$month/$day';
  }
}
