import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/vehicle.dart';
import '../providers/vehicles_providers.dart';

class AddVehiclePage extends ConsumerStatefulWidget {
  const AddVehiclePage({super.key});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _initialMileageController = TextEditingController();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _coverImageBytes;
  String? _coverImageFileName;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _initialMileageController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('新增車輛')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CoverImagePicker(
                imageBytes: _coverImageBytes,
                onPickImage: _pickCoverImage,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _modelController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '車款',
                  hintText: '例如 Yamaha Cygnus Gryphus',
                  prefixIcon: Icon(Icons.two_wheeler),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入車款';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '年份',
                  hintText: '例如 2024',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                validator: _validateYear,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialMileageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '購入初始里程',
                  hintText: '取得這台車時的里程',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: _validatePositiveInt,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '目前里程',
                  hintText: '公里',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
                validator: _validatePositiveInt,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '取得成本',
                  hintText: '購車或入手成本',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: _validatePositiveNumber,
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
                onPressed: _isSaving ? null : _saveVehicle,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('儲存車輛'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    setState(() {
      _coverImageBytes = bytes;
      _coverImageFileName = image.name;
      _errorMessage = null;
    });
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final initialMileage = int.parse(_initialMileageController.text.trim());
    final currentMileage = int.parse(_mileageController.text.trim());

    if (currentMileage < initialMileage) {
      setState(() {
        _errorMessage = '目前里程不可小於購入初始里程';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(vehiclesViewModelProvider.notifier).addVehicle(
            NewVehicleInput(
              model: _modelController.text.trim(),
              year: int.parse(_yearController.text.trim()),
              initialMileage: initialMileage,
              currentMileage: currentMileage,
              acquisitionCost: double.parse(_costController.text.trim()),
              coverImageBytes: _coverImageBytes,
              coverImageFileName: _coverImageFileName,
            ),
          );

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

  String? _validateYear(String? value) {
    final year = int.tryParse(value?.trim() ?? '');
    final currentYear = DateTime.now().year + 1;

    if (year == null) {
      return '請輸入有效年份';
    }

    if (year < 1900 || year > currentYear) {
      return '年份需介於 1900 到 $currentYear';
    }

    return null;
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
}

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({
    required this.imageBytes,
    required this.onPickImage,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPickImage,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            image: imageBytes == null
                ? null
                : DecorationImage(
                    image: MemoryImage(imageBytes!),
                    fit: BoxFit.cover,
                  ),
          ),
          child: imageBytes == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '選擇封面照',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                )
              : Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FloatingActionButton.small(
                      heroTag: null,
                      onPressed: onPickImage,
                      child: const Icon(Icons.edit),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
