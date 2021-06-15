import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

import 'route.dart';
import 'tree.dart';

class UrlStackManager {
  static final List<List<PageTreeNode>> _stack = [];

  static final List<UrlStackObserver> _observers = [];

  static void addObserver(UrlStackObserver observer) {
    _observers.add(observer);
  }

  static void removeObserver(UrlStackObserver observer) {
    _observers.remove(observer);
  }

  static void _push(List<PageTreeNode> nodeList) {
    if (_stack.isEmpty) {
      _stack.add(nodeList);
      _notifyObservers();
      return;
    }

    List<PageTreeNode> newList = [];

    int startIndex = -1;

    for (int i = 0; i < _stack.last.length; i++) {
      if (_stack.last[i].rootName == nodeList.first.rootName) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      throw Exception('invalid path');
    }

    for (int i = 0; i < startIndex; i++) {
      newList.add(_stack.last[i]);
    }

    newList.addAll(nodeList);

    _stack.add(newList);

    _notifyObservers();
  }

  static void _popUntil(List<PageTreeNode> nodeList) {
    for (int i = _stack.length - 1; i >= 0; i--) {
      List<PageTreeNode> tmpList = _stack[i];

      if (tmpList.length != nodeList.length) {
        _stack.removeAt(i);
        continue;
      }

      bool needsRemove = false;

      for (int j = 0; j < tmpList.length; j++) {
        if (tmpList[j].compare(nodeList[j])) {
          needsRemove = true;
          break;
        }
      }

      if (needsRemove) {
        _stack.removeAt(i);
      }
    }
    _notifyObservers();
  }

  static void _pushAndRemoveUntil(List<PageTreeNode> pushNodeList, List<PageTreeNode> targetNodeList) {
    if (_stack.isEmpty) {
      _stack.add(pushNodeList);
      _notifyObservers();
      return;
    }

    List<PageTreeNode> newPushNodeList = [];

    int startIndex = -1;

    for (int i = 0; i < _stack.last.length; i++) {
      if (_stack.last[i].rootName == pushNodeList.first.rootName) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      throw Exception('invalid path');
    }

    for (int i = 0; i < startIndex; i++) {
      newPushNodeList.add(_stack.last[i]);
    }

    newPushNodeList.addAll(pushNodeList);

    List<PageTreeNode> newTargetNodeList = [];

    startIndex = -1;

    for (int i = 0; i < _stack.last.length; i++) {
      if (_stack.last[i].rootName == targetNodeList.first.rootName) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      throw Exception('invalid path');
    }

    for (int i = 0; i < startIndex; i++) {
      newTargetNodeList.add(_stack.last[i]);
    }

    newTargetNodeList.addAll(targetNodeList);

    _stack.add(newPushNodeList);

    for (int i = _stack.length - 2; i >= 0; i--) {
      List<PageTreeNode> tmpList = _stack[i];

      if (tmpList.length != newTargetNodeList.length) {
        _stack.removeAt(i);
        continue;
      }

      bool needsRemove = false;

      for (int j = 0; j < tmpList.length; j++) {
        if (tmpList[j].path != newTargetNodeList[j].path) {
          needsRemove = true;
          break;
        }
      }

      if (needsRemove) {
        _stack.removeAt(i);
      }
    }
    _notifyObservers();
  }

  static void _pushReplace(List<PageTreeNode> nodeList) {
    if (_stack.isEmpty) {
      _stack.add(nodeList);
      _notifyObservers();
      return;
    }

    List<PageTreeNode> newList = [];

    int startIndex = -1;

    for (int i = 0; i < _stack.last.length; i++) {
      if (_stack.last[i].rootName == nodeList.first.rootName) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      throw Exception('invalid path');
    }

    for (int i = 0; i < startIndex; i++) {
      newList.add(_stack.last[i]);
    }

    newList.addAll(nodeList);

    _stack.removeLast();
    _stack.add(newList);

    _notifyObservers();
  }

  static void _pushOrReplace(List<PageTreeNode> pushNodeList, List<PageTreeNode> replaceNodeList) {
    if (_stack.isEmpty) {
      _stack.add(pushNodeList);
      _notifyObservers();
      return;
    }

    List<PageTreeNode> newPushList = [];

    int startIndex = -1;

    for (int i = 0; i < _stack.last.length; i++) {
      if (_stack.last[i].rootName == pushNodeList.first.rootName) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      throw Exception('invalid path');
    }

    for (int i = 0; i < startIndex; i++) {
      newPushList.add(_stack.last[i]);
    }

    newPushList.addAll(pushNodeList);

    List<PageTreeNode> newReplaceList = [];

    startIndex = -1;

    for (int i = 0; i < _stack.last.length; i++) {
      if (_stack.last[i].rootName == replaceNodeList.first.rootName) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      throw Exception('invalid path');
    }

    for (int i = 0; i < startIndex; i++) {
      newReplaceList.add(_stack.last[i]);
    }

    newReplaceList.addAll(replaceNodeList);

    List<PageTreeNode> tmpList = _stack.last;

    if (tmpList.length != newReplaceList.length) {
      _stack.add(newPushList);
      _notifyObservers();
      return;
    }

    bool needReplace = true;

    for (int i = 0; i < tmpList.length; i++) {
      if (tmpList[i].path != newReplaceList[i].path) {
        needReplace = false;
        break;
      }
    }

    if (needReplace) {
      _stack.removeLast();
    }
    _stack.add(newPushList);

    _notifyObservers();
  }

  static void _pop() {
    _stack.removeLast();
    _notifyObservers();
  }

  static void _notifyObservers() {
    for (final UrlStackObserver observer in _observers) {
      observer.onStackChanged(_stack.last);
    }
  }
}

abstract class UrlStackObserver {
  void onStackChanged(List<PageTreeNode> nodeList);
}

class UrlManager {
  static final Map<String, List<PageTreeNode>> _nodeListMap = {};

  static final Map<String, Map<PageTreeNode, Completer>> _completerMap = {};

  static final List<UrlListener> _listenerList = [];

  static void addListener(UrlListener listener) {
    _listenerList.add(listener);
    if (!_nodeListMap.containsKey(listener.listenerTreeName)) {
      _nodeListMap.addAll({listener.listenerTreeName: []});
    }

    if (!_completerMap.containsKey(listener.listenerTreeName)) {
      _completerMap.addAll({listener.listenerTreeName: {}});
    }
  }

  static void removeListener(UrlListener listener) {
    _listenerList.remove(listener);
    _nodeListMap.remove(listener.listenerTreeName);
    _completerMap.remove(listener.listenerTreeName);
  }

  static Future _waitForResult(String treeName) {
    return _completerMap[treeName][_nodeListMap[treeName].last].future;
  }

  static bool _containsPage(String treeName, String path) {
    return _nodeListMap[treeName].any((element) => element.path == path);
  }

  static String _currentPage(String treeName) {
    return _nodeListMap[treeName].last.path;
  }

  static bool _canPop(String treeName) {
    return _nodeListMap[treeName].length > 1;
  }

  static List<PageTreeNode> _pages(String treeName) {
    return _nodeListMap[treeName];
  }

  static void _push(String path, Map<String, String> parameters) {
    Map<String, PageTreeNode> map = _parsePath(path, parameters);

    for (final String key in map.keys) {
      if (!_nodeListMap.containsKey(key)) {
        _nodeListMap.addAll({key: []});
      }

      if (!_completerMap.containsKey(key)) {
        _completerMap.addAll({key: {}});
      }

      if (_nodeListMap[key].isEmpty || !map[key].compare(_nodeListMap[key].last)) {
        _nodeListMap[key].add(map[key]);

        _completerMap[key].addAll({map[key]: Completer()});
      }
    }

    UrlStackManager._push(map.values.toList());

    _notifyListeners();
  }

  static void _pushReplace(String path, Map<String, String> parameters, {dynamic result}) {
    Map<String, PageTreeNode> map = _parsePath(path, parameters);

    for (final String key in map.keys) {
      if (!_nodeListMap.containsKey(key)) {
        _nodeListMap.addAll({key: []});
      }

      if (!_completerMap.containsKey(key)) {
        _completerMap.addAll({key: {}});
      }

      if (_nodeListMap[key].isNotEmpty) {
        PageTreeNode pageTreeNode = _nodeListMap[key].removeLast();
        Completer completer = _completerMap[key].remove(pageTreeNode);
        completer.complete(result);
      }

      _nodeListMap[key].add(map[key]);

      _completerMap[key].addAll({map[key]: Completer()});
    }

    UrlStackManager._pushReplace(map.values.toList());

    _notifyListeners();
  }

  static void _pushOrReplace(String path, String replacePath, Map<String, String> parameters) {
    Map<String, PageTreeNode> pushMap = _parsePath(path, parameters);

    Map<String, PageTreeNode> replaceMap = _parsePath(replacePath, {});

    for (final String key in pushMap.keys) {
      if (!_nodeListMap.containsKey(key)) {
        _nodeListMap.addAll({key: []});
      }

      if (!_completerMap.containsKey(key)) {
        _completerMap.addAll({key: {}});
      }

      if (_nodeListMap[key].isNotEmpty && replaceMap.containsKey(key)) {
        PageTreeNode pageTreeNode = replaceMap[key];

        if (_nodeListMap[key].isNotEmpty && pageTreeNode.path == _nodeListMap[key].last.path) {
          _completerMap[key].remove(_nodeListMap[key].removeLast());
        }
      }

      if (_nodeListMap[key].isEmpty || !pushMap[key].compare(_nodeListMap[key].last)) {
        _nodeListMap[key].add(pushMap[key]);

        _completerMap[key].addAll({pushMap[key]: Completer()});
      }
    }

    UrlStackManager._pushOrReplace(pushMap.values.toList(), replaceMap.values.toList());

    _notifyListeners();
  }

  static void _pushAndRemoveUntil(String path, String targetPath, Map<String, String> parameters) {
    Map<String, PageTreeNode> pushMap = _parsePath(path, parameters);
    Map<String, PageTreeNode> removeMap = _parsePath(targetPath, {});

    for (final String key in removeMap.keys) {
      if (!_nodeListMap.containsKey(key)) {
        _nodeListMap.addAll({key: []});
      }

      if (!_completerMap.containsKey(key)) {
        _completerMap.addAll({key: {}});
      }

      while (_nodeListMap[key].isNotEmpty && _nodeListMap[key].last.path != removeMap[key].path) {
        _completerMap.remove(_nodeListMap[key].removeLast());
      }
    }

    for (final String key in pushMap.keys) {
      if (!_nodeListMap.containsKey(key)) {
        _nodeListMap.addAll({key: []});
      }

      if (!_completerMap.containsKey(key)) {
        _completerMap.addAll({key: {}});
      }

      if (_nodeListMap[key].isEmpty || !pushMap[key].compare(_nodeListMap[key].last)) {
        _nodeListMap[key].add(pushMap[key]);
        _completerMap[key].addAll({pushMap[key]: Completer()});
      }
    }

    UrlStackManager._pushAndRemoveUntil(pushMap.values.toList(), removeMap.values.toList());

    _notifyListeners();
  }

  static void _pop(String treeName, {dynamic result}) {
    Completer completer = _completerMap[treeName].remove(_nodeListMap[treeName].removeLast());
    completer.complete(result);

    UrlStackManager._pop();

    _notifyListeners();
  }

  static void _popUntil(String targetPath, Map<String, String> parameters) {
    Map<String, PageTreeNode> map = _parsePath(targetPath, parameters);

    for (final String key in map.keys) {
      while (_nodeListMap.containsKey(key) && _nodeListMap[key].isNotEmpty && !_nodeListMap[key].last.compare(map[key])) {
        _completerMap[key].remove(_nodeListMap[key].removeLast());
      }
    }

    UrlStackManager._popUntil(map.values.toList());

    _notifyListeners();
  }

  static void reset() {
    _nodeListMap.clear();
    _completerMap.clear();

    PageTreeManager.instance.reset();
  }

  static Map<String, PageTreeNode> _parsePath(String path, Map<String, String> parameters) {
    if (path.contains(':')) {
      List<String> segments = path.split(':');
      Map<String, PageTreeNode> cacheMap = {};

      for (final PageTree tree in PageTreeManager.instance.trees) {
        if (tree.name == segments[0]) {
          PageTreeNode node = tree.findNode(segments[1].split('/'), parameters);

          if (node != null) {
            cacheMap.addAll({tree.name: node});
          }
          return cacheMap;
        }
      }
    }

    List<String> pathNodes = path.split('/');

    List<int> indexList = [];

    Map<String, PageTreeNode> cacheMap = {};

    for (int i = 0; i < pathNodes.length; i++) {
      for (final PageTree tree in PageTreeManager.instance.trees) {
        if (pathNodes[i] == tree.rootName) {
          indexList.add(i);
          break;
        }
      }
    }

    for (int i = 0; i < indexList.length; i++) {
      for (final PageTree tree in PageTreeManager.instance.trees) {
        if (tree.rootName == pathNodes[indexList[i]]) {
          PageTreeNode node = tree.findNode(
              pathNodes.sublist(indexList[i], i == indexList.length - 1 ? pathNodes.length : indexList[i + 1]), i == indexList.length - 1 ? parameters : {});

          if (node != null) {
            cacheMap.addAll({tree.name: node});
          }

          break;
        }
      }
    }

    return cacheMap;
  }

  static void _notifyListeners() {
    for (final UrlListener listener in _listenerList) {
      listener.onNodeListUpdate(_nodeListMap[listener.listenerTreeName]);
    }
  }
}

abstract class UrlListener {
  String get listenerTreeName;

  void onNodeListUpdate(List<PageTreeNode> newNodeList);
}

abstract class UrlDelegate extends RouterDelegate<String> with ChangeNotifier, UrlListener {
  static UrlDelegate of(BuildContext context) => Router.of(context).routerDelegate as UrlDelegate;

  UrlDelegate({@required this.treeName});

  final String treeName;

  final Map<String, AnonymousPageBuilder> _anonymousPageBuilders = {};

  GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  Future waitResult() => UrlManager._waitForResult(treeName);

  bool get userGestureInProgress => _key.currentState.userGestureInProgress;

  void push(String path, {Map<String, String> parameters}) {
    UrlManager._push(path, parameters);
  }

  void pushReplace(String path, {Map<String, String> parameters, dynamic result}) {
    UrlManager._pushReplace(path, parameters, result: result);
  }

  void pop({dynamic result}) {
    UrlManager._pop(treeName, result: result);
  }

  void popUntil(String target, {Map<String, String> parameters}) {
    UrlManager._popUntil(target, parameters);
  }

  void pushAndRemoveUntil(String path, String targetPath, {Map<String, String> parameters}) {
    UrlManager._pushAndRemoveUntil(path, targetPath, parameters);
  }

  void pushOrReplace(String path, String replacePath, {Map<String, String> parameters}) {
    UrlManager._pushOrReplace(path, replacePath, parameters);
  }

  void addAnonymousPageBuilder(Map<String, AnonymousPageBuilder> map) {
    _anonymousPageBuilders.addAll(map);
  }

  Future pushPopUp(String name, {Map<String, String> parameters}) {
    if (parameters == null) {
      parameters = {};
    }

    Route newRoute = _anonymousPageBuilders[name](parameters);

    _key.currentState.push(newRoute);

    return newRoute.popped;
  }

  void popPopUp({dynamic result}) {
    _key.currentState.pop(result);
  }

  bool containsPage(String path) => UrlManager._containsPage(treeName, path);

  String get currentPage => UrlManager._currentPage(treeName);

  @override
  Future<bool> popRoute() {
    if (canPop()) {
      pop();
      return SynchronousFuture(true);
    }
    return SynchronousFuture(false);
  }

  bool canPop() {
    return UrlManager._canPop(treeName);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _key,
      pages: List.generate(UrlManager._pages(treeName).length, (index) => UrlManager._pages(treeName)[index].getPage()),
      onPopPage: (route, result) {
        if (route.didPop(result)) {
          pop(result: result);
          return true;
        }
        return false;
      },
    );
  }

  @override
  String get listenerTreeName => treeName;

  @override
  void onNodeListUpdate(List<PageTreeNode> newNodeList) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }
}

class RootUrlDelegate extends UrlDelegate with UrlStackObserver {
  RootUrlDelegate({@required String treeName}) : super(treeName: treeName);

  String _currentUrl = '';

  @override
  String get currentConfiguration => _currentUrl;

  @override
  Future<void> setNewRoutePath(String configuration) {
    // forward
    if (UrlStackManager._stack.isEmpty || !UrlStackManager._stack.any((element) => _generateUrl(element) == configuration)) {
      Uri uri = Uri.parse(configuration);

      push(configuration.split('?')[0], parameters: Map.from(uri.queryParameters));

      return SynchronousFuture(null);
    }

    // back
    else if (UrlStackManager._stack.any((element) => _generateUrl(element) == configuration)) {
      Uri uri = Uri.parse(configuration);

      UrlManager._popUntil(configuration.split('?')[0], Map.from(uri.queryParameters));

      return SynchronousFuture(null);
    }

    throw Exception('invalid url');
  }

  @override
  Future<void> setInitialRoutePath(String configuration) {
    return setNewRoutePath(configuration);
  }

  @override
  void onStackChanged(List<PageTreeNode> nodeList) {
    _currentUrl = _generateUrl(nodeList);
    notifyListeners();
    return;
  }

  String _generateUrl(List<PageTreeNode> nodeList) {
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < nodeList.length; i++) {
      buffer.write(nodeList[i].path);

      if (i != nodeList.length - 1) {
        buffer.write('/');
      }
    }

    if (nodeList.last.parameters.isEmpty) {
      return buffer.toString();
    }

    buffer.write('?');
    bool firstParam = true;

    for (int i = 0; i < nodeList.last.parameters.keys.length; i++) {
      RegExp exp = RegExp(r'^##([a-zA-Z0-9_]*)##$');
      if (exp.hasMatch(nodeList.last.parameters.keys.elementAt(i))) {
        continue;
      } else if (!firstParam) {
        if (i != nodeList.last.parameters.keys.length - 1) {
          buffer.write('&');
        }
      }

      if (firstParam) {
        firstParam = false;
      }
      buffer.write('${nodeList.last.parameters.keys.elementAt(i)}=${nodeList.last.parameters[nodeList.last.parameters.keys.elementAt(i)]}');
    }

    return buffer.toString();
  }
}

class SubUrlDelegate extends UrlDelegate {
  SubUrlDelegate({@required String treeName}) : super(treeName: treeName);

  @override
  Future<void> setNewRoutePath(String configuration) {
    return SynchronousFuture(null);
  }
}

class UrlParser extends RouteInformationParser<String> {
  UrlParser({this.defaultPath});

  final String defaultPath;

  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) {
    if (routeInformation.location == '/') {
      return SynchronousFuture(defaultPath);
    }
    return SynchronousFuture(routeInformation.location);
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) {
    return RouteInformation(location: configuration);
  }
}
