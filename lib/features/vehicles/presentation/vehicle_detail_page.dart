import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../fuel/data/fuel_record.dart';
import '../../fuel/data/fuel_analytics.dart';
import '../../fuel/presentation/add_fuel_record_page.dart';
import '../../fuel/providers/fuel_records_providers.dart';
import '../../maintenance/data/maintenance_record.dart';
import '../../maintenance/presentation/add_maintenance_record_page.dart';
import '../../maintenance/providers/oil_change_preferences_provider.dart';
import '../../maintenance/providers/maintenance_records_providers.dart';
import '../data/vehicle.dart';
import '../providers/vehicles_providers.dart';

const _vehicleHeaderExpandedHeight = 370.0;

class VehicleDetailPage extends ConsumerStatefulWidget {
  const VehicleDetailPage({
    super.key,
    required this.vehicle,
  });

  final Vehicle vehicle;

  @override
  ConsumerState<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends ConsumerState<VehicleDetailPage> {
  final _imagePicker = ImagePicker();
  late Vehicle _vehicle;
  bool _isUpdatingCover = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: _vehicleHeaderExpandedHeight,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: colorScheme.onSurface,
            flexibleSpace: _VehicleFlexibleSpace(
              title: _vehicle.model,
              header: _VehicleHeader(
                vehicle: _vehicle,
                isUpdatingCover: _isUpdatingCover,
                onChangeCoverImage: _changeCoverImage,
                onUpdateMileage: _showUpdateMileageDialog,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.list(
              children: [
                _OilChangeProgressSection(vehicle: _vehicle),
                const SizedBox(height: 16),
                _RefuelProgressSection(vehicle: _vehicle),
                const SizedBox(height: 16),
                _FuelAnalyticsSection(vehicle: _vehicle),
                const SizedBox(height: 16),
                _FuelRecordsSection(vehicle: _vehicle),
                const SizedBox(height: 16),
                _MaintenanceRecordsSection(vehicle: _vehicle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeCoverImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null) {
      return;
    }

    setState(() => _isUpdatingCover = true);

    try {
      final updatedVehicle =
          await ref.read(vehiclesRepositoryProvider).updateVehicleCoverImage(
                vehicleId: _vehicle.id,
                bytes: await image.readAsBytes(),
                fileName: image.name,
                previousCoverImagePath: _vehicle.coverImagePath,
              );

      ref.invalidate(vehiclesViewModelProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _vehicle = updatedVehicle;
        _isUpdatingCover = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('車輛圖片已更新')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isUpdatingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新圖片失敗：$error')),
      );
    }
  }

  Future<void> _showUpdateMileageDialog() async {
    final updatedMileage = await showDialog<int>(
      context: context,
      builder: (context) => _UpdateMileageDialog(vehicle: _vehicle),
    );

    if (updatedMileage == null) {
      return;
    }

    try {
      final updatedVehicle =
          await ref.read(vehiclesRepositoryProvider).updateCurrentMileage(
                vehicleId: _vehicle.id,
                currentMileage: updatedMileage,
              );

      ref.invalidate(vehiclesViewModelProvider);

      if (!mounted) {
        return;
      }

      setState(() => _vehicle = updatedVehicle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前里程已更新')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新里程失敗：$error')),
      );
    }
  }
}

class _VehicleFlexibleSpace extends StatelessWidget {
  const _VehicleFlexibleSpace({
    required this.title,
    required this.header,
  });

  final String title;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final minExtent = settings?.minExtent ?? kToolbarHeight;
    final maxExtent = settings?.maxExtent ?? minExtent;
    final currentExtent = settings?.currentExtent ?? maxExtent;
    final collapseProgress = maxExtent == minExtent
        ? 1.0
        : (1 - (currentExtent - minExtent) / (maxExtent - minExtent)).clamp(
            0.0,
            1.0,
          );
    final titleOpacity = ((collapseProgress - 0.62) / 0.38).clamp(0.0, 1.0);
    final headerOpacity = (1 - ((collapseProgress - 0.58) / 0.3)).clamp(
      0.0,
      1.0,
    );
    final toolbarBackgroundColor =
        Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ColoredBox(color: toolbarBackgroundColor),
        ),
        ClipRect(
          child: Opacity(
            opacity: headerOpacity,
            child: IgnorePointer(
              ignoring: headerOpacity == 0,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: maxExtent,
                child: SizedBox(
                  height: maxExtent,
                  child: header,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 56,
          right: 16,
          top: MediaQuery.paddingOf(context).top,
          height: kToolbarHeight,
          child: IgnorePointer(
            child: Opacity(
              opacity: titleOpacity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({
    required this.vehicle,
    required this.isUpdatingCover,
    required this.onChangeCoverImage,
    required this.onUpdateMileage,
  });

  final Vehicle vehicle;
  final bool isUpdatingCover;
  final VoidCallback onChangeCoverImage;
  final VoidCallback onUpdateMileage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 230,
            child: Stack(
              fit: StackFit.expand,
              children: [
                vehicle.coverImageUrl == null
                    ? ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.motorcycle_rounded,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Image.network(
                        vehicle.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.24),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FilledButton.icon(
                    onPressed: isUpdatingCover ? null : onChangeCoverImage,
                    icon: isUpdatingCover
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined),
                    label: Text(isUpdatingCover ? '更新中' : '更換封面'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _vehicleHeaderExpandedHeight - 200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.flag_outlined,
                        label: '初始 ${vehicle.initialMileage} km',
                      ),
                      _InfoChip(
                        icon: Icons.speed_outlined,
                        label: '目前 ${vehicle.currentMileage} km',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    _InfoChip(
                      icon: Icons.calendar_month_outlined,
                      label: '${vehicle.year}',
                    ),
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: '\$${vehicle.acquisitionCost.toStringAsFixed(0)}',
                    ),
                  ]),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: onUpdateMileage,
                      icon: const Icon(Icons.edit_road_outlined),
                      label: const Text('更新目前里程'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OilChangeProgressSection extends ConsumerWidget {
  const _OilChangeProgressSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceRecordsState = ref.watch(
      maintenanceRecordsProvider(vehicle.id),
    );
    final intervalState = ref.watch(oilChangeIntervalProvider(vehicle.id));

    return intervalState.when(
      data: (oilChangeInterval) => maintenanceRecordsState.when(
        data: (records) {
          final lastOilRecord = _findLastOilRecord(records);

          if (lastOilRecord == null) {
            return _OilChangeProgressCard.empty(
              interval: oilChangeInterval,
              onChangeInterval: () => _showIntervalDialog(
                context,
                ref,
                oilChangeInterval,
              ),
            );
          }

          final drivenMileage = vehicle.currentMileage - lastOilRecord.odometer;
          final safeDrivenMileage = drivenMileage < 0 ? 0 : drivenMileage;
          final remainingMileage = oilChangeInterval - safeDrivenMileage;
          final progress = (safeDrivenMileage / oilChangeInterval).clamp(
            0.0,
            1.0,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _OilChangeProgressCard(
              interval: oilChangeInterval,
              lastChangedMileage: lastOilRecord.odometer,
              currentMileage: vehicle.currentMileage,
              drivenMileage: safeDrivenMileage,
              remainingMileage: remainingMileage,
              progress: progress,
              onChangeInterval: () => _showIntervalDialog(
                context,
                ref,
                oilChangeInterval,
              ),
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(
                  maintenanceRecordsProvider(vehicle.id),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('重新整理'),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(oilChangeIntervalProvider(vehicle.id)),
              icon: const Icon(Icons.refresh),
              label: const Text('重新整理'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showIntervalDialog(
    BuildContext context,
    WidgetRef ref,
    int currentInterval,
  ) async {
    final interval = await showDialog<int>(
      context: context,
      builder: (context) => _OilChangeIntervalDialog(
        currentInterval: currentInterval,
      ),
    );

    if (interval == null) {
      return;
    }

    await ref.read(oilChangeIntervalRepositoryProvider).saveInterval(
          vehicleId: vehicle.id,
          interval: interval,
        );
    ref.invalidate(oilChangeIntervalProvider(vehicle.id));
  }

  MaintenanceRecord? _findLastOilRecord(List<MaintenanceRecord> records) {
    final oilRecords = records
        .where((record) => record.item.trim().contains('機油'))
        .toList()
      ..sort((a, b) => b.odometer.compareTo(a.odometer));

    return oilRecords.isEmpty ? null : oilRecords.first;
  }
}

class _OilChangeProgressCard extends StatelessWidget {
  const _OilChangeProgressCard({
    required this.interval,
    required this.lastChangedMileage,
    required this.currentMileage,
    required this.drivenMileage,
    required this.remainingMileage,
    required this.progress,
    required this.onChangeInterval,
  }) : isEmpty = false;

  const _OilChangeProgressCard.empty({
    required this.interval,
    required this.onChangeInterval,
  })  : lastChangedMileage = 0,
        currentMileage = 0,
        drivenMileage = 0,
        remainingMileage = interval,
        progress = 0,
        isEmpty = true;

  final int interval;
  final int lastChangedMileage;
  final int currentMileage;
  final int drivenMileage;
  final int remainingMileage;
  final double progress;
  final bool isEmpty;
  final VoidCallback onChangeInterval;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOverdue = !isEmpty && remainingMileage <= 0;
    final statusColor = isOverdue ? colorScheme.error : colorScheme.primary;
    final statusText = isEmpty
        ? '新增一筆「機油」保養紀錄後開始追蹤'
        : isOverdue
            ? '已超過 ${remainingMileage.abs()} km'
            : '還可騎 $remainingMileage km';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.opacity,
                  color:
                      isOverdue ? colorScheme.onError : colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOverdue ? '該換機油了' : '下次機油更換',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isOverdue
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isOverdue
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '設定更換里程',
                onPressed: onChangeInterval,
                icon: Icon(
                  Icons.tune,
                  color: isOverdue
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          if (isEmpty)
            Text(
              '目前規則：每 $interval km 更換一次機油。',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.build_outlined,
                  label: '上次 $lastChangedMileage km',
                ),
                _InfoChip(
                  icon: Icons.speed_outlined,
                  label: '目前 $currentMileage km',
                ),
                _InfoChip(
                  icon: Icons.route_outlined,
                  label: '已騎 $drivenMileage km',
                ),
                _InfoChip(
                  icon: Icons.tune,
                  label: '週期 $interval km',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OilChangeIntervalDialog extends StatefulWidget {
  const _OilChangeIntervalDialog({required this.currentInterval});

  final int currentInterval;

  @override
  State<_OilChangeIntervalDialog> createState() =>
      _OilChangeIntervalDialogState();
}

class _OilChangeIntervalDialogState extends State<_OilChangeIntervalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(
      text: widget.currentInterval.toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('設定機油更換里程'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _intervalController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '更換週期',
            hintText: '例如 1000',
            suffixText: 'km',
            prefixIcon: Icon(Icons.tune),
          ),
          validator: (value) {
            final interval = int.tryParse(value?.trim() ?? '');

            if (interval == null || interval <= 0) {
              return '請輸入大於 0 的整數';
            }

            if (interval > 50000) {
              return '週期不可超過 50000 km';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              int.parse(_intervalController.text.trim()),
            );
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _UpdateMileageDialog extends StatefulWidget {
  const _UpdateMileageDialog({required this.vehicle});

  final Vehicle vehicle;

  @override
  State<_UpdateMileageDialog> createState() => _UpdateMileageDialogState();
}

class _UpdateMileageDialogState extends State<_UpdateMileageDialog> {
  late final TextEditingController _mileageController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _mileageController = TextEditingController(
      text: widget.vehicle.currentMileage.toString(),
    );
  }

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更新目前里程'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _mileageController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '目前里程',
            hintText: '公里',
            helperText: '初始里程：${widget.vehicle.initialMileage} km',
            prefixIcon: const Icon(Icons.speed_outlined),
          ),
          validator: (value) {
            final mileage = int.tryParse(value?.trim() ?? '');

            if (mileage == null || mileage < 0) {
              return '請輸入 0 以上的整數';
            }

            if (mileage < widget.vehicle.initialMileage) {
              return '目前里程不可小於初始里程';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              int.parse(_mileageController.text.trim()),
            );
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _FuelRecordsSection extends StatelessWidget {
  const _FuelRecordsSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: '加油紀錄',
      icon: Icons.local_gas_station_outlined,
      action: TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AddFuelRecordPage(vehicle: vehicle),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      child: _FuelRecordsContent(vehicle: vehicle),
    );
  }
}

class _FuelRecordsContent extends ConsumerWidget {
  const _FuelRecordsContent({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelRecordsState = ref.watch(fuelRecordsProvider(vehicle.id));

    return fuelRecordsState.when(
      data: (records) {
        return Column(
          children: [
            const _DataHeader(
              labels: ['日期', '里程', '加油量', '金額', '油品'],
              flexes: [2, 1, 1, 1, 1],
            ),
            if (records.isEmpty)
              const _EmptySectionHint(message: '尚無加油紀錄')
            else
              ...records.take(5).map(
                    (record) => _FuelRecordRow(
                      record: record,
                      vehicle: vehicle,
                    ),
                  ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(fuelRecordsProvider(vehicle.id)),
              icon: const Icon(Icons.refresh),
              label: const Text('重新整理'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelRecordRow extends ConsumerWidget {
  const _FuelRecordRow({
    required this.record,
    required this.vehicle,
  });

  final FuelRecord record;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onLongPress: () => _showRecordActions(
        context: context,
        onEdit: () => _editRecord(context),
        onDelete: () => _deleteRecord(context, ref),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            _CellText(
              _formatDate(record.fueledAt),
              flex: 2,
              preserveFullText: true,
            ),
            _CellText('${record.odometer}'),
            _CellText('${record.fuelVolume.toStringAsFixed(2)}L'),
            _CellText('\$${record.amount.toStringAsFixed(0)}'),
            _CellText(record.fuelType),
          ],
        ),
      ),
    );
  }

  void _editRecord(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddFuelRecordPage(
          vehicle: vehicle,
          record: record,
        ),
      ),
    );
  }

  Future<void> _deleteRecord(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await _confirmDelete(
      context: context,
      title: '刪除加油紀錄',
      message: '確定要刪除這筆加油紀錄嗎？',
    );

    if (!shouldDelete) {
      return;
    }

    try {
      await ref.read(fuelRecordsRepositoryProvider).deleteFuelRecord(
            recordId: record.id,
            vehicleId: vehicle.id,
          );
      ref.invalidate(fuelRecordsProvider(vehicle.id));
      ref.invalidate(vehiclesViewModelProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加油紀錄已刪除')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除加油紀錄失敗：$error')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}/$month/$day';
  }
}

class _CellText extends StatelessWidget {
  const _CellText(
    this.text, {
    this.flex = 1,
    this.preserveFullText = false,
  });

  final String text;
  final int flex;
  final bool preserveFullText;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      maxLines: 1,
      overflow: preserveFullText ? TextOverflow.visible : TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );

    return Expanded(
      flex: flex,
      child: preserveFullText
          ? FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: textWidget,
            )
          : textWidget,
    );
  }
}

Future<void> _showRecordActions({
  required BuildContext context,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) async {
  final action = await showModalBottomSheet<_RecordAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('修改'),
              onTap: () => Navigator.of(context).pop(_RecordAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('刪除'),
              onTap: () => Navigator.of(context).pop(_RecordAction.delete),
            ),
          ],
        ),
      );
    },
  );

  switch (action) {
    case _RecordAction.edit:
      onEdit();
    case _RecordAction.delete:
      onDelete();
    case null:
      return;
  }
}

enum _RecordAction { edit, delete }

Future<bool> _confirmDelete({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('刪除'),
            ),
          ],
        ),
      ) ??
      false;
}

class _FuelAnalyticsSection extends ConsumerWidget {
  const _FuelAnalyticsSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleId = vehicle.id;
    final fuelRecordsState = ref.watch(fuelRecordsProvider(vehicleId));

    return _DetailSection(
      title: '油耗分析',
      icon: Icons.query_stats_outlined,
      child: fuelRecordsState.when(
        data: (records) {
          final analytics = FuelAnalytics.fromRecords(
            records,
            currentMileage: vehicle.currentMileage,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricTile(
                    label: '單次油耗',
                    value: _formatEfficiency(analytics.latestFuelEfficiency),
                  ),
                  _MetricTile(
                    label: '平均油耗',
                    value: _formatEfficiency(analytics.averageFuelEfficiency),
                  ),
                  _MetricTile(
                    label: '每公里成本',
                    value: _formatCostPerKilometer(
                      analytics.costPerKilometer,
                    ),
                  ),
                  _MetricTile(
                    label: '月油資',
                    value: _formatMoney(analytics.monthlyFuelCost),
                  ),
                ],
              ),
              if (!analytics.hasEnoughRecordsForEfficiency) ...[
                const SizedBox(height: 12),
                const _AnalyticsHint(
                  message: '累積至少 2 筆不同里程的加油紀錄後，會開始計算油耗。',
                ),
              ],
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(fuelRecordsProvider(vehicleId)),
                icon: const Icon(Icons.refresh),
                label: const Text('重新整理'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEfficiency(double? value) {
    if (value == null) {
      return '資料不足';
    }

    return '${value.toStringAsFixed(1)} km/L';
  }

  String _formatCostPerKilometer(double? value) {
    if (value == null) {
      return '資料不足';
    }

    return '\$${value.toStringAsFixed(2)}/km';
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }
}

class _RefuelProgressSection extends ConsumerWidget {
  const _RefuelProgressSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelRecordsState = ref.watch(fuelRecordsProvider(vehicle.id));

    return fuelRecordsState.when(
      data: (records) {
        final analytics = FuelAnalytics.fromRecords(
          records,
          currentMileage: vehicle.currentMileage,
        );

        return _RefuelProgressCard(
          analytics: analytics,
          currentMileage: vehicle.currentMileage,
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(fuelRecordsProvider(vehicle.id)),
              icon: const Icon(Icons.refresh),
              label: const Text('重新整理'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefuelProgressCard extends StatelessWidget {
  const _RefuelProgressCard({
    required this.analytics,
    required this.currentMileage,
  });

  final FuelAnalytics analytics;
  final int currentMileage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canEstimate = analytics.canEstimateRefuel;
    final remainingMileage = analytics.remainingMileageToRefuel ?? 0;
    final isDue = canEstimate && remainingMileage <= 0;
    final isLow =
        canEstimate && !isDue && (analytics.refuelProgress ?? 0) >= 0.8;
    final statusColor = isDue
        ? colorScheme.error
        : isLow
            ? Colors.orange.shade700
            : colorScheme.primary;
    final containerColor = isDue
        ? colorScheme.errorContainer
        : isLow
            ? Colors.orange.shade100
            : colorScheme.primaryContainer;
    final onContainerColor = isDue
        ? colorScheme.onErrorContainer
        : isLow
            ? Colors.orange.shade900
            : colorScheme.onPrimaryContainer;
    final title = !canEstimate
        ? '預估加油'
        : isDue
            ? '差不多該加油了'
            : isLow
                ? '油量可能偏低'
                : '預估還能騎';
    final statusText = !canEstimate
        ? '累積 2 筆加油紀錄後開始推估'
        : isDue
            ? '已超過 ${remainingMileage.abs().toStringAsFixed(0)} km'
            : '還可騎 ${remainingMileage.toStringAsFixed(0)} km';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_gas_station_outlined,
                  color: isDue ? colorScheme.onError : colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: onContainerColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: onContainerColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: analytics.refuelProgress ?? 0,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.58),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          if (!canEstimate)
            Text(
              '會以每次加油後視為滿油，並用最大單次加油量推估油箱容量。',
              style: TextStyle(color: onContainerColor),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.local_gas_station_outlined,
                  label: '上次 ${analytics.lastFueledMileage} km',
                ),
                _InfoChip(
                  icon: Icons.speed_outlined,
                  label: '目前 $currentMileage km',
                ),
                _InfoChip(
                  icon: Icons.route_outlined,
                  label: '已騎 ${analytics.drivenSinceLastFuel} km',
                ),
                _InfoChip(
                  icon: Icons.flag_outlined,
                  label: '建議 ${analytics.nextRefuelMileage} km',
                ),
                _InfoChip(
                  icon: Icons.opacity,
                  label:
                      '估 ${analytics.estimatedTankVolume!.toStringAsFixed(1)} L',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AnalyticsHint extends StatelessWidget {
  const _AnalyticsHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _MaintenanceRecordsSection extends StatelessWidget {
  const _MaintenanceRecordsSection({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: '保養改裝紀錄',
      icon: Icons.build_outlined,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddMaintenanceRecordPage(vehicle: vehicle),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('新增'),
          ),
        ],
      ),
      child: _MaintenanceRecordsContent(vehicle: vehicle),
    );
  }
}

class _MaintenanceRecordsContent extends ConsumerWidget {
  const _MaintenanceRecordsContent({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceRecordsState = ref.watch(
      maintenanceRecordsProvider(vehicle.id),
    );

    return maintenanceRecordsState.when(
      data: (records) {
        final totalCost = records.fold<double>(
          0,
          (total, record) => total + record.amount,
        );

        return Column(
          children: [
            _MaintenanceTotalCostCard(totalCost: totalCost),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAllMaintenanceRecordsDialog(
                  context,
                  records,
                ),
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('全部紀錄'),
              ),
            ),
            const SizedBox(height: 4),
            const _DataHeader(
              labels: ['項目', '日期', '里程', '金額', '方式'],
              flexes: [2, 2, 1, 1, 1],
            ),
            if (records.isEmpty)
              const _EmptySectionHint(message: '尚無保養改裝紀錄')
            else
              ...records.take(5).map(
                    (record) => _MaintenanceRecordRow(
                      record: record,
                      vehicle: vehicle,
                    ),
                  ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(
                maintenanceRecordsProvider(vehicle.id),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('重新整理'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllMaintenanceRecordsDialog(
    BuildContext context,
    List<MaintenanceRecord> records,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _AllMaintenanceRecordsDialog(
        records: records,
        vehicle: vehicle,
      ),
    );
  }
}

class _AllMaintenanceRecordsDialog extends StatelessWidget {
  const _AllMaintenanceRecordsDialog({
    required this.records,
    required this.vehicle,
  });

  final List<MaintenanceRecord> records;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedRecords = [...records]
      ..sort((a, b) => b.servicedAt.compareTo(a.servicedAt));

    return AlertDialog(
      title: const Text('全部保養改裝紀錄'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: sortedRecords.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('尚無保養改裝紀錄'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: sortedRecords.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    return _MaintenanceRecordDialogTile(
                      record: sortedRecords[index],
                      vehicle: vehicle,
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}

class _MaintenanceRecordDialogTile extends ConsumerWidget {
  const _MaintenanceRecordDialogTile({
    required this.record,
    required this.vehicle,
  });

  final MaintenanceRecord record;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onLongPress: () => _showRecordActions(
        context: context,
        onEdit: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => AddMaintenanceRecordPage(
                vehicle: vehicle,
                record: record,
              ),
            ),
          );
        },
        onDelete: () => _deleteMaintenanceRecord(
          context,
          ref,
          record,
          vehicle,
          closeDialogAfterDelete: true,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.item,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '\$${record.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _InfoChip(
                  icon: Icons.calendar_month_outlined,
                  label: _formatDate(record.servicedAt),
                ),
                _InfoChip(
                  icon: Icons.speed_outlined,
                  label: '${record.odometer} km',
                ),
                _InfoChip(
                  icon: Icons.handyman_outlined,
                  label: record.serviceType.label,
                ),
              ],
            ),
            if (record.note != null && record.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}/$month/$day';
  }
}

void _editMaintenanceRecord(
  BuildContext context,
  MaintenanceRecord record,
  Vehicle vehicle,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AddMaintenanceRecordPage(
        vehicle: vehicle,
        record: record,
      ),
    ),
  );
}

Future<void> _deleteMaintenanceRecord(
  BuildContext context,
  WidgetRef ref,
  MaintenanceRecord record,
  Vehicle vehicle, {
  bool closeDialogAfterDelete = false,
}) async {
  final shouldDelete = await _confirmDelete(
    context: context,
    title: '刪除保養改裝紀錄',
    message: '確定要刪除這筆保養改裝紀錄嗎？',
  );

  if (!shouldDelete) {
    return;
  }

  try {
    await ref
        .read(maintenanceRecordsRepositoryProvider)
        .deleteMaintenanceRecord(
          recordId: record.id,
          vehicleId: vehicle.id,
        );
    ref.invalidate(maintenanceRecordsProvider(vehicle.id));
    ref.invalidate(vehiclesViewModelProvider);

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (closeDialogAfterDelete) {
      Navigator.of(context).pop();
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('保養改裝紀錄已刪除')),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('刪除保養改裝紀錄失敗：$error')),
    );
  }
}

class _MaintenanceTotalCostCard extends StatelessWidget {
  const _MaintenanceTotalCostCard({required this.totalCost});

  final double totalCost;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8), // 這裡設定跟外層一樣的圓角
              child: Image.asset(
                'assets/images/nice.jpg',
                width: 25,
                height: 25,
                fit: BoxFit.cover, // 重要：確保圖片填滿區域，圓角才看得出來
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '保養改裝總花費',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalCost.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceRecordRow extends ConsumerWidget {
  const _MaintenanceRecordRow({
    required this.record,
    required this.vehicle,
  });

  final MaintenanceRecord record;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onLongPress: () => _showRecordActions(
        context: context,
        onEdit: () => _editMaintenanceRecord(context, record, vehicle),
        onDelete: () => _deleteMaintenanceRecord(
          context,
          ref,
          record,
          vehicle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            _CellText(record.item, flex: 2),
            _CellText(
              _formatDate(record.servicedAt),
              flex: 2,
              preserveFullText: true,
            ),
            _CellText('${record.odometer}'),
            _CellText('\$${record.amount.toStringAsFixed(0)}'),
            _CellText(record.serviceType.label),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}/$month/$day';
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DataHeader extends StatelessWidget {
  const _DataHeader({
    required this.labels,
    this.flexes,
  });

  final List<String> labels;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              flex: flexes?[index] ?? 1,
              child: Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 148,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
