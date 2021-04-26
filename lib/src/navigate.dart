import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

import 'page.dart';
import 'route.dart';

abstract class TreeNode {
  TreeNode({@required this.name});

  final String name;

  TreeNode _parent;

  List<TreeNode> _children = [];

  set parent(TreeNode value) {
    _parent = value;
  }

  void addChild(TreeNode child) {
    child.parent = this;

    _children.add(child);
  }

  TreeNode findNode(List<String> pathNodes, Map<String, String> parameters);

  String get path => _parent == null ? name : '${_parent.path}/$name';

  String get rootName => _parent == null ? name : _parent.rootName;
}

class PageTreeNode extends TreeNode {
  PageTreeNode({
    @required String name,
    @required this.routeBuilder,
    Map<String, String> parameters,
  }) : super(name: name) {
    if (parameters != null) {
      _parameters.addAll(parameters);
    }
  }

  final Map<String, String> _parameters = {};

  final UrlPageRoute Function(UrlPage settomgs) routeBuilder;

  Map<String, String> get parameters => Map.unmodifiable(_parameters);

  @override
  TreeNode findNode(List<String> pathNodes, Map<String, String> parameters) {
    if (pathNodes.first == name || pathNodes.first == '.') {
      pathNodes.remove(pathNodes.first);

      if (pathNodes.isNotEmpty) {
        for (final TreeNode child in _children) {
          if (child.name == pathNodes.first) {
            return child.findNode(pathNodes, parameters);
          }
        }
        throw Exception('page not found');
      }

      return _copy(parameters);
    }

    if (pathNodes.first == '..') {
      pathNodes.remove(pathNodes.first);
      return _parent.findNode(pathNodes, parameters);
    }

    throw Exception('invalid path');
  }

  PageTreeNode _copy(Map<String, String> parameters) {
    PageTreeNode copyNode = PageTreeNode(name: name, routeBuilder: routeBuilder, parameters: parameters);

    copyNode.parent = _parent;
    for (final TreeNode node in _children) {
      copyNode.addChild(node);
    }

    return copyNode;
  }

  UrlPage getPage() =>
      UrlPage(key: ValueKey(PageObjectForKey(name: name, parameters: parameters)), name: name, parameters: parameters, routeBuilder: routeBuilder);
}

class FolderTreeNode extends TreeNode {
  FolderTreeNode({@required String name}) : super(name: name);

  @override
  TreeNode findNode(List<String> pathNodes, Map<String, String> parameters) {
    if (pathNodes.first == name) {
      pathNodes.remove(pathNodes.first);

      if (pathNodes.isNotEmpty) {
        for (final TreeNode child in _children) {
          if (child.name == pathNodes.first) {
            return child.findNode(pathNodes, parameters);
          }
        }
      }
    } else if (pathNodes.first == '..') {
      pathNodes.remove(pathNodes.first);

      return _parent.findNode(pathNodes, parameters);
    }

    throw Exception('invalid path');
  }
}

class PageTree {
  PageTree(this.name, this._root) {
    _currentNode = _root;
  }

  final String name;

  final TreeNode _root;

  TreeNode _currentNode;

  String get rootName => _root.name;

  TreeNode findNode(List<String> pathNodes, Map<String, String> parameters) {
    if (pathNodes.first == '.' || pathNodes.first == '..') {
      _currentNode = _currentNode.findNode(pathNodes, parameters);
      return _currentNode;
    }
    _currentNode = _root.findNode(pathNodes, parameters);
    return _currentNode;
  }
}

class PageTreeManager {
  static PageTreeManager _instance;

  static PageTreeManager get instance {
    if (_instance == null) {
      _instance = PageTreeManager._internal();
    }
    return _instance;
  }

  PageTreeManager._internal();

  final List<PageTree> _trees = [];

  void addTree(PageTree tree) {
    _trees.add(tree);
  }

  void _updateCurrentNode(String treeName, TreeNode currentNode) {
    for (final PageTree tree in _trees) {
      if (tree.name == treeName) {
        tree._currentNode = currentNode;
        return;
      }
    }
  }

  List<PageTree> get trees => List.unmodifiable(_trees);
}

class _PageTreeInspector {
  static void _push(String path, {Map<String, String> parameters}) {
    if (path.contains(':')) {
      List<String> segments = path.split(':');
      Map<String, PageTreeNode> cacheMap = {};

      for (final PageTree tree in PageTreeManager.instance.trees) {
        if (tree.name == segments[0]) {
          cacheMap.addAll({tree.name: tree.findNode(segments[1].split('/'), parameters)});

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

          cacheMap.addAll({tree.name: node});
          break;
        }
      }
    }

    TreeNodeCache._flush(cacheMap);

    UrlStackManager._push(cacheMap.values.toList());
    return;
  }

  static void _pop(String treeName, PageTreeNode newNode) {
    PageTreeManager.instance._updateCurrentNode(treeName, newNode);
    UrlStackManager._pop();
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
    for (final TreeNodeCacheObserver listener in _observers) {
      listener.onFlush(_cacheMap);
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

  final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

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
