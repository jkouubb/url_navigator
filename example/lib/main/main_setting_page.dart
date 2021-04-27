import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class MainSettingPageNode extends PageTreeNode {
  MainSettingPageNode()
      : super(
          name: 'enter_setting',
          routeBuilder: (settings) => NoTransitionUrlPageRoute(
            settings: settings,
            content: MainSettingPageWidget(),
          ),
        );
}

class MainSettingPageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints.tight(Size(200, 40)),
                  child: ElevatedButton(
                    onPressed: () {
                      UrlDelegate.of(context).push('app/setting_page');
                    },
                    child: Text(
                      'settings',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints.tight(Size(200, 40)),
                  child: ElevatedButton(
                    onPressed: () {
                      UrlDelegate.of(context).push('app/main/list/show_list/list_page/list_detail_page', parameters: {'name': 'jack'});
                    },
                    child: Text(
                      'detail with jack',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
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
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            UrlDelegate.of(context).pushReplace('app/main/list/show_list/list_page');
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
