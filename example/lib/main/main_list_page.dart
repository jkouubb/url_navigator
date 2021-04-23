import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class MainListPageNode extends PageTreeNode {
  MainListPageNode()
      : super(
          name: 'list',
          routeBuilder: (settings) => NoTransitionUrlPageRoute(
            settings: settings,
            content: MainListPageWidget(),
          ),
        );
}

class MainListPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainListPageWidgetState();
}

class _MainListPageWidgetState extends State<MainListPageWidget> {
  SubUrlDelegate delegate;

  @override
  void initState() {
    PageTreeNode initialPage = TreeNodeCache.instance.read('list');
    // if (initialPage == null) {
    //   PageTreeInspector.instance.parseUrl('list_page');
    //   initialPage = TreeNodeCache.instance.read('list');
    // }
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
    return Scaffold(
      appBar: AppBar(),
      body: Builder(
        builder: (context) {
          return Router(routerDelegate: delegate);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool result = await UrlDelegate.of(context).pushPopUp('pop_up');

          UrlDelegate.of(context).pushPopUp('toast', parameters: {'message': result.toString()});

          await Future.delayed(Duration(seconds: 2));

          UrlDelegate.of(context).popPopUp();
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            UrlDelegate.of(context).push('app/main/enter_setting');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.android,
              color: Colors.grey,
            ),
            activeIcon: Icon(
              Icons.android,
              color: Colors.blue,
            ),
            label: 'list',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.android_rounded,
              color: Colors.grey,
            ),
            activeIcon: Icon(
              Icons.android_rounded,
              color: Colors.blue,
            ),
            label: 'settings',
          ),
        ],
      ),
    );
  }
}
