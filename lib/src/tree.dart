import 'package:flutter/widgets.dart';

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
    Map<String, String> param = {};

    if (parameters != null && parameters.isNotEmpty) {
      param.addAll(parameters);
    }

    PageTreeNode copyNode = PageTreeNode(name: name, routeBuilder: routeBuilder, parameters: param);

    copyNode.parent = _parent;
    for (final TreeNode node in _children) {
      copyNode.addChild(node);
    }

    return copyNode;
  }

  UrlPage getPage() =>
      UrlPage(key: ValueKey(PageObjectForKey(name: name, parameters: parameters)), name: name, parameters: parameters, routeBuilder: routeBuilder);

  bool compare(TreeNode other) {
    return other is PageTreeNode && path == other.path && _compareParameters(other.parameters);
  }

  bool _compareParameters(Map<String, String> otherParameters) {
    for (final String key in parameters.keys) {
      if (!otherParameters.containsKey(key)) {
        return false;
      }

      if (parameters[key] != otherParameters[key]) {
        return false;
      }
    }

    return true;
  }
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
  PageTree(this.name, this._root);

  final String name;

  final FolderTreeNode _root;

  PageTreeNode _currentNode;

  String get rootName => _root.name;

  TreeNode findNode(List<String> pathNodes, Map<String, String> parameters) {
    PageTreeNode node =
        (pathNodes.first == '.' || pathNodes.first == '..') ? _currentNode.findNode(pathNodes, parameters) : _root.findNode(pathNodes, parameters);

    if (_currentNode == null || !_currentNode.compare(node)) {
      _currentNode = node;
      return _currentNode;
    }

    return null;
  }

  void reset() {
    _currentNode = null;
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

  void updateCurrentNode(String treeName, TreeNode currentNode) {
    for (final PageTree tree in _trees) {
      if (tree.name == treeName) {
        tree._currentNode = currentNode;
        return;
      }
    }
  }

  List<PageTree> get trees => List.unmodifiable(_trees);
}
