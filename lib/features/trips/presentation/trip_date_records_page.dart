import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/pull_to_refresh.dart';
import '../data/trip_record.dart';
import '../providers/trip_records_providers.dart';
import 'add_trip_record_page.dart';

class TripDateRecordsPage extends ConsumerWidget {
  const TripDateRecordsPage({
    super.key,
    required this.selectedDate,
  });

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsState =
        ref.watch(tripDateRecordsProvider(_dateOnly(selectedDate)));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDisplayDate(selectedDate)),
        centerTitle: true,
      ),
      body: PullToRefresh(
        onRefresh: () async {
          ref.invalidate(tripDateRecordsProvider(_dateOnly(selectedDate)));
          ref.invalidate(tripMonthRecordsProvider(_monthOnly(selectedDate)));
        },
        child: recordsState.when(
          data: (records) => records.isEmpty
              ? const _EmptyTripRecordsView()
              : _TripRecordsList(records: records),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _TripRecordsErrorView(
            error: error,
            onRetry: () => ref.invalidate(
              tripDateRecordsProvider(_dateOnly(selectedDate)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: '新增騎旅紀錄',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AddTripRecordPage(initialDate: selectedDate),
            ),
          );
        },
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('新增'),
      ),
    );
  }
}

class _TripRecordsList extends StatelessWidget {
  const _TripRecordsList({required this.records});

  final List<TripRecord> records;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _TripRecordCard(record: records[index]);
      },
    );
  }
}

class _TripRecordCard extends StatelessWidget {
  const _TripRecordCard({required this.record});

  final TripRecord record;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final coverImageUrl =
        record.images.isEmpty ? null : record.images.first.imageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: coverImageUrl == null
                ? ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.travel_explore_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : Image.network(
                    coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (record.vehicleModel != null)
                      _TripFact(
                        icon: Icons.motorcycle_outlined,
                        label: record.vehicleModel!,
                      ),
                    if (record.location != null)
                      _TripFact(
                        icon: Icons.place_outlined,
                        label: record.location!,
                      ),
                    if (record.odometer != null)
                      _TripFact(
                        icon: Icons.speed_outlined,
                        label: '${record.odometer} km',
                      ),
                    if (record.cost > 0)
                      _TripFact(
                        icon: Icons.payments_outlined,
                        label: '\$${record.cost.toStringAsFixed(0)}',
                      ),
                  ],
                ),
                if (record.content != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    record.content!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ],
                if (record.images.length > 1) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${record.images.length} 張照片',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripFact extends StatelessWidget {
  const _TripFact({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }
}

class _EmptyTripRecordsView extends StatelessWidget {
  const _EmptyTripRecordsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 96),
      children: [
        Icon(
          Icons.map_outlined,
          size: 60,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          '這天還沒有騎旅紀錄',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '加一張照片、一段文字，讓這趟路之後還找得到感覺。',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TripRecordsErrorView extends StatelessWidget {
  const _TripRecordsErrorView({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 96),
      children: [
        Text(
          error.toString(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重新整理'),
          ),
        ),
      ],
    );
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _monthOnly(DateTime date) {
  return DateTime(date.year, date.month);
}

String _formatDisplayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}/$month/$day';
}
