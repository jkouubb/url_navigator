import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

import 'list/list_detail_page.dart';
import 'list/list_page.dart';
import 'login/log_in_page.dart';
import 'main/folder_node.dart';
import 'main/main_list_page.dart';
import 'main/main_pop_up.dart';
import 'main/main_setting_page.dart';
import 'main/main_toast.dart';
import 'setting/edit_setting_page.dart';
import 'setting/setting_page.dart';

void main() {
  FolderTreeNode appRoot = FolderTreeNode(name: 'app');
  appRoot.addChild(LoginPageNode());
  MainFolderNode mainFolderNode = MainFolderNode();
  mainFolderNode.addChild(MainSettingPageNode());
  mainFolderNode.addChild(MainListPageNode());
  appRoot.addChild(mainFolderNode);
  SettingPageNode settingPageNode = SettingPageNode();
  settingPageNode.addChild(EditSettingPageNode());
  appRoot.addChild(settingPageNode);
  PageTree rootTree = PageTree('app', appRoot);

  PageTreeNode listRoot = ListPageNode();
  listRoot.addChild(ListDetailPageNode());
  PageTree listTree = PageTree('list', listRoot);

  PageTreeInspector.instance.addTree(rootTree);
  PageTreeInspector.instance.addTree(listTree);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  RootUrlDelegate delegate;

  @override
  void initState() {
    delegate = RootUrlDelegate(treeName: 'app');
    delegate.addAnonymousPageBuilder({
      'toast': (parameters) => PopupBoxRoute(
              child: MainToastWidget(
            message: parameters['message'],
          )),
      'pop_up': (parameters) => PopupBoxRoute(child: MainPopUpWidget()),
    });

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
    return MaterialApp.router(
      routeInformationParser: UrlParser('app/login_page'),
      routerDelegate: delegate,
    );
  }
}