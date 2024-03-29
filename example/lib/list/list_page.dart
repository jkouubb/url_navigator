import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class ListPageNode extends PageTreeNode {
  ListPageNode()
      : super(
          name: 'list_page',
          routeBuilder: (settings) => UrlPageRoute(
            settings: settings,
            content: ListPageWidget(),
          ),
        );
}

class ListPageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints.tight(Size(200, 40)),
          child: ElevatedButton(
            onPressed: () {
              UrlDelegate.of(context).push('show_list/list_page/list_detail_page', parameters: {'name': 'alpha'});
            },
            child: Text('alpha'),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        ConstrainedBox(
          constraints: BoxConstraints.tight(Size(200, 40)),
          child: ElevatedButton(
            onPressed: () {
              UrlDelegate.of(context).push('inner:./list_detail_page', parameters: {'name': 'beta'});
            },
            child: Text('beta'),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        ConstrainedBox(
          constraints: BoxConstraints.tight(Size(200, 40)),
          child: ElevatedButton(
            onPressed: () {
              UrlDelegate.of(context).push('app/setting_page');
            },
            child: Text('setting_page'),
          ),
        ),
      ],
    );
  }
}
