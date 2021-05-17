import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

import 'route.dart';
import 'tree.dart';

class _PageTreeInspector {
  static void _push(String path, {Map<String, String> parameters}) {
    if (path.contains(':')) {
      List<String> segments = path.split(':');
      Map<String, PageTreeNode> cacheMap = {};

      for (final PageTree tree in PageTreeManager.instance.trees) {
        if (tree.name == segments[0]) {
          PageTreeNode node = tree.findNode(segments[1].split('/'), parameters);

          if (node != null) {
            cacheMap.addAll({tree.name: node});
          }

          TreeNodeCache._flush(cacheMap);
          UrlStackManager._push(cacheMap.values.toList());
          return;
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

    TreeNodeCache._flush(cacheMap);

    UrlStackManager._push(cacheMap.values.toList());
    return;
  }

  static void _pop(String treeName, PageTreeNode newNode) {
    PageTreeManager.instance.updateCurrentNode(treeName, newNode);
    UrlStackManager._pop();
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

  static void _flush(Map<String, PageTreeNode> newCacheMap) {
    _cacheMap.clear();
    _cacheMap.addAll(newCacheMap);
    for (final observer in _observers) {
      observer.onFlush(_cacheMap);
    }
  }

  static PageTreeNode _read(String treeName) => _cacheMap.remove(treeName);
}

abstract class TreeNodeCacheObserver {
  void onFlush(Map<String, PageTreeNode> cacheMap);
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
    }
  }

  final String treeName;

  final Map<String, AnonymousPageBuilder> _anonymousPageBuilders = {};

  final List<PageTreeNode> _nodeList = [];

  final Map<PageTreeNode, Completer> _completerMap = {};

  GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  Future waitResult() => _completerMap[_nodeList.last].future;

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
    bool hasTarget = false;

    for (int i = _nodeList.length - 1; i >= 0; i--) {
      if (_nodeList[i].path == target) {
        hasTarget = true;
        break;
      }
    }

    if (!hasTarget) {
      return;
    }

    while (_nodeList.last.path != target) {
      PageTreeNode node = _nodeList.removeLast();

      Completer completer = _completerMap.remove(node);

      completer.complete(null);

      _PageTreeInspector._pop(treeName, _nodeList.last);
    }

    notifyListeners();
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

  @override
  void onFlush(Map<String, PageTreeNode> cacheMap) {
    if (cacheMap.containsKey(treeName)) {
      PageTreeNode node = cacheMap.remove(treeName);

      _nodeList.add(node);

      _completerMap.addAll({_nodeList.last: Completer()});

      notifyListeners();
    }
  }

  @override
  Future<bool> popRoute() {
    return _key.currentState.maybePop();
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
