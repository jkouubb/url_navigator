import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'route.dart';
import 'tree.dart';

abstract class UrlDelegate extends RouterDelegate<String>
    with ChangeNotifier, TreeNodeCacheObserver {
  static UrlDelegate of(BuildContext context) =>
      Router.of(context).routerDelegate as UrlDelegate;

  UrlDelegate({this.treeName, PageTreeNode initialPage}) {
    if (initialPage != null) {
      _nodeList.add(initialPage);
    }
  }

  final String treeName;

  final Map<String, AnonymousPageBuilder> _anonymousPageBuilders = {};

  final List<PageTreeNode> _nodeList = [];

  final Map<PageTreeNode, Completer> _completerMap = {};

  final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  @override
  void onFlush(Map<String, PageTreeNode> cacheMap) {
    if (!cacheMap.containsKey(treeName)) {
      return;
    }

    PageTreeNode node = cacheMap.remove(treeName);

    _nodeList.add(node);

    _completerMap.addAll({_nodeList.last: Completer()});

    notifyListeners();
  }

  Future waitResult() => _completerMap[_nodeList.last].future;

  void push(String path, {Map<String, String> parameters}) {
    PageTreeInspector.instance.parseUrl(path, parameters: parameters);
  }

  void pushReplace(String path,
      {Map<String, String> parameters, dynamic result}) {
    PageTreeNode oldNode = _nodeList.removeLast();
    Completer<dynamic> oldCompleter = _completerMap.remove(oldNode);
    oldCompleter.complete(result);

    PageTreeInspector.instance.parseUrl(path, parameters: parameters);
  }

  void pop({dynamic result}) {
    PageTreeNode node = _nodeList.removeLast();

    Completer completer = _completerMap.remove(node);

    completer.complete(result);

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
  Future<bool> popRoute() {
    return _key.currentState.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _key,
      pages: List.generate(
          _nodeList.length, (index) => _nodeList[index].getPage()),
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

class RootUrlDelegate extends UrlDelegate {
  RootUrlDelegate({@required String treeName, PageTreeNode initialPage})
      : super(treeName: treeName, initialPage: initialPage);

  @override
  Future<void> setNewRoutePath(String configuration) {
    Uri uri = Uri.parse(configuration);

    push(uri.path, parameters: Map.from(uri.queryParameters));

    return SynchronousFuture(null);
  }

  @override
  Future<void> setInitialRoutePath(String configuration) {
    _nodeList.clear();
    _completerMap.clear();

    Uri uri = Uri.parse(configuration);

    push(uri.path, parameters: Map.from(uri.queryParameters));
    return SynchronousFuture(null);
  }

  @override
  String get currentConfiguration => _nodeList.last.path;
}

class SubUrlDelegate extends UrlDelegate {
  SubUrlDelegate({@required String treeName, PageTreeNode initialPage})
      : super(treeName: treeName, initialPage: initialPage);

  @override
  Future<void> setNewRoutePath(String configuration) {
    return SynchronousFuture(null);
  }
}

class UrlParser extends RouteInformationParser<String> {
  UrlParser(this.defaultPath);

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
