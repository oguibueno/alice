enum AliceTabItem { inspector, logger, analytics }

extension AliceTabItemExtension on AliceTabItem {
  String get title {
    switch (this) {
      case AliceTabItem.inspector:
        return 'Inspector';
      case AliceTabItem.logger:
        return 'Logger';
      case AliceTabItem.analytics:
        return 'Analytics';
    }
  }
}
