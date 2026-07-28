import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trips/presentation/trip_location_picker_page.dart';
import '../data/trip_route.dart';
import '../providers/trip_routes_providers.dart';

class AddTripRoutePage extends ConsumerStatefulWidget {
  const AddTripRoutePage({
    super.key,
    this.route,
  });

  final TripRoute? route;

  @override
  ConsumerState<AddTripRoutePage> createState() => _AddTripRoutePageState();
}

class _AddTripRoutePageState extends ConsumerState<AddTripRoutePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stops = <NewTripRouteStopInput>[];
  bool _isSaving = false;

  bool get _isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();

    final route = widget.route;
    if (route == null) {
      return;
    }

    _nameController.text = route.name;
    _descriptionController.text = route.description ?? '';
    _stops.addAll(route.stops.map(NewTripRouteStopInput.fromStop));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '修改騎旅路線' : '新增騎旅路線'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveRoute,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? '更新' : '儲存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '路線名稱',
                prefixIcon: Icon(Icons.route_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入路線名稱';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '備註',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _RouteStopsHeader(
              stopCount: _stops.length,
              onAddStop: _pickAndAddStop,
            ),
            const SizedBox(height: 12),
            if (_stops.isEmpty)
              _EmptyStopsPanel(onAddStop: _pickAndAddStop)
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _stops.length,
                onReorder: _reorderStop,
                itemBuilder: (context, index) {
                  return _RouteStopTile(
                    key: ValueKey('${_stops[index].name}-$index'),
                    stop: _stops[index],
                    index: index,
                    totalCount: _stops.length,
                    onEdit: () => _pickAndReplaceStop(index),
                    onDelete: () => _removeStop(index),
                  );
                },
              ),
            if (_stops.length == 1) ...[
              const SizedBox(height: 12),
              Text(
                '再新增一個終點後就可以儲存路線。',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
            if (_stops.length > 5) ...[
              const SizedBox(height: 12),
              Text(
                'Google Maps 對停靠點數量有限制；停靠點太多時，開啟導航可能只會部分套用。',
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _pickAndAddStop,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('新增地點'),
      ),
    );
  }

  Future<void> _pickAndAddStop() async {
    final selection = await _pickLocation();

    if (selection == null) {
      return;
    }

    setState(() => _stops.add(_toStopInput(selection)));
  }

  Future<void> _pickAndReplaceStop(int index) async {
    final current = _stops[index];
    final selection = await _pickLocation(current);

    if (selection == null) {
      return;
    }

    setState(() => _stops[index] = _toStopInput(selection));
  }

  Future<TripLocationSelection?> _pickLocation([
    NewTripRouteStopInput? current,
  ]) {
    return Navigator.of(context).push<TripLocationSelection>(
      MaterialPageRoute(
        builder: (_) => TripLocationPickerPage(
          initialName: current?.name,
          initialPlaceId: current?.placeId,
          initialAddress: current?.address,
          initialLatitude: current?.latitude,
          initialLongitude: current?.longitude,
        ),
      ),
    );
  }

  NewTripRouteStopInput _toStopInput(TripLocationSelection selection) {
    return NewTripRouteStopInput(
      name: selection.name,
      placeId: selection.placeId,
      address: selection.address,
      latitude: selection.latitude,
      longitude: selection.longitude,
    );
  }

  void _reorderStop(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final stop = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, stop);
    });
  }

  void _removeStop(int index) {
    setState(() => _stops.removeAt(index));
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('路線至少需要起點與終點')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(tripRoutesRepositoryProvider);
      final input = NewTripRouteInput(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        stops: List.unmodifiable(_stops),
      );

      final route = widget.route;
      if (route == null) {
        await repository.addRoute(input);
      } else {
        await repository.updateRoute(
          routeId: route.id,
          input: input,
        );
      }

      ref.invalidate(tripRoutesProvider);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_isEditing ? '修改' : '新增'}路線失敗：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _RouteStopsHeader extends StatelessWidget {
  const _RouteStopsHeader({
    required this.stopCount,
    required this.onAddStop,
  });

  final int stopCount;
  final VoidCallback onAddStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '停靠點規劃',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        TextButton.icon(
          onPressed: onAddStop,
          icon: const Icon(Icons.add),
          label: Text(stopCount == 0 ? '新增起點' : '新增停靠點'),
        ),
      ],
    );
  }
}

class _EmptyStopsPanel extends StatelessWidget {
  const _EmptyStopsPanel({required this.onAddStop});

  final VoidCallback onAddStop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onAddStop,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 42,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              '從地圖選擇第一個地點',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '依序加入起點、停靠點與終點。',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStopTile extends StatelessWidget {
  const _RouteStopTile({
    super.key,
    required this.stop,
    required this.index,
    required this.totalCount,
    required this.onEdit,
    required this.onDelete,
  });

  final NewTripRouteStopInput stop;
  final int index;
  final int totalCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (index) {
      0 => '起點',
      _ when index == totalCount - 1 => '終點',
      _ => '停靠 ${index + 1}',
    };

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text('${index + 1}'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            stop.address?.isNotEmpty == true
                ? stop.address!
                : stop.coordinateLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '編輯地點',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_location_alt_outlined),
            ),
            IconButton(
              tooltip: '刪除地點',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
