// ignore_for_file: cascade_invocations
import 'package:alice/src/core/alice_core.dart';
import 'package:alice/src/core/alice_logger.dart';
import 'package:alice/src/helper/alice_alert_helper.dart';
import 'package:alice/src/model/alice_event_filter.dart';
import 'package:alice/src/model/alice_http_call.dart';
import 'package:alice/src/model/alice_menu_item.dart';
import 'package:alice/src/model/alice_sort_option.dart';
import 'package:alice/src/model/alice_tab_item.dart';
import 'package:alice/src/ui/page/alice_call_details_screen.dart';
import 'package:alice/src/ui/page/alice_stats_screen.dart';
import 'package:alice/src/ui/widget/alice_call_list_item_widget.dart';
import 'package:alice/src/ui/widget/alice_events_filter_sheet.dart';
import 'package:alice/src/ui/widget/alice_events_list_widget.dart';
import 'package:alice/src/ui/widget/alice_log_list_widget.dart';
import 'package:alice/src/ui/widget/alice_raw_log_list_widger.dart';
import 'package:alice/src/utils/alice_constants.dart';
import 'package:flutter/material.dart';

class AliceCallsListScreen extends StatefulWidget {
  final AliceCore _aliceCore;
  final AliceLogger? _aliceLogger;

  const AliceCallsListScreen(this._aliceCore, this._aliceLogger, {super.key});

  @override
  State<AliceCallsListScreen> createState() => _AliceCallsListScreenState();
}

class _AliceCallsListScreenState extends State<AliceCallsListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryTextEditingController =
      TextEditingController();
  final List<AliceMenuItem> _menuItems = [];
  final _tabItems = AliceTabItem.values;
  final ScrollController _scrollController = ScrollController();

  final _eventsDeleteMenuItem = AliceMenuItem('Delete', Icons.delete);

  AliceSortOption? _sortOption = AliceSortOption.time;
  bool _sortAscending = false;
  AliceEventFilter _eventFilter = const AliceEventFilter();
  bool _searchEnabled = false;
  bool isAndroidRawLogsEnabled = false;
  int _selectedIndex = 0;

  TabController? _tabController;

  AliceCore get aliceCore => widget._aliceCore;

  _AliceCallsListScreenState() {
    _menuItems.add(AliceMenuItem('Sort', Icons.sort));
    _menuItems.add(AliceMenuItem('Delete', Icons.delete));
    _menuItems.add(AliceMenuItem('Stats', Icons.insert_chart));
    _menuItems.add(AliceMenuItem('Save', Icons.save));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      vsync: this,
      length: _tabItems.length,
      initialIndex: _tabItems.first.index,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController?.addListener(() {
        _onTabChanged(_tabController!.index);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _queryTextEditingController.dispose();
    _tabController?.dispose();
    _scrollController.dispose();
  }

  AliceTabItem get _selectedTab => _tabItems[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget._aliceCore.directionality ?? Directionality.of(context),
      child: Theme(
        data: Theme.of(context),
        child: Scaffold(
          appBar: AppBar(
            title: _searchEnabled ? _buildSearchField() : _buildTitleWidget(),
            actions: _buildActionWidgets(),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AliceConstants.orange,
              tabs: [
                for (final item in _tabItems)
                  Tab(text: item.title.toUpperCase()),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              for (final item in _tabItems) _buildTabContent(item),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  Widget _buildTabContent(AliceTabItem item) {
    switch (item) {
      case AliceTabItem.inspector:
        return _buildCallsListWrapper();
      case AliceTabItem.logger:
        return _buildLogsWidget();
      case AliceTabItem.analytics:
        return AliceEventsListWidget(
          aliceCore: aliceCore,
          query: _queryTextEditingController.text,
          filter: _eventFilter,
          onFilterChanged: (filter) => setState(() => _eventFilter = filter),
        );
    }
  }

  List<Widget> _buildActionWidgets() {
    switch (_selectedTab) {
      case AliceTabItem.inspector:
        return [
          _buildSearchButton(),
          _buildMenuButton(),
        ];
      case AliceTabItem.logger:
        return [
          _buildLogsChangeButton(),
          _buildLogsClearButton(),
        ];
      case AliceTabItem.analytics:
        return [
          _buildSearchButton(),
          _buildEventsFilterButton(),
          _buildEventsMenuButton(),
        ];
    }
  }

  Widget _buildEventsMenuButton() {
    return PopupMenuButton<AliceMenuItem>(
      key: const Key('events_menu'),
      onSelected: (_) => _showRemoveEventsDialog(),
      itemBuilder: (context) => [
        for (final item in [_eventsDeleteMenuItem])
          PopupMenuItem<AliceMenuItem>(
            value: item,
            child: Row(
              children: [
                Icon(item.iconData, color: AliceConstants.lightRed),
                const Padding(padding: EdgeInsets.only(left: 10)),
                Text(item.title),
              ],
            ),
          ),
      ],
    );
  }

  void _showRemoveEventsDialog() {
    AliceAlertHelper.showAlert(
      context,
      'Delete events',
      'Do you want to delete captured events?',
      firstButtonTitle: 'No',
      secondButtonTitle: 'Yes',
      secondButtonAction: aliceCore.removeEvents,
    );
  }

  Widget _buildEventsFilterButton() {
    final count = _eventFilter.activeFilterCount;
    return IconButton(
      key: const Key('events_filter_button'),
      tooltip: 'Filter & sort',
      onPressed: _openEventsFilterSheet,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.tune),
      ),
    );
  }

  Future<void> _openEventsFilterSheet() async {
    final filter = await showAliceEventsFilterSheet(
      context,
      events: aliceCore.eventsSubject.value,
      hiddenEventNames: aliceCore.hiddenEventNames,
      filter: _eventFilter,
    );
    if (filter != null && mounted) {
      setState(() => _eventFilter = filter);
    }
  }

  Widget _buildFloatingActionButton() {
    return _selectedTab == AliceTabItem.logger
        ? Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'h1',
                backgroundColor: AliceConstants.orange,
                onPressed: () {
                  _scrollLogsList(true);
                },
                child: Icon(Icons.arrow_upward, color: AliceConstants.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'h2',
                backgroundColor: AliceConstants.orange,
                onPressed: () {
                  _scrollLogsList(false);
                },
                child: Icon(Icons.arrow_downward, color: AliceConstants.white),
              ),
            ],
          )
        : const SizedBox();
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: _onSearchClicked,
    );
  }

  Widget _buildLogsChangeButton() {
    return IconButton(
      icon: const Icon(Icons.terminal),
      onPressed: _onLogsChangeClicked,
    );
  }

  Widget _buildLogsClearButton() {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: _showClearLogsDialog,
    );
  }

  void _showClearLogsDialog() {
    AliceAlertHelper.showAlert(
      context,
      'Delete logs',
      'Do you want to clear logs?',
      firstButtonTitle: 'No',
      secondButtonTitle: 'Yes',
      secondButtonAction: _onLogsClearClicked,
    );
  }

  void _onLogsChangeClicked() {
    setState(() {
      isAndroidRawLogsEnabled = !isAndroidRawLogsEnabled;
    });
  }

  void _onLogsClearClicked() {
    setState(() {
      if (isAndroidRawLogsEnabled) {
        widget._aliceLogger?.clearAndroidRawLogs();
      } else {
        widget._aliceLogger?.clearLogs();
      }
    });
  }

  void _onSearchClicked() {
    setState(() {
      _searchEnabled = !_searchEnabled;
      if (!_searchEnabled) {
        _queryTextEditingController.text = '';
      }
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _searchEnabled = false;
      _queryTextEditingController.text = '';
    });
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<AliceMenuItem>(
      onSelected: _onMenuItemSelected,
      itemBuilder: (BuildContext context) {
        return _menuItems.map((AliceMenuItem item) {
          return PopupMenuItem<AliceMenuItem>(
            value: item,
            child: Row(
              children: [
                Icon(
                  item.iconData,
                  color: AliceConstants.lightRed,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                ),
                Text(item.title),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildTitleWidget() {
    return const Text('Alice');
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _queryTextEditingController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: _selectedTab == AliceTabItem.analytics
            ? 'Search event name or parameter...'
            : 'Search http request...',
        hintStyle: TextStyle(fontSize: 16, color: AliceConstants.grey),
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 16),
      onChanged: _updateSearchQuery,
    );
  }

  void _onMenuItemSelected(AliceMenuItem menuItem) {
    if (menuItem.title == 'Sort') {
      _showSortDialog();
    }
    if (menuItem.title == 'Delete') {
      _showRemoveDialog();
    }
    if (menuItem.title == 'Stats') {
      _showStatsScreen();
    }
  }

  Widget _buildCallsListWrapper() {
    return StreamBuilder<List<AliceHttpCall>>(
      stream: aliceCore.callsSubject,
      builder: (context, snapshot) {
        var calls = snapshot.data ?? [];
        final query = _queryTextEditingController.text.trim();
        if (query.isNotEmpty) {
          calls = calls
              .where(
                (call) =>
                    call.endpoint.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        }
        if (calls.isNotEmpty) {
          return _buildCallsListWidget(calls);
        } else {
          return _buildEmptyWidget();
        }
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AliceConstants.orange,
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no calls to show',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Check if you send any http request',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '• Check your Alice configuration',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '• Check search filters',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallsListWidget(List<AliceHttpCall> calls) {
    final callsSorted = List<AliceHttpCall>.of(calls);
    switch (_sortOption) {
      case AliceSortOption.time:
        if (_sortAscending) {
          callsSorted.sort(
            (call1, call2) => call1.createdTime.compareTo(call2.createdTime),
          );
        } else {
          callsSorted.sort(
            (call1, call2) => call2.createdTime.compareTo(call1.createdTime),
          );
        }
      case AliceSortOption.responseTime:
        if (_sortAscending) {
          callsSorted.sort();
          callsSorted.sort(
            (call1, call2) =>
                call1.response?.time.compareTo(call2.response!.time) ?? -1,
          );
        } else {
          callsSorted.sort(
            (call1, call2) =>
                call2.response?.time.compareTo(call1.response!.time) ?? -1,
          );
        }
      case AliceSortOption.responseCode:
        if (_sortAscending) {
          callsSorted.sort(
            (call1, call2) =>
                call1.response?.status?.compareTo(call2.response!.status!) ??
                -1,
          );
        } else {
          callsSorted.sort(
            (call1, call2) =>
                call2.response?.status?.compareTo(call1.response!.status!) ??
                -1,
          );
        }
      case AliceSortOption.responseSize:
        if (_sortAscending) {
          callsSorted.sort(
            (call1, call2) =>
                call1.response?.size.compareTo(call2.response!.size) ?? -1,
          );
        } else {
          callsSorted.sort(
            (call1, call2) =>
                call2.response?.size.compareTo(call1.response!.size) ?? -1,
          );
        }
      case AliceSortOption.endpoint:
        if (_sortAscending) {
          callsSorted
              .sort((call1, call2) => call1.endpoint.compareTo(call2.endpoint));
        } else {
          callsSorted
              .sort((call1, call2) => call2.endpoint.compareTo(call1.endpoint));
        }
      case null:
    }

    return ListView.builder(
      itemCount: callsSorted.length,
      itemBuilder: (context, index) {
        return AliceCallListItemWidget(callsSorted[index], _onListItemClicked);
      },
    );
  }

  void _onListItemClicked(AliceHttpCall call) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => AliceCallDetailsScreen(call, widget._aliceCore),
      ),
    );
  }

  void _showRemoveDialog() {
    AliceAlertHelper.showAlert(
      context,
      'Delete calls',
      'Do you want to delete http calls?',
      firstButtonTitle: 'No',
      firstButtonAction: () => <String, dynamic>{},
      secondButtonTitle: 'Yes',
      secondButtonAction: _removeCalls,
    );
  }

  void _removeCalls() {
    aliceCore.removeCalls();
  }

  void _showStatsScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => AliceStatsScreen(widget._aliceCore),
      ),
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {});
  }

  void _showSortDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext buildContext) {
        return Theme(
          data: ThemeData(
            brightness: Brightness.light,
          ),
          child: AlertDialog(
            title: const Text('Select filter'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
                  children: [
                    ...AliceSortOption.values.map(
                      (AliceSortOption sortOption) =>
                          RadioListTile<AliceSortOption>(
                        title: Text(sortOption.name),
                        value: sortOption,
                        groupValue: _sortOption,
                        onChanged: (AliceSortOption? value) {
                          setState(() {
                            _sortOption = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Descending'),
                        Switch(
                          value: _sortAscending,
                          onChanged: (value) {
                            setState(() {
                              _sortAscending = value;
                            });
                          },
                          activeTrackColor: Colors.grey,
                          activeColor: Colors.white,
                        ),
                        const Text('Ascending'),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  sortCalls();
                },
                child: const Text('Use filter'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsWidget() {
    final aliceLogger = widget._aliceLogger;
    final emptyWidget = _buildEmptyLogsWidget();
    if (aliceLogger != null) {
      if (isAndroidRawLogsEnabled) {
        return AliceRawLogListWidget(
          scrollController: _scrollController,
          getRawLogs: aliceLogger.getAndroidRawLogs(),
          emptyWidget: emptyWidget,
        );
      }
      return AliceLogListWidget(
        logsListenable: aliceLogger.listenable,
        scrollController: _scrollController,
        emptyWidget: emptyWidget,
      );
    } else {
      return _buildEmptyLogsWidget();
    }
  }

  void sortCalls() {
    setState(() {});
  }

  Widget _buildEmptyLogsWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AliceConstants.orange,
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no logs to show',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollLogsList(bool top) {
    if (top) {
      _scrollToTop();
    } else {
      _scrollToBottom();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(microseconds: 500),
      curve: Curves.ease,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(microseconds: 500),
      curve: Curves.ease,
    );
  }
}
