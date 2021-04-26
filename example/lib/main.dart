import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

import 'list/list_detail_page.dart';
import 'list/list_page.dart';
import 'login/log_in_page.dart';
import 'main/main_list_page.dart';
import 'main/main_pop_up.dart';
import 'main/main_setting_page.dart';
import 'main/main_toast.dart';
import 'setting/edit_setting_page.dart';
import 'setting/setting_page.dart';

void main() {
  /// Declare a top folder for your page tree.
  ///
  /// It is not necessary, you can always use a [PageTreeNode] as the root of your page tree.
  /// FolderTreeNode does nothing but organize your app page tree so your url can be meaningful
  FolderTreeNode appRoot = FolderTreeNode(name: 'app');

  /* grow your tree */
  appRoot.addChild(LoginPageNode());

  FolderTreeNode mainFolderNode = FolderTreeNode(name: 'main');
  mainFolderNode.addChild(MainListPageNode());
  mainFolderNode.addChild(MainSettingPageNode());
  appRoot.addChild(mainFolderNode);

  SettingPageNode settingPageNode = SettingPageNode();
  settingPageNode.addChild(EditSettingPageNode());
  appRoot.addChild(settingPageNode);

  /* Declare a tree with a name and a root */
  PageTree rootTree = PageTree('page', appRoot);

  /* Another tree for nest navigator */
  PageTreeNode listRoot = ListPageNode();
  listRoot.addChild(ListDetailPageNode());
  PageTree listTree = PageTree('inner', listRoot);

  /* Register trees */
  PageTreeManager.instance.addTree(rootTree);
  PageTreeManager.instance.addTree(listTree);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  RootUrlDelegate delegate;
  SubUrlDelegate subUrlDelegate;

  @override
  void initState() {
    /* In the Root of Your app, you need to use [RootUrlDelegate] to update url on browser */
    /* Each [UrlDelegate] needs to declare the name of the tree which it cares */
    delegate = RootUrlDelegate(treeName: 'page');
    subUrlDelegate = SubUrlDelegate(treeName: 'inner');

    /* AnonymousPages are Routes which are not linked with [UrlPage], their url won't show. Usually, they are used as alerts in a web page  */
    delegate.addAnonymousPageBuilder({
      'toast': (parameters) => UrlPopupRoute(
              content: MainToastWidget(
            message: parameters['message'],
          )),
      'pop_up': (parameters) => UrlPopupRoute(
            content: MainPopUpWidget(),
          ),
    });

    /* Each [UrlDelegate] is a [TreeNodeCacheObserver], they observe [TreeNodeCache], once there is a page from the tree they care in [TreeNodeCache], they pick it and update themselves */
    TreeNodeCache.addObserver(delegate);
    TreeNodeCache.addObserver(subUrlDelegate);

    /* RootUrlDelegate is a [UrlStackManagerObserver], it observes the url stack. Once stack updates, it updates its currentConfiguration and notify the Root Router */
    UrlStackManager.addObserver(delegate);
    super.initState();
  }

  @override
  void dispose() {
    /* Don't forget remove Delegate when the Navigator is being disposed */
    TreeNodeCache.removeObserver(delegate);
    TreeNodeCache.removeObserver(subUrlDelegate);

    UrlStackManager.removeObserver(delegate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: UrlParser(defaultPath: 'app/login_page'),
      routerDelegate: delegate,
    );
  }
}
