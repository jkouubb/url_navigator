import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class LoginPageNode extends PageTreeNode {
  LoginPageNode()
      : super(
          name: 'login_page',
          builder: (key, name, parameters) =>
              LoginPage(key: key, name: name, parameters: parameters),
        );
}

class LoginPage extends SimpleUrlPage {
  LoginPage({Key key, String name, Map<String, String> parameters})
      : super(
          key: key,
          name: name,
          parameters: parameters,
          builder: (context) => LoginPageWidget(),
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
