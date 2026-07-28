import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pull_to_refresh.dart';
import '../data/trip_route.dart';
import '../providers/trip_routes_providers.dart';
import 'add_trip_route_page.dart';

class TripRoutesPage extends ConsumerWidget {
  const TripRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesState = ref.watch(tripRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('騎旅路線'),
        centerTitle: true,
      ),
      body: PullToRefresh(
        onRefresh: () => ref.refresh(tripRoutesProvider.future),
        child: routesState.when(
          data: (routes) => routes.isEmpty
              ? const _EmptyRoutesView()
              : _TripRoutesList(routes: routes),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _RoutesErrorView(error: error),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AddTripRoutePage(),
            ),
          );

          if (added == true) {
            ref.invalidate(tripRoutesProvider);
          }
        },
        icon: const Icon(Icons.add_road_outlined),
        label: const Text('新增路線'),
      ),
    );
  }
}

class _TripRoutesList extends StatelessWidget {
  const _TripRoutesList({required this.routes});

  final List<TripRoute> routes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: routes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _TripRouteCard(route: routes[index]);
      },
    );
  }
}

class _TripRouteCard extends ConsumerWidget {
  const _TripRouteCard({required this.route});

  final TripRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final origin = route.origin;
    final destination = route.destination;
    final waypointCount = route.waypoints.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _openRoute(context, ref),
        onLongPress: () => _showRouteActions(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alt_route,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _summaryText(origin, destination, waypointCount),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (route.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  route.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RouteMetaChip(
                    icon: Icons.two_wheeler_outlined,
                    label: '機車路線',
                  ),
                  _RouteMetaChip(
                    icon: Icons.place_outlined,
                    label: '${route.stops.length} 個地點',
                  ),
                  if (waypointCount > 0)
                    _RouteMetaChip(
                      icon: Icons.flag_outlined,
                      label: '$waypointCount 個停靠點',
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openRoute(context, ref),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('從目前位置導航'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summaryText(
    TripRouteStop? origin,
    TripRouteStop? destination,
    int waypointCount,
  ) {
    if (origin == null || destination == null) {
      return '路線資料不完整';
    }

    final waypointText = waypointCount == 0 ? '' : '，經 $waypointCount 站';
    return '${origin.name} -> ${destination.name}$waypointText';
  }

  Future<void> _openRoute(BuildContext context, WidgetRef ref) async {
    if (route.origin == null || route.destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('路線資料不完整，無法開啟導航')),
      );
      return;
    }

    try {
      final launcher = ref.read(googleMapsRouteLauncherProvider);
      final didLaunch = await launcher.openRoute(route);

      if (!context.mounted || didLaunch) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法開啟 Google Maps')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('以目前位置導航失敗：$error')),
      );
    }
  }

  Future<void> _openPlannedRoute(BuildContext context, WidgetRef ref) async {
    if (route.origin == null || route.destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('路線資料不完整，無法查看規劃路線')),
      );
      return;
    }

    try {
      final launcher = ref.read(googleMapsRouteLauncherProvider);
      final didLaunch = await launcher.openPlannedRoute(route);

      if (!context.mounted || didLaunch) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法開啟 Google Maps')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查看完整規劃路線失敗：$error')),
      );
    }
  }

  Future<void> _showRouteActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<_RouteAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.navigation_outlined),
                title: const Text('從目前位置導航'),
                onTap: () => Navigator.of(context).pop(_RouteAction.navigate),
              ),
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: const Text('查看完整規劃路線'),
                onTap: () => Navigator.of(context).pop(_RouteAction.preview),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('修改路線'),
                onTap: () => Navigator.of(context).pop(_RouteAction.edit),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('刪除路線'),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () => Navigator.of(context).pop(_RouteAction.delete),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _RouteAction.navigate:
        await _openRoute(context, ref);
      case _RouteAction.preview:
        await _openPlannedRoute(context, ref);
      case _RouteAction.edit:
        await _editRoute(context, ref);
      case _RouteAction.delete:
        await _deleteRoute(context, ref);
    }
  }

  Future<void> _editRoute(BuildContext context, WidgetRef ref) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTripRoutePage(route: route),
      ),
    );

    if (updated == true) {
      ref.invalidate(tripRoutesProvider);
    }
  }

  Future<void> _deleteRoute(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除路線'),
        content: Text('確定要刪除「${route.name}」嗎？'),
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
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      final repository = ref.read(tripRoutesRepositoryProvider);
      await repository.deleteRoute(route.id);
      ref.invalidate(tripRoutesProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('路線已刪除')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刪除路線失敗：$error')),
      );
    }
  }
}

enum _RouteAction { navigate, preview, edit, delete }

class _RouteMetaChip extends StatelessWidget {
  const _RouteMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutesView extends StatelessWidget {
  const _EmptyRoutesView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Icon(
          Icons.alt_route,
          size: 76,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          '還沒有騎旅路線',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '新增常騎路線，下次出發前一鍵開 Google Maps 導航。',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RoutesErrorView extends StatelessWidget {
  const _RoutesErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 96),
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text(
          '讀取騎旅路線失敗',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '$error',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
