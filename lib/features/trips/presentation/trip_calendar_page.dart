import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../shared/widgets/pull_to_refresh.dart';
import '../data/trip_record.dart';
import '../providers/trip_records_providers.dart';
import 'trip_date_records_page.dart';

class TripCalendarPage extends ConsumerStatefulWidget {
  const TripCalendarPage({super.key});

  @override
  ConsumerState<TripCalendarPage> createState() => _TripCalendarPageState();
}

class _TripCalendarPageState extends ConsumerState<TripCalendarPage> {
  DateTime _focusedMonth = _monthOnly(DateTime.now());
  DateTime _selectedDate = _dateOnly(DateTime.now());
  final Map<DateTime, List<TripRecord>> _recordsByMonth = {};
  bool _hasShownCalendar = false;

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(tripMonthRecordsProvider(_focusedMonth));
    final records = recordsState.valueOrNull;
    final cachedMonthRecords = _recordsByMonth[_focusedMonth];
    final displayRecords =
        records ?? cachedMonthRecords ?? const <TripRecord>[];

    if (records != null) {
      _recordsByMonth[_focusedMonth] = records;
      _hasShownCalendar = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('騎旅日誌'),
        centerTitle: true,
      ),
      body: recordsState.hasError && !_hasShownCalendar
          ? _TripCalendarError(
              error: recordsState.error!,
              onRetry: () =>
                  ref.invalidate(tripMonthRecordsProvider(_focusedMonth)),
            )
          : recordsState.isLoading && !_hasShownCalendar
              ? const Center(child: CircularProgressIndicator())
              : _TripCalendarContent(
                  records: displayRecords,
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  isLoading: recordsState.isLoading,
                  onRefresh: () async {
                    ref.invalidate(tripMonthRecordsProvider(_focusedMonth));
                    ref.invalidate(tripDateRecordsProvider(_selectedDate));
                    await ref.read(
                      tripMonthRecordsProvider(_focusedMonth).future,
                    );
                  },
                  onDaySelected: (selectedDate, focusedDate) {
                    final normalizedSelectedDate = _dateOnly(selectedDate);
                    setState(() {
                      _selectedDate = normalizedSelectedDate;
                      _focusedMonth = _monthOnly(focusedDate);
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TripDateRecordsPage(
                          selectedDate: normalizedSelectedDate,
                        ),
                      ),
                    );
                  },
                  onPageChanged: (focusedDate) {
                    setState(() {
                      _focusedMonth = _monthOnly(focusedDate);
                      _selectedDate = _sameDayInMonth(
                        selectedDate: _selectedDate,
                        focusedMonth: focusedDate,
                      );
                    });
                  },
                  onOpenSelectedDate: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TripDateRecordsPage(
                          selectedDate: _selectedDate,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _TripCalendarContent extends StatelessWidget {
  const _TripCalendarContent({
    required this.records,
    required this.focusedMonth,
    required this.selectedDate,
    required this.isLoading,
    required this.onRefresh,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onOpenSelectedDate,
  });

  final List<TripRecord> records;
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final OnDaySelected onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final VoidCallback onOpenSelectedDate;

  @override
  Widget build(BuildContext context) {
    final recordsByDate = _groupRecordsByDate(records);
    final selectedRecords = recordsByDate[selectedDate] ?? const [];

    return Stack(
      children: [
        PullToRefresh(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _MonthSummaryCard(
                records: records,
                focusedMonth: focusedMonth,
                isLoading: isLoading,
              ),
              const SizedBox(height: 14),
              _CalendarCard(
                focusedMonth: focusedMonth,
                selectedDate: selectedDate,
                recordsByDate: recordsByDate,
                onDaySelected: onDaySelected,
                onPageChanged: onPageChanged,
              ),
              const SizedBox(height: 16),
              _SelectedDatePreview(
                selectedDate: selectedDate,
                records: selectedRecords,
                onOpen: onOpenSelectedDate,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: isLoading ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: const LinearProgressIndicator(minHeight: 2),
          ),
        ),
      ],
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({
    required this.records,
    required this.focusedMonth,
    required this.isLoading,
  });

  final List<TripRecord> records;
  final DateTime focusedMonth;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tripDays =
        records.map((record) => _dateOnly(record.tripDate)).toSet();
    final totalCost = records.fold<double>(
      0,
      (total, record) => total + record.cost,
    );
    final latestRecord = records.isEmpty ? null : records.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${focusedMonth.month} 月騎旅',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(
                icon: Icons.event_available_outlined,
                label: '${tripDays.length} 天',
              ),
              _SummaryChip(
                icon: Icons.article_outlined,
                label: '${records.length} 筆紀錄',
              ),
              _SummaryChip(
                icon: Icons.payments_outlined,
                label: '\$${totalCost.toStringAsFixed(0)}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isLoading
                ? '正在更新這個月的騎旅紀錄'
                : latestRecord == null
                    ? '這個月還沒有騎旅紀錄'
                    : '最近：${latestRecord.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.recordsByDate,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Map<DateTime, List<TripRecord>> recordsByDate;
  final OnDaySelected onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: TableCalendar<TripRecord>(
          firstDay: DateTime(2000),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: focusedMonth,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          eventLoader: (day) => recordsByDate[_dateOnly(day)] ?? const [],
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: '月',
          },
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
        ),
      ),
    );
  }
}

class _SelectedDatePreview extends StatelessWidget {
  const _SelectedDatePreview({
    required this.selectedDate,
    required this.records,
    required this.onOpen,
  });

  final DateTime selectedDate;
  final List<TripRecord> records;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${selectedDate.day}',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDisplayDate(selectedDate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      records.isEmpty
                          ? '點擊新增這天的騎旅故事'
                          : '${records.length} 筆騎旅紀錄',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCalendarError extends StatelessWidget {
  const _TripCalendarError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新整理'),
            ),
          ],
        ),
      ),
    );
  }
}

Map<DateTime, List<TripRecord>> _groupRecordsByDate(List<TripRecord> records) {
  final recordsByDate = <DateTime, List<TripRecord>>{};

  for (final record in records) {
    final date = _dateOnly(record.tripDate);
    recordsByDate.putIfAbsent(date, () => []).add(record);
  }

  return recordsByDate;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _monthOnly(DateTime date) {
  return DateTime(date.year, date.month);
}

DateTime _sameDayInMonth({
  required DateTime selectedDate,
  required DateTime focusedMonth,
}) {
  final lastDayOfMonth = DateTime(
    focusedMonth.year,
    focusedMonth.month + 1,
    0,
  ).day;
  final day =
      selectedDate.day > lastDayOfMonth ? lastDayOfMonth : selectedDate.day;

  return DateTime(focusedMonth.year, focusedMonth.month, day);
}

String _formatDisplayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}/$month/$day';
}
