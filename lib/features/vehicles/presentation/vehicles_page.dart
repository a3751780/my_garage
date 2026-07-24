import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pull_to_refresh.dart';
import '../data/vehicle.dart';
import '../providers/vehicles_providers.dart';
import 'add_vehicle_page.dart';
import 'vehicle_detail_page.dart';

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({
    super.key,
    required this.onSignOut,
    required this.onChangePassword,
    required this.onOpenTrips,
  });

  final VoidCallback onSignOut;
  final VoidCallback onChangePassword;
  final VoidCallback onOpenTrips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesState = ref.watch(vehiclesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '騎旅日誌',
            onPressed: onOpenTrips,
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            tooltip: '修改密碼',
            onPressed: onChangePassword,
            icon: const Icon(Icons.lock_reset_outlined),
          ),
          IconButton(
            tooltip: '登出',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: PullToRefresh(
        onRefresh: () =>
            ref.read(vehiclesViewModelProvider.notifier).loadVehicles(),
        child: vehiclesState.when(
          data: (vehicles) => vehicles.isEmpty
              ? const _EmptyVehiclesView()
              : _VehiclesList(vehicles: vehicles),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _VehiclesErrorView(error: error),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新增車輛',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AddVehiclePage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VehiclesList extends StatelessWidget {
  const _VehiclesList({required this.vehicles});

  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: vehicles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _VehicleCard(vehicle: vehicles[index]);
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => VehicleDetailPage(vehicle: vehicle),
            ),
          );
        },
        child: SizedBox(
          height: 118,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 118,
                child: _VehicleCoverImage(vehicle: vehicle),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.model,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          _VehicleFact(
                            icon: Icons.calendar_month_outlined,
                            label: '${vehicle.year}',
                          ),
                          _VehicleFact(
                            icon: Icons.speed_outlined,
                            label: '${vehicle.currentMileage} km',
                          ),
                          _VehicleFact(
                            icon: Icons.payments_outlined,
                            label:
                                '\$${vehicle.acquisitionCost.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleCoverImage extends StatelessWidget {
  const _VehicleCoverImage({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (vehicle.coverImageUrl == null) {
      return ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.motorcycle_rounded,
          size: 40,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      vehicle.coverImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _VehicleFact extends StatelessWidget {
  const _VehicleFact({
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
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmptyVehiclesView extends StatelessWidget {
  const _EmptyVehiclesView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Icon(
          Icons.motorcycle_rounded,
          size: 72,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          '還沒有車輛',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '點右下角新增你的第一台車。',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VehiclesErrorView extends ConsumerWidget {
  const _VehiclesErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 56),
        const SizedBox(height: 16),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(vehiclesViewModelProvider.notifier).loadVehicles(),
          icon: const Icon(Icons.refresh),
          label: const Text('重新整理'),
        ),
      ],
    );
  }
}
