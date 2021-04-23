import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'route.dart';
import 'tree.dart';

abstract class UrlDelegate extends RouterDelegate<String> with ChangeNotifier, TreeNodeCacheObserver {
  static UrlDelegate of(BuildContext context) => Router.of(context).routerDelegate as UrlDelegate;

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

  void pushReplace(String path, {Map<String, String> parameters, dynamic result}) {
    PageTreeNode oldNode = _nodeList.removeLast();
    Completer<dynamic> oldCompleter = _completerMap.remove(oldNode);
    oldCompleter.complete(result);

    PageTreeInspector.instance.parseUrl(path, parameters: parameters);
  }

  void pop({dynamic result}) {
    PageTreeNode node = _nodeList.removeLast();

    Completer completer = _completerMap.remove(node);

    completer.complete(result);

    PageTreeInspector.instance.updateTreeCurrentNode(treeName, _nodeList.last);

    notifyListeners();

    UrlStackManager.instance.popStack();
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
  String get currentConfiguration {
    List<PageTreeNode> list = UrlStackManager.instance.currentStack;

    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < list.length; i++) {
      buffer.write(list[i].path);

      if (i != list.length - 1) {
        buffer.write('/');
      }
    }

    if (list.last.parameters.isEmpty) {
      return buffer.toString();
    }

    buffer.write('?');

    for (int i = 0; i < list.last.parameters.keys.length; i++) {
      buffer.write('${list.last.parameters.keys.elementAt(i)}=${list.last.parameters[list.last.parameters.keys.elementAt(i)]}');

      if (i != list.last.parameters.keys.length - 1) {
        buffer.write('&');
      }
    }

    return buffer.toString();
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

class RootUrlDelegate extends UrlDelegate {
  RootUrlDelegate({@required String treeName, PageTreeNode initialPage}) : super(treeName: treeName, initialPage: initialPage);

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
    UrlStackManager.instance.clear();

    Uri uri = Uri.parse(configuration);

    push(uri.path, parameters: Map.from(uri.queryParameters));
    return SynchronousFuture(null);
  }
}

class SubUrlDelegate extends UrlDelegate {
  SubUrlDelegate({@required String treeName, PageTreeNode initialPage}) : super(treeName: treeName, initialPage: initialPage);

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
