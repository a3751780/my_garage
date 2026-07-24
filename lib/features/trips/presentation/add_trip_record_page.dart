import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../vehicles/data/vehicle.dart';
import '../../vehicles/providers/vehicles_providers.dart';
import '../data/trip_record.dart';
import '../providers/trip_records_providers.dart';
import 'trip_location_picker_page.dart';

class AddTripRecordPage extends ConsumerStatefulWidget {
  const AddTripRecordPage({
    super.key,
    required this.initialDate,
  });

  final DateTime initialDate;

  @override
  ConsumerState<AddTripRecordPage> createState() => _AddTripRecordPageState();
}

class _AddTripRecordPageState extends ConsumerState<AddTripRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _dateController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _contentController = TextEditingController();

  late DateTime _tripDate;
  String? _vehicleId;
  double? _locationLatitude;
  double? _locationLongitude;
  List<XFile> _images = [];
  bool _isFilteringImages = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tripDate = _dateOnly(widget.initialDate);
    _dateController.text = _formatDisplayDate(_tripDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _odometerController.dispose();
    _costController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesState = ref.watch(vehiclesViewModelProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('新增騎旅紀錄'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: vehiclesState.when(
          data: (vehicles) {
            if (_vehicleId == null && vehicles.isNotEmpty) {
              _vehicleId = vehicles.first.id;
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  _ImagePickerPanel(
                    images: _images,
                    isFilteringImages: _isFilteringImages,
                    tripDate: _tripDate,
                    onPickImages: _pickImages,
                    onRemoveImage: _removeImage,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _vehicleId,
                    decoration: const InputDecoration(
                      labelText: '車輛',
                      prefixIcon: Icon(Icons.motorcycle_outlined),
                    ),
                    items: vehicles
                        .map(
                          (vehicle) => DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(vehicle.model),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _vehicleId = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請先選擇車輛';
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
                    onTap: _isSaving ? null : _pickDate,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '標題',
                      hintText: '例如 北海岸小跑',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '請輸入標題';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: '地點',
                      hintText: '透過地圖選取',
                      prefixIcon: const Icon(Icons.place_outlined),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_locationController.text.isNotEmpty)
                            IconButton(
                              tooltip: '清除地點',
                              onPressed: _isSaving ? null : _clearLocation,
                              icon: const Icon(Icons.close),
                            ),
                          IconButton(
                            tooltip: '開啟地圖',
                            onPressed: _isSaving ? null : _openLocationPicker,
                            icon: const Icon(Icons.map_outlined),
                          ),
                        ],
                      ),
                    ),
                    onTap: _isSaving ? null : _openLocationPicker,
                  ),
                  if (_locationLatitude != null &&
                      _locationLongitude != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_locationLatitude!.toStringAsFixed(6)}, '
                      '${_locationLongitude!.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _odometerController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '里程',
                            hintText: '可留空',
                            prefixIcon: Icon(Icons.speed_outlined),
                          ),
                          validator: _validateOptionalPositiveInt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '花費',
                            hintText: '可留空',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          validator: _validateOptionalPositiveNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    minLines: 6,
                    maxLines: 10,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: '文字紀錄',
                      hintText: '今天這段路、遇到的人、天氣、車況...',
                      alignLabelWithHint: true,
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
                    onPressed:
                        _isSaving ? null : () => _saveTripRecord(vehicles),
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('儲存騎旅紀錄'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (images.isEmpty) {
      return;
    }

    setState(() => _isFilteringImages = true);

    final matchedImages = <XFile>[];
    var skippedCount = 0;
    var noDateCount = 0;

    try {
      for (final image in images) {
        final takenAt = await _readImageTakenAt(image);

        if (takenAt == null) {
          noDateCount++;
          matchedImages.add(image);
          continue;
        }

        if (_isSameDate(takenAt, _tripDate)) {
          matchedImages.add(image);
        } else {
          skippedCount++;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isFilteringImages = false);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _images = [..._images, ...matchedImages].take(8).toList();
    });

    if (skippedCount > 0 || noDateCount > 0) {
      final messageParts = <String>[];

      if (skippedCount > 0) {
        messageParts
            .add('已排除 $skippedCount 張非 ${_formatDisplayDate(_tripDate)} 的照片');
      }

      if (noDateCount > 0) {
        messageParts.add('$noDateCount 張沒有拍攝日期，已先保留');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageParts.join('；'))),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images = [..._images]..removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _tripDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _tripDate = _dateOnly(selectedDate);
      _dateController.text = _formatDisplayDate(_tripDate);
      _images = [];
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日期已變更，請重新選擇該日期的照片')),
    );
  }

  Future<void> _saveTripRecord(List<Vehicle> vehicles) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (vehicles.isEmpty) {
      setState(() => _errorMessage = '請先建立至少一台車輛');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final imageInputs = <NewTripRecordImageInput>[];

      for (final image in _images) {
        imageInputs.add(
          NewTripRecordImageInput(
            bytes: await image.readAsBytes(),
            fileName: image.name,
          ),
        );
      }

      await ref.read(tripRecordsRepositoryProvider).addTripRecord(
            NewTripRecordInput(
              vehicleId: _vehicleId!,
              title: _titleController.text.trim(),
              content: _trimOrNull(_contentController.text),
              tripDate: _tripDate,
              odometer: _parseOptionalInt(_odometerController.text),
              location: _trimOrNull(_locationController.text),
              locationLatitude: _locationLatitude,
              locationLongitude: _locationLongitude,
              cost: _parseOptionalDouble(_costController.text) ?? 0,
              images: imageInputs,
            ),
          );

      ref.invalidate(tripDateRecordsProvider(_tripDate));
      ref.invalidate(tripMonthRecordsProvider(_monthOnly(_tripDate)));

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

  String? _validateOptionalPositiveInt(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final number = int.tryParse(text);

    if (number == null || number < 0) {
      return '請輸入 0 以上的整數';
    }

    return null;
  }

  String? _validateOptionalPositiveNumber(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final number = double.tryParse(text);

    if (number == null || number < 0) {
      return '請輸入 0 以上的數字';
    }

    return null;
  }

  int? _parseOptionalInt(String value) {
    final text = value.trim();
    return text.isEmpty ? null : int.parse(text);
  }

  double? _parseOptionalDouble(String value) {
    final text = value.trim();
    return text.isEmpty ? null : double.parse(text);
  }

  String? _trimOrNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _openLocationPicker() async {
    final selection = await Navigator.of(context).push<TripLocationSelection>(
      MaterialPageRoute(
        builder: (_) => TripLocationPickerPage(
          initialName: _trimOrNull(_locationController.text),
          initialLatitude: _locationLatitude,
          initialLongitude: _locationLongitude,
        ),
      ),
    );

    if (selection == null) {
      return;
    }

    setState(() {
      _locationController.text = selection.name;
      _locationLatitude = selection.latitude;
      _locationLongitude = selection.longitude;
    });
  }

  void _clearLocation() {
    setState(() {
      _locationController.clear();
      _locationLatitude = null;
      _locationLongitude = null;
    });
  }

  Future<DateTime?> _readImageTakenAt(XFile image) async {
    try {
      final tags = await readExifFromBytes(await image.readAsBytes());
      final dateTag = tags['EXIF DateTimeOriginal'] ??
          tags['EXIF DateTimeDigitized'] ??
          tags['Image DateTime'];
      final rawDate = dateTag?.printable;

      if (rawDate == null) {
        return null;
      }

      return _parseExifDate(rawDate);
    } catch (_) {
      return null;
    }
  }
}

class _ImagePickerPanel extends StatelessWidget {
  const _ImagePickerPanel({
    required this.images,
    required this.isFilteringImages,
    required this.tripDate,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  final List<XFile> images;
  final bool isFilteringImages;
  final DateTime tripDate;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '照片',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: isFilteringImages ? null : onPickImages,
                icon: isFilteringImages
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(isFilteringImages ? '篩選中' : '選擇當日照片'),
              ),
            ],
          ),
          Text(
            '會依 ${_formatDisplayDate(tripDate)} 過濾照片；沒有拍攝日期的照片會保留。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          if (images.isEmpty)
            AspectRatio(
              aspectRatio: 16 / 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 42,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _SelectedImageTile(
                    image: images[index],
                    onRemove: () => onRemoveImage(index),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedImageTile extends StatelessWidget {
  const _SelectedImageTile({
    required this.image,
    required this.onRemove,
  });

  final XFile image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List>(
            future: image.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 104,
                  height: 104,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Image.memory(
                snapshot.data!,
                width: 104,
                height: 104,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filled(
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
      ],
    );
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

DateTime? _parseExifDate(String rawDate) {
  final match = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(rawDate.trim());

  if (match == null) {
    return null;
  }

  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}

DateTime _monthOnly(DateTime date) {
  return DateTime(date.year, date.month);
}

String _formatDisplayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}/$month/$day';
}
