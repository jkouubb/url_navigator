import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class LoginPageNode extends PageTreeNode {
  LoginPageNode()
      : super(
          name: 'login_page',
          routeBuilder: (settings) => UrlPageRoute(
            settings: settings,
            content: LoginPageWidget(),
          ),
        );
}

class LoginPageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints.tight(Size(200, 40)),
        child: ElevatedButton(
          onPressed: () {
            UrlDelegate.of(context).pushReplace('app/main/enter_setting');
          },
          child: Text(
            'login',
          ),
        ),
      ),
    );
  }
}
