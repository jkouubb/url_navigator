import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class MainListPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainListPageWidgetState();
}

class _MainListPageWidgetState extends State<MainListPageWidget> {
  SubUrlDelegate delegate;

  @override
  void initState() {
    PageTreeNode initialPage = TreeNodeCache.instance.read('list');
    if (initialPage == null) {
      PageTreeInspector.instance.parseUrl('list_page');
      initialPage = TreeNodeCache.instance.read('list');
    }
    delegate = SubUrlDelegate(treeName: 'list', initialPage: initialPage);
    TreeNodeCache.instance.addListener(delegate);
    super.initState();
  }

  @override
  void dispose() {
    TreeNodeCache.instance.removeListener(delegate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Router(routerDelegate: delegate);
  }
}
