import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

import 'route.dart';
import 'tree.dart';

class _PageTreeInspector {
  static Map<String, PageTreeNode> _parsePath(String path, {Map<String, String> parameters}) {
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
          PageTreeNode node = tree.findNode(pathNodes.sublist(indexList[i], i == indexList.length - 1 ? pathNodes.length : indexList[i + 1]), parameters);

          if (node != null) {
            cacheMap.addAll({tree.name: node});
          }

          break;
        }
      }
    }

    return cacheMap;
  }

  static void _push(String path, {Map<String, String> parameters}) {
    Map<String, PageTreeNode> cacheMap = _parsePath(path, parameters: parameters);

    TreeNodeCache._push(cacheMap);

    UrlStackManager._push(cacheMap.values.toList());
    return;
  }

  static void _pop(String treeName, PageTreeNode newNode) {
    PageTreeManager.instance.updateCurrentNode(treeName, newNode);
    UrlStackManager._pop();
  }

  static void _popUntil(String targetPath) {
    Map<String, PageTreeNode> cacheMap = _parsePath(targetPath, parameters: {});

    TreeNodeCache._popUntil(cacheMap);

    UrlStackManager._popUntil(cacheMap.values.toList());
    return;
  }

  static void _pushAndRemoveUntil(String path, String targetPath, {Map<String, String> parameters}) {
    Map<String, PageTreeNode> pushCacheMap = _parsePath(path, parameters: parameters);

    TreeNodeCache._push(pushCacheMap);

    UrlStackManager._push(pushCacheMap.values.toList());

    Map<String, PageTreeNode> removeCacheMap = _parsePath(targetPath, parameters: {});

    TreeNodeCache._pushAndRemoveUntil(removeCacheMap);

    UrlStackManager._pushAndRemoveUntil(removeCacheMap.values.toList());
    return;
  }

  static void _pushOrReplace(String path, String replacePath, {Map<String, String> parameters}) {
    Map<String, PageTreeNode> pushCacheMap = _parsePath(path, parameters: parameters);

    Map<String, PageTreeNode> replaceCacheMap = _parsePath(replacePath, parameters: {});

    TreeNodeCache._pushOrReplace(pushCacheMap, replaceCacheMap);

    UrlStackManager._pushOrReplace(pushCacheMap.values.toList(), replaceCacheMap.values.toList());
    return;
  }

  static void reset() {
    for (final PageTree tree in PageTreeManager.instance.trees) {
      PageTreeManager.instance.updateCurrentNode(tree.name, null);
    }
  }
}

class TreeNodeCache {
  static void addObserver(TreeNodeCacheObserver listener) {
    _observers.add(listener);
  }

  static void removeObserver(TreeNodeCacheObserver listener) {
    _observers.remove(listener);
  }

  static Map<String, PageTreeNode> _cacheMap = {};

  static final List<TreeNodeCacheObserver> _observers = [];

  static void _push(Map<String, PageTreeNode> newCacheMap) {
    _cacheMap.clear();
    _cacheMap.addAll(newCacheMap);
    for (final observer in _observers) {
      observer.onPush(_cacheMap);
    }
  }

  static void _popUntil(Map<String, PageTreeNode> newCacheMap) {
    _cacheMap.clear();
    _cacheMap.addAll(newCacheMap);
    for (final observer in _observers) {
      observer.onPopUntil(_cacheMap);
    }
  }

  static void _pushAndRemoveUntil(Map<String, PageTreeNode> newCacheMap) {
    _cacheMap.clear();
    _cacheMap.addAll(newCacheMap);
    for (final observer in _observers) {
      observer.onPushAndRemoveUntil(_cacheMap);
    }
  }

  static void _pushOrReplace(Map<String, PageTreeNode> pushCacheMap, Map<String, PageTreeNode> replaceCacheMap) {
    _cacheMap.clear();
    _cacheMap.addAll(pushCacheMap);
    for (final observer in _observers) {
      observer.onPushOrReplace(_cacheMap, replaceCacheMap);
    }
  }

  static PageTreeNode _read(String treeName) => _cacheMap.remove(treeName);
}

abstract class TreeNodeCacheObserver {
  void onPush(Map<String, PageTreeNode> cacheMap);

  void onPopUntil(Map<String, PageTreeNode> cacheMap);

  void onPushAndRemoveUntil(Map<String, PageTreeNode> cacheMap);

  void onPushOrReplace(Map<String, PageTreeNode> pushCacheMap, Map<String, PageTreeNode> replaceCacheMap);
}

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
        if (tmpList[j].path != nodeList[j].path) {
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

  static void _pushAndRemoveUntil(List<PageTreeNode> nodeList) {
    for (int i = _stack.length - 2; i >= 0; i--) {
      List<PageTreeNode> tmpList = _stack[i];

      if (tmpList.length != nodeList.length) {
        _stack.removeAt(i);
        continue;
      }

      bool needsRemove = false;

      for (int j = 0; j < tmpList.length; j++) {
        if (tmpList[j].path != nodeList[j].path) {
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

  static void _pushOrReplace(List<PageTreeNode> pushNodeList, List<PageTreeNode> replaceNodeList) {
    if (_stack.isEmpty) {
      _stack.add(pushNodeList);
      _notifyObservers();
      return;
    }

    List<PageTreeNode> newList = [];

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
      newList.add(_stack.last[i]);
    }

    newList.addAll(pushNodeList);

    List<PageTreeNode> tmpList = _stack.last;

    if (tmpList.length != replaceNodeList.length) {
      _stack.add(newList);
      _notifyObservers();
      return;
    }

    bool needReplace = true;

    if (tmpList.length == replaceNodeList.length) {
      for (int i = 0; i < tmpList.length; i++) {
        if (tmpList[i].path != replaceNodeList[i].path) {
          needReplace = false;
          break;
        }
      }
    }

    if (needReplace) {
      _stack.removeLast();
    }
    _stack.add(newList);

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

abstract class UrlDelegate extends RouterDelegate<String> with ChangeNotifier, TreeNodeCacheObserver {
  static UrlDelegate of(BuildContext context) => Router.of(context).routerDelegate as UrlDelegate;

  UrlDelegate({@required this.treeName}) {
    PageTreeNode initialPage = TreeNodeCache._read(treeName);
    if (initialPage != null) {
      _nodeList.add(initialPage);
      _completerMap.addAll({_nodeList.last: Completer()});
    }
  }

  final String treeName;

  final Map<String, AnonymousPageBuilder> _anonymousPageBuilders = {};

  final List<PageTreeNode> _nodeList = [];

  final Map<PageTreeNode, Completer> _completerMap = {};

  GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  Future waitResult() => _completerMap[_nodeList.last].future;

  bool get userGestureInProgress => _key.currentState.userGestureInProgress;

  void push(String path, {Map<String, String> parameters}) {
    _PageTreeInspector._push(path, parameters: parameters);
  }

  void pushReplace(String path, {Map<String, String> parameters, dynamic result}) {
    PageTreeNode oldNode = _nodeList.removeLast();
    Completer<dynamic> oldCompleter = _completerMap.remove(oldNode);
    oldCompleter.complete(result);

    _PageTreeInspector._push(path, parameters: parameters);
  }

  void pop({dynamic result}) {
    PageTreeNode node = _nodeList.removeLast();

    Completer completer = _completerMap.remove(node);

    completer.complete(result);

    _PageTreeInspector._pop(treeName, _nodeList.last);

    notifyListeners();
  }

  void popUntil(String target) {
    _PageTreeInspector._popUntil(target);

    notifyListeners();
  }

  void pushAndRemoveUntil(String path, String targetPath, {Map<String, String> parameters}) {
    _PageTreeInspector._pushAndRemoveUntil(path, targetPath, parameters: parameters);
  }

  void pushOrReplace(String path, String replacePath, {Map<String, String> parameters}) {
    _PageTreeInspector._pushOrReplace(path, replacePath, parameters: parameters);
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

  bool containsPage(String path) => _nodeList.any((element) => element.path == path);

  String get currentPage => _nodeList.last.path;

  @override
  void onPush(Map<String, PageTreeNode> cacheMap) {
    if (cacheMap.containsKey(treeName)) {
      PageTreeNode node = cacheMap.remove(treeName);

      _nodeList.add(node);

      _completerMap.addAll({_nodeList.last: Completer()});

      notifyListeners();
    }
  }

  @override
  void onPopUntil(Map<String, PageTreeNode> cacheMap) {
    if (cacheMap.containsKey(treeName)) {
      PageTreeNode node = cacheMap.remove(treeName);

      for (int i = _nodeList.length - 1; i >= 0; i--) {
        if (node.path != _nodeList[i].path) {
          PageTreeNode nodeToRemove = _nodeList.removeAt(i);
          Completer completer = _completerMap.remove(nodeToRemove);
          completer.complete();
        }
      }

      notifyListeners();
    }
  }

  @override
  void onPushAndRemoveUntil(Map<String, PageTreeNode> cacheMap) {
    if (cacheMap.containsKey(treeName)) {
      PageTreeNode node = cacheMap.remove(treeName);

      for (int i = _nodeList.length - 2; i >= 0; i--) {
        if (node.path != _nodeList[i].path) {
          PageTreeNode nodeToRemove = _nodeList.removeAt(i);
          Completer completer = _completerMap.remove(nodeToRemove);
          completer.complete();
        }
      }

      notifyListeners();
    }
  }

  @override
  void onPushOrReplace(Map<String, PageTreeNode> pushCacheMap, Map<String, PageTreeNode> replaceCacheMap) {
    if (pushCacheMap.containsKey(treeName)) {
      PageTreeNode node = pushCacheMap.remove(treeName);

      if (replaceCacheMap.containsKey(treeName)) {
        PageTreeNode nodeToReplace = replaceCacheMap.remove(treeName);

        if (nodeToReplace.path == _nodeList.last.path) {
          _nodeList.removeLast();
        }
      }

      _nodeList.add(node);

      _completerMap.addAll({_nodeList.last: Completer()});

      notifyListeners();
    }
  }

  @override
  Future<bool> popRoute() {
    return _key.currentState.maybePop();
  }

  bool canPop() {
    return _nodeList.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _key,
      pages: List.generate(_nodeList.length, (index) => _nodeList[index].getPage()),
      onPopPage: (route, result) {
        if (route.didPop(result)) {
          pop(result: result);
          return true;
        }
        return false;
      },
    );
  }
}

class RootUrlDelegate extends UrlDelegate with UrlStackObserver {
  RootUrlDelegate({@required String treeName}) : super(treeName: treeName);

  String _currentUrl = '';

  @override
  String get currentConfiguration => _currentUrl;

  @override
  Future<void> setNewRoutePath(String configuration) {
    _nodeList.clear();
    _PageTreeInspector.reset();

    Uri uri = Uri.parse(configuration);

    push(configuration.split('?')[0], parameters: Map.from(uri.queryParameters));

    return SynchronousFuture(null);
  }

  @override
  Future<void> setInitialRoutePath(String configuration) {
    return setNewRoutePath(configuration);
  }

  @override
  void onStackChanged(List<PageTreeNode> nodeList) {
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < nodeList.length; i++) {
      buffer.write(nodeList[i].path);

      if (i != nodeList.length - 1) {
        buffer.write('/');
      }
    }

    if (nodeList.last.parameters.isEmpty) {
      _currentUrl = buffer.toString();
      notifyListeners();
      return;
    }

    buffer.write('?');

    for (int i = 0; i < nodeList.last.parameters.keys.length; i++) {
      RegExp exp = RegExp(r'^##([a-zA-Z0-9_]*)##$');
      if (exp.hasMatch(nodeList.last.parameters.keys.elementAt(i))) {
        continue;
      }
      buffer.write('${nodeList.last.parameters.keys.elementAt(i)}=${nodeList.last.parameters[nodeList.last.parameters.keys.elementAt(i)]}');

      if (i != nodeList.last.parameters.keys.length - 1) {
        buffer.write('&');
      }
    }

    _currentUrl = buffer.toString();
    notifyListeners();
    return;
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
