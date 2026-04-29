import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

import '../api/backend_api.dart';
import '../api/dtos.dart';
import '../app/app_config.dart';

class DeviceHistoryPage extends StatefulWidget {
  const DeviceHistoryPage({super.key});

  @override
  State<DeviceHistoryPage> createState() => _DeviceHistoryPageState();
}

class _DeviceHistoryPageState extends State<DeviceHistoryPage> {
  static const _api = BackendApi();
  static const _pageSize = 300;
  static final _maxSpan = const Duration(days: 3);

  late DateTime _fromUtc;
  late DateTime _toUtc;
  bool _includeHumidity = true;
  bool _includeValve = true;
  int _offset = 0;
  final List<HistoryTimelineItemDto> _items = [];
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _toUtc = now;
    _fromUtc = now.subtract(_maxSpan);
    WidgetsBinding.instance.addPostFrameCallback((_) => _search(reset: true));
  }

  void _clampFromTo() {
    if (_fromUtc.isAfter(_toUtc)) {
      _fromUtc = _toUtc.subtract(const Duration(minutes: 1));
    }
    if (_toUtc.difference(_fromUtc) > _maxSpan) {
      _fromUtc = _toUtc.subtract(_maxSpan);
    }
  }

  Future<void> _pickFrom() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.fromMillisecondsSinceEpoch(_fromUtc.millisecondsSinceEpoch, isUtc: true)
          .toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fromUtc = DateTime.utc(picked.year, picked.month, picked.day);
      _clampFromTo();
    });
    if (!mounted) return;
    if (_toUtc.difference(_fromUtc) > _maxSpan) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.historyRangeMax3Days)));
    }
  }

  Future<void> _pickTo() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.fromMillisecondsSinceEpoch(_toUtc.millisecondsSinceEpoch, isUtc: true)
          .toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _toUtc = DateTime.utc(picked.year, picked.month, picked.day, 23, 59, 59);
      _clampFromTo();
    });
    if (!mounted) return;
    if (_toUtc.difference(_fromUtc) > _maxSpan) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.historyRangeMax3Days)));
      setState(_clampFromTo);
    }
  }

  Future<void> _search({required bool reset}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_includeHumidity && !_includeValve) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.historySelectOneType)));
      if (mounted) setState(() => _loadingMore = false);
      return;
    }
    _clampFromTo();
    if (_toUtc.difference(_fromUtc) > _maxSpan) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.historyRangeMax3Days)));
      setState(() {
        _fromUtc = _toUtc.subtract(_maxSpan);
      });
    }

    final int queryOffset = reset ? 0 : _offset;

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dto = await _api.getDeviceHistoryTimeline(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
        from: _fromUtc,
        to: _toUtc,
        humidity: _includeHumidity,
        valve: _includeValve,
        offset: queryOffset,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(_dedupeAdjacentValveRows(dto.items));
          _offset = _pageSize;
        } else {
          final merged = <HistoryTimelineItemDto>[..._items, ...dto.items];
          _items
            ..clear()
            ..addAll(_dedupeAdjacentValveRows(merged));
          _offset += _pageSize;
        }
        _hasMore = dto.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _search(reset: false);
  }

  String _paramText(HistoryTimelineItemDto row) {
    if (row.kind == 'humidity') {
      return row.humidityRaw?.toString() ?? '-';
    }
    if (row.kind == 'valve') {
      return row.valve ?? '-';
    }
    return row.kind;
  }

  List<HistoryTimelineItemDto> _dedupeAdjacentValveRows(List<HistoryTimelineItemDto> rows) {
    if (rows.isEmpty) return rows;
    final out = <HistoryTimelineItemDto>[];
    for (final row in rows) {
      if (out.isNotEmpty) {
        final prev = out.last;
        final isAdjacentSameValve = prev.kind == 'valve' &&
            row.kind == 'valve' &&
            (prev.valve ?? '') == (row.valve ?? '');
        if (isAdjacentSameValve) {
          continue;
        }
      }
      out.add(row);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _search(reset: true),
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.historyRangeMax3Days, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickFrom,
                        child: Text('${l10n.historyFromLabel}: ${df.format(_fromUtc.toLocal())}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickTo,
                        child: Text('${l10n.historyToLabel}: ${df.format(_toUtc.toLocal())}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    FilterChip(
                      label: Text(l10n.historyIncludeHumidity),
                      selected: _includeHumidity,
                      onSelected: (v) => setState(() => _includeHumidity = v),
                    ),
                    FilterChip(
                      label: Text(l10n.historyIncludeValve),
                      selected: _includeValve,
                      onSelected: (v) => setState(() => _includeValve = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : () => _search(reset: true),
                  child: Text(l10n.historySearchButton),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: 1 + _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  l10n.historyColumnTime,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  l10n.historyColumnValue,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (index <= _items.length) {
                        final row = _items[index - 1];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(df.format(row.at.toLocal())),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(_paramText(row)),
                              ),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: _loadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: _loadMore,
                                  child: Text(l10n.historyLoadMore),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
