import 'package:flutter/material.dart';

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

  void updateCurrentNode(TreeNode node) {
    _currentNode = node;
  }

  TreeNode findNode(List<String> pathNodes, Map<String, String> parameters) {
    if (pathNodes.first == '.' || pathNodes.first == '..') {
      _currentNode = _currentNode.findNode(pathNodes, parameters);
      return _currentNode;
    }
    _currentNode = _root.findNode(pathNodes, parameters);
    return _currentNode;
  }
}

class PageTreeInspector {
  static PageTreeInspector _instance;

  static PageTreeInspector get instance {
    if (_instance == null) {
      _instance = PageTreeInspector._internal();
    }
    return _instance;
  }

  PageTreeInspector._internal();

  final List<PageTree> _trees = [];

  void addTree(PageTree tree) {
    _trees.add(tree);
  }

  void updateTreeCurrentNode(String treeName, TreeNode currentNode) {
    for (final PageTree tree in _trees) {
      if (tree.name == treeName) {
        tree.updateCurrentNode(currentNode);
        return;
      }
    }
  }

  void parseUrl(String path, {Map<String, String> parameters}) {
    if (path.contains(':')) {
      List<String> segments = path.split(':');
      Map<String, PageTreeNode> cacheMap = {};

      for (final PageTree tree in _trees) {
        if (tree.name == segments[0]) {
          cacheMap.addAll({tree.name: tree.findNode(segments[1].split('/'), parameters)});

          _updateStack(cacheMap.values.toList());
          TreeNodeCache.instance.flush(cacheMap);
          return;
        }
      }
    }

    List<String> pathNodes = path.split('/');

    if (parameters == null) {
      parameters = {};
    }

    List<int> indexList = [];

    Map<String, PageTreeNode> cacheMap = {};

    for (int i = 0; i < pathNodes.length; i++) {
      for (final PageTree tree in _trees) {
        if (pathNodes[i] == tree.rootName) {
          indexList.add(i);
          break;
        }
      }
    }

    for (int i = 0; i < indexList.length; i++) {
      for (final PageTree tree in _trees) {
        if (tree.rootName == pathNodes[indexList[i]]) {
          PageTreeNode node = tree.findNode(pathNodes.sublist(indexList[i], i == indexList.length - 1 ? pathNodes.length : indexList[i + 1]), parameters);

          cacheMap.addAll({tree.name: node});
          break;
        }
      }
    }

    _updateStack(cacheMap.values.toList());
    TreeNodeCache.instance.flush(cacheMap);
  }

  void _updateStack(List<PageTreeNode> nodeList) {
    List<PageTreeNode> list = [];
    int startIndex = -1;

    for (int i = 0; i < _trees.length; i++) {
      if (nodeList.first.rootName == _trees[i].rootName) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      throw Exception('invalid path');
    }

    for (int i = 0; i < startIndex; i++) {
      list.add(_trees[i]._currentNode);
    }

    list.addAll(nodeList);

    UrlStackManager.instance.updateStack(list);
  }
}

class TreeNodeCache {
  static TreeNodeCache _instance;

  static TreeNodeCache get instance {
    if (_instance == null) {
      _instance = TreeNodeCache._internal();
    }
    return _instance;
  }

  TreeNodeCache._internal();

  final Map<String, PageTreeNode> _cacheMap = {};

  final List<TreeNodeCacheObserver> _listeners = [];

  void addListener(TreeNodeCacheObserver listener) {
    _listeners.add(listener);
  }

  void removeListener(TreeNodeCacheObserver listener) {
    _listeners.remove(listener);
  }

  void flush(Map<String, PageTreeNode> newCacheMap) {
    _cacheMap.clear();
    _cacheMap.addAll(newCacheMap);
    for (final TreeNodeCacheObserver listener in _listeners) {
      listener.onFlush(_cacheMap);
    }
  }

  PageTreeNode read(String treeName) => _cacheMap.remove(treeName);
}

abstract class TreeNodeCacheObserver {
  void onFlush(Map<String, PageTreeNode> cacheMap);
}

class UrlStackManager {
  static UrlStackManager _instance;

  static UrlStackManager get instance {
    if (_instance == null) {
      _instance = UrlStackManager._internal();
    }
    return _instance;
  }

  UrlStackManager._internal();

  final List<List<PageTreeNode>> _stack = [];

  List<PageTreeNode> get currentStack => List.unmodifiable(_stack.last);

  void updateStack(List<PageTreeNode> nodeList) {
    _stack.add(nodeList);
  }

  void popStack() {
    _stack.removeLast();
  }

  void clear() {
    _stack.clear();
  }
}
