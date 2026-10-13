import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:stories_editor/src/domain/models/editable_items.dart';

class DraggableWidgetNotifier extends ChangeNotifier {
  List<EditableItem> _draggableWidget = [];
  List<EditableItem> get draggableWidget => _draggableWidget;
  set draggableWidget(List<EditableItem> item) {
    _draggableWidget = item;
    notifyListeners();
  }

  GiphyGif? _gif;
  GiphyGif? get giphy => _gif;
  set giphy(GiphyGif? giphy) {
    _gif = giphy;
    notifyListeners();
  }

  /// The final item paints on top. Keep background items behind overlays.
  bool bringToFront(EditableItem item) {
    final index = _draggableWidget.indexOf(item);
    if (index < 0 || index == _draggableWidget.length - 1) return false;
    _draggableWidget = [..._draggableWidget]..removeAt(index)..add(item);
    notifyListeners();
    return true;
  }

  bool sendToBack(EditableItem item) {
    final index = _draggableWidget.indexOf(item);
    if (index <= 0 || item.isStoriesBackground) return false;
    final backgroundCount =
        _draggableWidget.where((entry) => entry.isStoriesBackground).length;
    _draggableWidget = [..._draggableWidget]..removeAt(index)
      ..insert(backgroundCount, item);
    notifyListeners();
    return true;
  }

  bool moveLayer(EditableItem item, int newIndex) {
    final oldIndex = _draggableWidget.indexOf(item);
    if (oldIndex < 0 || newIndex < 0 ||
        newIndex >= _draggableWidget.length || oldIndex == newIndex) {
      return false;
    }
    if (item.isStoriesBackground ||
        _draggableWidget[newIndex].isStoriesBackground) return false;
    _draggableWidget = [..._draggableWidget]..removeAt(oldIndex)
      ..insert(newIndex, item);
    notifyListeners();
    return true;
  }

  void setDefaults() {
    _draggableWidget = [];
    _gif = null;
    notifyListeners();
  }

  updatedNeedsRefresh() {
    notifyListeners();
  }
}
